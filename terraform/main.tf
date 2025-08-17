terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.48.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "gcs" {
    prefix  = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "project" {}

# Grant Cloud Build Service Account permissions to deploy infrastructure
resource "google_project_iam_member" "cloudbuild_sa_permissions" {
  for_each = toset([
    "roles/serviceusage.serviceUsageAdmin",
    "roles/run.admin",
    "roles/cloudsql.admin",
    "roles/secretmanager.admin",
    "roles/compute.networkAdmin",
    "roles/vpcaccess.admin",
    "roles/iam.serviceAccountUser",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild,
    google_project_service.cloudrun,
    google_project_service.sqladmin,
    google_project_service.secretmanager,
    google_project_service.vpcaccess,
  ]
}

# Grant Cloud Run's runtime Service Account permissions to access other services
resource "google_project_iam_member" "cloudrun_runtime_sa_permissions" {
  for_each = toset([
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
  ])
  project = var.project_id
  role    = each.key
  # The default service account for Cloud Run is the Compute Engine default SA
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    google_project_service.secretmanager,
    google_project_service.sqladmin,
  ]
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudrun" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "containerregistry" {
  service = "containerregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess" {
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-for-gcp-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "projects/${var.project_id}/global/networks/default"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = "projects/${var.project_id}/global/networks/default"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on              = [google_project_service.servicenetworking]
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_sql_database_instance" "main" {
  name             = "adk-trade-db"
  database_version = "MYSQL_8_0"
  region           = var.region

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  settings {
    tier = "db-g1-small"
    availability_type = "ZONAL"
    disk_size = 10
    disk_type = "PD_SSD"
    ip_configuration {
      ipv4_enabled = false
      private_network = "projects/${var.project_id}/global/networks/default"
    }
    backup_configuration {
      enabled = true
    }
    location_preference {
      zone = "${var.region}-a"
    }
    insights_config {
      query_insights_enabled = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = "adk-trade"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "db_user" {
  name     = "adk-trade-user"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

resource "google_vpc_access_connector" "connector" {
  name          = "adk-trade-connector"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = "default"
  depends_on = [
    google_project_service.vpcaccess
  ]
}

resource "google_cloud_run_v2_service" "main" {
  name     = "adk-trade"
  location = var.region

  depends_on = [
    google_sql_database.database
  ]

  template {
    containers {
      image = "gcr.io/${var.project_id}/adk-trade"
      ports {
        container_port = 8080
      }
      env {
        name  = "GCP_SQL_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.main.connection_name
      }
      env {
        name  = "GCP_SQL_USER"
        value = google_sql_user.db_user.name
      }
      env {
        name  = "GCP_SQL_PASSWORD"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "GCP_SQL_DB_NAME"
        value = google_sql_database.database.name
      }
    }
    scaling {
      max_instance_count = 2
    }
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }
  }
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 5.30.0"
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

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudrun" {
  service = "run.googleapis.com"
}

resource "google_project_service" "sqladmin" {
  service = "sqladmin.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "containerregistry" {
  service = "containerregistry.googleapis.com"
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

  settings {
    tier = "db-n1-standard-1"
    availability_type = "REGIONAL"
    disk_size = 10
    disk_type = "PD_SSD"
    ip_configuration {
      ipv4_enabled = true
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

resource "google_sql_user" "db_user" {
  name     = "adk-trade-user"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

resource "google_cloud_run_v2_service" "main" {
  name     = "adk-trade"
  location = var.region

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
        value = "adk-trade"
      }
    }
    scaling {
      max_instance_count = 2
    }
  }
}

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

locals {
  image_suffixes = {
    "data_analyst"        = "data-analyst-agent"
    "execution_analyst"   = "execution-analyst-agent"
    "portfolio_manager"   = "portfolio-manager-agent"
    "risk_analyst"        = "risk-analyst-agent"
    "trade_scanner_agent" = "trade-scanner-agent"
    "trading_analyst"     = "trading-analyst-agent"
  }
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
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
  depends_on = [
    google_project_service.secretmanager
  ]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "db_host" {
  secret_id = "db-host"
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
  depends_on = [
    google_project_service.secretmanager
  ]
}

resource "google_secret_manager_secret_version" "db_host" {
  secret      = google_secret_manager_secret.db_host.id
  secret_data = google_sql_database_instance.main.public_ip_address
  depends_on = [google_sql_database_instance.main]
}

resource "google_sql_database_instance" "main" {
  name             = "adk-trade-db"
  database_version = "MYSQL_8_0"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-g1-small"
    availability_type = "ZONAL"
    disk_size = 10
    disk_type = "PD_SSD"
    ip_configuration {
      ipv4_enabled    = true
      # WARNING: This allows access from any IP address.
      # For a production environment, you should restrict this to known IP ranges.
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
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
  depends_on = [
    google_project_service.sqladmin
  ]
}

resource "google_sql_database" "database" {
  name     = "adk-trade"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "db_user" {
  name     = "db_user"
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
  for_each = toset(var.agents)
  name     = "adk-trade-${replace(each.key, "_", "-")}"
  location = var.region
  deletion_protection = false

  depends_on = [
    google_sql_database.database,
    google_project_service.cloudrun
  ]

  template {
    scaling {
      max_instance_count = 1
    }
    containers {
      image = "gcr.io/${var.project_id}/${local.image_suffixes[each.key]}"
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
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }
  }
}

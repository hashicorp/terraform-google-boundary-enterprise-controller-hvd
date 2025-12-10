# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Google secret manager - Boundary database password lookup
#------------------------------------------------------------------------------
data "google_secret_manager_secret_version" "boundary_database_password" {
  secret = var.boundary_database_password_secret_version
}

#-----------------------------------------------------------------------------------
# Cloud SQL for PostgreSQL
#-----------------------------------------------------------------------------------
resource "random_id" "postgres_suffix" {
  byte_length = 4
}

resource "google_compute_global_address" "postgres_private_ip" {

  name          = "${var.friendly_name_prefix}-boundary-postgres-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.vpc.self_link
}

resource "google_sql_database_instance" "boundary" {
  provider = google-beta

  name                = "${var.friendly_name_prefix}-boundary-pg-${random_id.postgres_suffix.hex}"
  database_version    = var.postgres_version
  encryption_key_name = var.postgres_key_name == null ? null : data.google_kms_crypto_key.postgres[0].id
  deletion_protection = false

  settings {
    availability_type = var.postgres_availability_type
    tier              = var.postgres_machine_type
    disk_type         = "PD_SSD"
    disk_size         = var.postgres_disk_size
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = data.google_compute_network.vpc.self_link
      ssl_mode        = var.postgres_ssl_mode
    }

    backup_configuration {
      enabled    = true
      start_time = var.postgres_backup_start_time
    }

    maintenance_window {
      day          = var.postgres_maintenance_window.day
      hour         = var.postgres_maintenance_window.hour
      update_track = var.postgres_maintenance_window.update_track
    }

    insights_config {
      query_insights_enabled  = var.postgres_insights_config.query_insights_enabled
      query_plans_per_minute  = var.postgres_insights_config.query_plans_per_minute
      query_string_length     = var.postgres_insights_config.query_string_length
      record_application_tags = var.postgres_insights_config.record_application_tags
      record_client_address   = var.postgres_insights_config.record_client_address
    }

    user_labels = var.common_labels
  }
  depends_on = [google_kms_crypto_key_iam_binding.cloud_sql_sa_postgres_cmek]
}

resource "google_sql_database" "boundary" {
  name     = var.boundary_database_name
  instance = google_sql_database_instance.boundary.name
}

resource "google_sql_user" "boundary" {
  name     = var.boundary_database_user
  instance = google_sql_database_instance.boundary.name
  password = nonsensitive(data.google_secret_manager_secret_version.boundary_database_password.secret_data)
}

#------------------------------------------------------------------------------
# KMS Cloud SQL for PostgreSQL customer managed encryption key (CMEK)
#------------------------------------------------------------------------------
data "google_kms_key_ring" "postgres" {
  count = var.postgres_kms_keyring_name != null ? 1 : 0

  name     = var.postgres_kms_keyring_name
  location = data.google_client_config.default.region
}

data "google_kms_crypto_key" "postgres" {
  count = var.postgres_kms_cmek_name != null ? 1 : 0

  name     = var.postgres_kms_cmek_name
  key_ring = data.google_kms_key_ring.postgres[0].id
}
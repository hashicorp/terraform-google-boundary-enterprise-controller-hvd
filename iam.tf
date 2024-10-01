# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#-----------------------------------------------------------------------------------
# Service Account
#-----------------------------------------------------------------------------------
data "google_storage_project_service_account" "project" {}

resource "google_service_account" "boundary" {
  account_id   = "${var.friendly_name_prefix}-bnd-ctl-svc-acct"
  display_name = "${var.friendly_name_prefix}-boundary-ctl-svc-acct"
  description  = "Service Account allowing Boundary instance(s) to interact GCP resources and services."
}

resource "google_service_account_key" "boundary" {
  service_account_id = google_service_account.boundary.name
}


#------------------------------------------------------------------------------
# Cloud SQL for PostgreSQL KMS CMEK
#------------------------------------------------------------------------------
// There is no Google-managed service account (service agent) for Cloud SQL,
// so one must be created to allow the Cloud SQL instance to use the CMEK.
// https://cloud.google.com/sql/docs/postgres/configure-cmek
resource "google_project_service_identity" "cloud_sql_sa" {
  count    = var.postgres_kms_cmek_name != null ? 1 : 0
  provider = google-beta

  service = "sqladmin.googleapis.com"
}

resource "google_kms_crypto_key_iam_binding" "cloud_sql_sa_postgres_cmek" {
  count = var.postgres_kms_cmek_name != null ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.postgres[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${google_project_service_identity.cloud_sql_sa[0].email}",
  ]
}

#-----------------------------------------------------------------------------------
# Secret Manager
#-----------------------------------------------------------------------------------
resource "google_secret_manager_secret_iam_member" "boundary_cert" {
  count = var.boundary_tls_cert_secret_id != "" ? 1 : 0

  secret_id = var.boundary_tls_cert_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_secret_manager_secret_iam_member" "boundary_privkey" {
  count = var.boundary_tls_privkey_secret_id != "" ? 1 : 0

  secret_id = var.boundary_tls_privkey_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_secret_manager_secret_iam_member" "ca_bundle" {
  count = var.boundary_tls_ca_bundle_secret_id != null ? 1 : 0

  secret_id = var.boundary_tls_ca_bundle_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_secret_manager_secret_iam_member" "boundary_license" {
  count = var.boundary_license_secret_id != "" ? 1 : 0

  secret_id = var.boundary_license_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.boundary.email}"
}

#-----------------------------------------------------------------------------------
# KMS Manager
#-----------------------------------------------------------------------------------
resource "google_kms_crypto_key_iam_member" "created_root_operator" {
  count = var.create_root_key ? 1 : 0

  crypto_key_id = google_kms_crypto_key.root[0].id
  role          = "roles/cloudkms.cryptoOperator"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "created_root_viewer" {
  count = var.create_root_key ? 1 : 0

  crypto_key_id = google_kms_crypto_key.root[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "created_recovery_operator" {
  count = var.create_recovery_key ? 1 : 0

  crypto_key_id = google_kms_crypto_key.recovery[0].id
  role          = "roles/cloudkms.cryptoOperator"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "created_recovery_viewer" {
  count = var.create_recovery_key ? 1 : 0

  crypto_key_id = google_kms_crypto_key.recovery[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "created_worker_operator" {
  count = var.create_worker_key ? 1 : 0

  crypto_key_id = google_kms_crypto_key.worker[0].id
  role          = "roles/cloudkms.cryptoOperator"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "created_worker_viewer" {
  count         = var.create_worker_key ? 1 : 0
  crypto_key_id = google_kms_crypto_key.worker[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "created_bsr_operator" {
  count = var.create_bsr_key && var.enable_session_recording ? 1 : 0

  crypto_key_id = google_kms_crypto_key.bsr[0].id
  role          = "roles/cloudkms.cryptoOperator"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "created_bsr_viewer" {
  count = var.create_bsr_key && var.enable_session_recording ? 1 : 0

  crypto_key_id = google_kms_crypto_key.bsr[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "existing_root_operator" {
  count = var.root_key_name != null ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.root[0].id
  role          = "roles/cloudkms.cryptoOperator"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "existing_root_viewer" {
  count = var.root_key_name != null ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.root[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "existing_recovery_operator" {
  count = var.recovery_key_name != null ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.recovery[0].id
  role          = "roles/cloudkms.cryptoOperator"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "existing_recovery_viewer" {
  count = var.recovery_key_name != null ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.recovery[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "existing_worker_operator" {
  count = var.worker_key_name != null ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.worker[0].id
  role          = "roles/cloudkms.cryptoOperator"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "existing_worker_viewer" {
  count = var.worker_key_name != null ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.worker[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "existing_bsr_operator" {
  count = var.bsr_key_name != null && var.enable_session_recording ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.bsr[0].id
  role          = "roles/cloudkms.cryptoOperator"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

resource "google_kms_crypto_key_iam_member" "existing_bsr_viewer" {
  count = var.bsr_key_name != null && var.enable_session_recording ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.bsr[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.boundary.email}"
}

#-----------------------------------------------------------------------------------
# Boundary Session Recording Service Account
#-----------------------------------------------------------------------------------
resource "google_service_account" "bsr" {
  count = var.enable_session_recording ? 1 : 0

  account_id   = "${var.friendly_name_prefix}-bnd-bsr-svc-acct"
  display_name = "${var.friendly_name_prefix}-boundary-bsr-svc-acct"
  description  = "Service Account allowing Boundary workers(s) to interact Google Cloud Storage bucket for session recording."
}

resource "google_service_account_key" "bsr" {
  count = var.enable_session_recording ? 1 : 0

  service_account_id = google_service_account.bsr[0].name
}

resource "google_storage_hmac_key" "bsr" {
  count = var.enable_session_recording ? 1 : 0

  service_account_email = google_service_account.bsr[0].email
}

#-----------------------------------------------------------------------------------
# Cloud Storage Buckets
#-----------------------------------------------------------------------------------
resource "google_storage_bucket_iam_member" "bsr_object_admin" {
  count = var.enable_session_recording ? 1 : 0

  bucket = google_storage_bucket.bsr[0].id
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.bsr[0].email}"
}

resource "google_storage_bucket_iam_member" "bsr_reader" {
  count = var.enable_session_recording ? 1 : 0

  bucket = google_storage_bucket.bsr[0].id
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.bsr[0].email}"
}

# #-----------------------------------------------------------------------------------
# # Cloud Storage Bucket Encryption
# #-----------------------------------------------------------------------------------
# resource "google_kms_crypto_key_iam_member" "gcs_bucket" {
#   count = var.gcs_bucket_key_name == null ? 0 : 1

#   crypto_key_id = data.google_kms_crypto_key.gcs_bucket[0].id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   member        = "serviceAccount:${google_service_account.tfe.email}"
# }

# resource "google_kms_crypto_key_iam_member" "gcs_account" {
#   count = var.gcs_bucket_key_name == null ? 0 : 1

#   crypto_key_id = data.google_kms_crypto_key.gcs_bucket[0].id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

#   member = "serviceAccount:${data.google_storage_project_service_account.project.email_address}"
# }
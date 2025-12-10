# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Google cloud storage (GCS) bucket
#------------------------------------------------------------------------------
resource "random_id" "gcs_suffix" {
  count = var.enable_session_recording ? 1 : 0

  byte_length = 4
}

resource "google_storage_bucket" "bsr" {
  count = var.enable_session_recording ? 1 : 0

  name                        = "${var.friendly_name_prefix}-boundary-bsr-${random_id.gcs_suffix[0].hex}"
  location                    = var.bsr_gcs_location
  storage_class               = var.bsr_gcs_storage_class
  uniform_bucket_level_access = var.bsr_gcs_uniform_bucket_level_access
  force_destroy               = var.bsr_gcs_force_destroy
  labels                      = var.common_labels

  dynamic "encryption" {
    for_each = var.bsr_gcs_kms_key_name != null ? ["encryption"] : []

    content {
      default_kms_key_name = data.google_kms_crypto_key.tfe_gcs_cmek[0].id
    }
  }

  versioning {
    enabled = var.bsr_gcs_versioning_enabled
  }

  depends_on = [google_kms_crypto_key_iam_binding.gcp_project_gcs_cmek]
}

#------------------------------------------------------------------------------
# KMS Google cloud storage (GCS) customer managed encryption key
#------------------------------------------------------------------------------
locals {
  gcs_service_account_email = "service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_binding" "gcp_project_gcs_cmek" {
  count = var.bsr_gcs_kms_key_name != null ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.bsr_key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${local.gcs_service_account_email}",
  ]
}

data "google_kms_key_ring" "bsr_gcs" {
  count = var.bsr_gcs_kms_key_ring_name != null && var.enable_session_recording ? 1 : 0

  name     = var.bsr_gcs_kms_key_ring_name
  location = lower(var.bsr_gcs_location)
}

data "google_kms_crypto_key" "bsr_key" {
  count = var.bsr_gcs_kms_key_name != null && var.enable_session_recording ? 1 : 0

  name     = var.bsr_gcs_kms_key_name
  key_ring = data.google_kms_key_ring.bsr_gcs[0].id
}

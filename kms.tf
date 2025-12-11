# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

resource "random_id" "gcs_key_ring_suffix" {
  byte_length = 4
}

#-----------------------------------------------------------------------------------
# KMS Encryption
#-----------------------------------------------------------------------------------
data "google_kms_key_ring" "kms" {
  count = var.key_ring_name != null ? 1 : 0

  name     = var.key_ring_name
  location = var.key_ring_location != null || data.google_client_config.default.region != null ? var.key_ring_location != null ? var.key_ring_location : data.google_client_config.default.region : var.region
}

data "google_kms_crypto_key" "root" {
  count = var.root_key_name != null ? 1 : 0

  name     = var.root_key_name
  key_ring = data.google_kms_key_ring.kms[0].id
}

data "google_kms_crypto_key" "recovery" {
  count = var.recovery_key_name != null ? 1 : 0

  name     = var.recovery_key_name
  key_ring = data.google_kms_key_ring.kms[0].id
}

data "google_kms_crypto_key" "worker" {
  count = var.worker_key_name != null ? 1 : 0

  name     = var.worker_key_name
  key_ring = data.google_kms_key_ring.kms[0].id
}

data "google_kms_crypto_key" "bsr" {
  count = var.bsr_key_name != null ? 1 : 0

  name     = var.bsr_key_name
  key_ring = data.google_kms_key_ring.kms[0].id
}

resource "google_kms_key_ring" "kms" {
  count = var.create_key_ring ? 1 : 0

  name     = "${var.friendly_name_prefix}-boundary-key-ring-${random_id.gcs_key_ring_suffix.id}"
  location = var.key_ring_location != null || data.google_client_config.default.region != null ? var.key_ring_location != null ? var.key_ring_location : data.google_client_config.default.region : var.region
}

resource "google_kms_crypto_key" "root" {
  count = var.create_root_key ? 1 : 0

  name            = "${var.friendly_name_prefix}-boundary-root-key"
  key_ring        = google_kms_key_ring.kms[0].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "31536000s"
  labels          = var.common_labels

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "recovery" {
  count = var.create_recovery_key ? 1 : 0

  name            = "${var.friendly_name_prefix}-boundary-recovery-key"
  key_ring        = google_kms_key_ring.kms[0].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "31536000s"
  labels          = var.common_labels

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "worker" {
  count = var.create_worker_key ? 1 : 0

  name            = "${var.friendly_name_prefix}-boundary-worker-key"
  key_ring        = google_kms_key_ring.kms[0].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "31536000s"
  labels          = var.common_labels

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "bsr" {
  count = var.create_bsr_key && var.enable_session_recording ? 1 : 0

  name            = "${var.friendly_name_prefix}-boundary-bsr-key"
  key_ring        = google_kms_key_ring.kms[0].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "31536000s"
  labels          = var.common_labels

  lifecycle {
    prevent_destroy = false
  }
}

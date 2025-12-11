# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------------------------------------------
# Boundary URLs
#------------------------------------------------------------------------------------------------------------------
output "boundary_url" {
  value       = "https://${var.boundary_fqdn}:9200"
  description = "URL of Boundary application based on `boundary_fqdn` input."
}

output "boundary_fqdn" {
  value       = var.boundary_fqdn
  description = "`boundary_fqdn` input."
}

output "api_lb_ip_address" {
  value       = google_compute_address.api.address
  description = "IP Address of the API Load Balancer."
}

output "cluster_lb_ip_address" {
  value       = google_compute_address.cluster.address
  description = "IP Address of the API Load Balancer."
}

#------------------------------------------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------------------------------------------

output "google_sql_database_instance_id" {
  value       = google_sql_database_instance.boundary.id
  description = "ID of Cloud SQL DB instance."
}

output "gcp_db_instance_ip" {
  value       = google_sql_database_instance.boundary.private_ip_address
  description = "Cloud SQL DB instance IP."
}

#------------------------------------------------------------------------------------------------------------------
# KMS
#------------------------------------------------------------------------------------------------------------------
output "created_boundary_keyring_name" {
  value       = try(google_kms_key_ring.kms[0].name, null)
  description = "Name of the created Boundary KMS key ring."
}

output "created_boundary_root_key_name" {
  value       = try(google_kms_crypto_key.root[0].name, null)
  description = "Name of the created Boundary root KMS key."
}

output "created_boundary_recovery_key_name" {
  value       = try(google_kms_crypto_key.recovery[0].name, null)
  description = "Name of the created Boundary recovery KMS key."
}

output "created_boundary_worker_key_name" {
  value       = try(google_kms_crypto_key.worker[0].name, null)
  description = "Name of the created Boundary worker KMS key."
}

output "created_boundary_bsr_key_name" {
  value       = try(google_kms_crypto_key.bsr[0].name, null)
  description = "Name of the created Boundary BSR KMS key."
}

output "provided_boundary_keyring_name" {
  value       = try(data.google_kms_key_ring.kms[0].name, null)
  description = "Name of the Provided Boundary KMS key ring."
}

output "provided_boundary_root_key_name" {
  value       = try(data.google_kms_crypto_key.root[0].name, null)
  description = "Name of the Provided Boundary root KMS key."
}

output "provided_boundary_recovery_key_name" {
  value       = try(data.google_kms_crypto_key.recovery[0].name, null)
  description = "Name of the Provided Boundary recovery KMS key."
}

output "provided_boundary_worker_key_name" {
  value       = try(data.google_kms_crypto_key.worker[0].name, null)
  description = "Name of the Provided Boundary worker KMS key."
}

output "provided_boundary_bsr_key_name" {
  value       = try(data.google_kms_crypto_key.bsr[0].name, null)
  description = "Name of the provided Boundary BSR KMS key."
}

#------------------------------------------------------------------------------------------------------------------
# Boundary Session Recording
#------------------------------------------------------------------------------------------------------------------
output "bsr_bucket_name" {
  value       = try(google_storage_bucket.bsr[0].name, null)
  description = "Name of the Google Cloud Storage bucket."
}

output "bsr_hmac_key_access_id" {
  value       = try(google_storage_hmac_key.bsr[0].access_id, null)
  description = "Value of the Google Cloud Storage HMAC key access id."
}

output "bsr_hmac_key_secret" {
  value       = try(google_storage_hmac_key.bsr[0].secret, null)
  description = "Value of the Google Cloud Storage HMAC key access id."
  sensitive   = true
}

output "bsr_cloud_storage_endpoint_url" {
  value       = var.enable_session_recording ? "https://storage.googleapis.com" : null
  description = "Google Cloud Storage endpoint URL."
}

# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "boundary_url" {
  value       = module.boundary.boundary_url
  description = "URL to access Boundary application based on value of `boundary_fqdn` input."
}

output "boundary_api_lb_ip_address" {
  value       = module.boundary.api_lb_ip_address
  description = "DNS name of the Load Balancer for Boundary clients."
}

output "boundary_cluster_lb_ip_address" {
  value       = module.boundary.cluster_lb_ip_address
  description = "DNS name of the Load Balancer for Boundary clients."
}

#------------------------------------------------------------------------------------------------------------------
# KMS
#------------------------------------------------------------------------------------------------------------------
output "created_boundary_keyring_name" {
  value       = module.boundary.created_boundary_keyring_name
  description = "Name of the Boundary KMS key ring."
}

output "created_boundary_root_key_name" {
  value       = module.boundary.created_boundary_root_key_name
  description = "Name of the Boundary root KMS key."
}

output "created_boundary_recovery_key_name" {
  value       = module.boundary.created_boundary_recovery_key_name
  description = "Name of the Boundary recovery KMS key."

}

output "created_boundary_worker_key_name" {
  value       = module.boundary.created_boundary_worker_key_name
  description = "Name of the Boundary worker KMS key."
}

output "created_boundary_bsr_key_name" {
  value       = module.boundary.created_boundary_bsr_key_name
  description = "Name of the Boundary worker KMS key."
}

output "provided_boundary_keyring_name" {
  value       = module.boundary.provided_boundary_keyring_name
  description = "Name of the Boundary KMS key ring."
}

output "provided_boundary_root_key_name" {
  value       = module.boundary.provided_boundary_root_key_name
  description = "Name of the Boundary root KMS key."
}

output "provided_boundary_recovery_key_name" {
  value       = module.boundary.provided_boundary_recovery_key_name
  description = "Name of the Boundary recovery KMS key."

}

output "provided_boundary_worker_key_name" {
  value       = module.boundary.provided_boundary_worker_key_name
  description = "Name of the Boundary worker KMS key."
}

output "provided_boundary_bsr_key_name" {
  value       = module.boundary.provided_boundary_bsr_key_name
  description = "Name of the Boundary worker KMS key."
}

#------------------------------------------------------------------------------------------------------------------
# Boundary Session Recording
#------------------------------------------------------------------------------------------------------------------
output "bsr_hmac_key_access_id" {
  value       = module.boundary.bsr_hmac_key_access_id
  description = "Value of the Google Cloud Storage HMAC key access id."
}

output "bsr_hmac_key_secret" {
  value       = module.boundary.bsr_hmac_key_secret
  description = "Value of the Google Cloud Storage HMAC key access id."
  sensitive   = true
}

output "bsr_cloud_storage_endpoint_url" {
  value       = module.boundary.bsr_cloud_storage_endpoint_url
  description = "Google Cloud Storage endpoint URL."
}

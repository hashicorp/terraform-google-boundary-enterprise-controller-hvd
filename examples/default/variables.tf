# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
variable "project_id" {
  type        = string
  description = "ID of GCP Project to create resources in."
}

variable "region" {
  type        = string
  description = "Region of GCP Project to create resources in."
}

variable "friendly_name_prefix" {
  type        = string
  description = "Friendly name prefix used for uniquely naming resources. This should be unique across all deployments"
  validation {
    condition     = !strcontains(var.friendly_name_prefix, "boundary")
    error_message = "Value must not contain 'boundary' to avoid redundancy in naming conventions."
  }
  validation {
    condition     = length(var.friendly_name_prefix) < 13
    error_message = "Value can only contain alphanumeric characters and must be less than 13 characters."
  }
}

variable "common_labels" {
  type        = map(string)
  description = "Common labels to apply to GCP resources."
  default     = {}
}

#------------------------------------------------------------------------------
# Prereqs
#------------------------------------------------------------------------------
variable "boundary_license_secret_id" {
  type        = string
  description = "ID of Secrets Manager secret for Boundary license file."
}

variable "boundary_tls_cert_secret_id" {
  type        = string
  description = "ID of Secrets Manager secret for Boundary TLS certificate in PEM format. Secret must be stored as a base64-encoded string."
}

variable "boundary_tls_privkey_secret_id" {
  type        = string
  description = "ID of Secrets Manager secret for Boundary TLS private key in PEM format. Secret must be stored as a base64-encoded string."
}

variable "boundary_tls_ca_bundle_secret_id" {
  type        = string
  description = "ID of Secrets Manager secret for private/custom TLS Certificate Authority (CA) bundle in PEM format. Secret must be stored as a base64-encoded string."
  default     = null
}

variable "boundary_database_password_secret_version" {
  type        = string
  description = "Name of PostgreSQL database password secret to retrieve from GCP Secret Manager."
  default     = null
}

variable "additional_package_names" {
  type        = set(string)
  description = "List of additional repository package names to install"
  default     = []
}

#------------------------------------------------------------------------------
# Boundary Configuration Settings
#------------------------------------------------------------------------------
variable "boundary_fqdn" {
  type        = string
  description = "Fully qualified domain name of boundary instance. This name should resolve to the load balancer IP address and will be what clients use to access boundary."
}

variable "boundary_tls_disable" {
  type        = bool
  description = "Boolean to disable TLS for boundary."
  default     = false
}

variable "boundary_version" {
  type        = string
  description = "Version of Boundary to install."
  default     = "0.17.1+ent"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\+ent$", var.boundary_version))
    error_message = "Value must be in the format 'X.Y.Z+ent'."
  }
}

variable "enable_session_recording" {
  type        = bool
  description = "Boolean to enable session recording in Boundary."
  default     = false
}

#-----------------------------------------------------------------------------------
# Networking
#-----------------------------------------------------------------------------------
variable "vpc" {
  type        = string
  description = "Existing VPC network to deploy Boundary resources into."
}

variable "vpc_project_id" {
  type        = string
  description = "ID of GCP Project where the existing VPC resides if it is different than the default project."
  default     = null
}

variable "subnet_name" {
  type        = string
  description = "Existing VPC subnetwork for Boundary instance(s) and optionally Boundary frontend load balancer."
}

variable "api_load_balancing_scheme" {
  type        = string
  description = "Determines whether API load balancer is internal-facing or external-facing."
  default     = "internal"

  validation {
    condition     = contains(["external", "internal"], var.api_load_balancing_scheme)
    error_message = "Supported values are `external`, `internal`."
  }
}

variable "create_cloud_dns_record" {
  type        = bool
  description = "Boolean to create Google Cloud DNS record for `boundary_fqdn` resolving to load balancer IP. `cloud_dns_managed_zone` is required when `true`."
  default     = false

  validation {
    condition     = var.create_cloud_dns_record == true ? var.cloud_dns_managed_zone != null : true
    error_message = "Must set a `cloud_dns_managed_zone` when `create_cloud_dns_record` is set to `true`."
  }
}

variable "cloud_dns_managed_zone" {
  type        = string
  description = "Zone name to create Boundary Cloud DNS record in if `create_cloud_dns_record` is set to `true`."
  default     = null
}

#-----------------------------------------------------------------------------------
# Firewall
#-----------------------------------------------------------------------------------
variable "cidr_ingress_ssh_allow" {
  type        = list(string)
  description = "CIDR ranges to allow SSH traffic inbound to Boundary instance(s) via IAP tunnel."
  default     = ["10.0.0.0/16"]
}

variable "cidr_ingress_9200_allow" {
  type        = list(string)
  description = "CIDR ranges to allow 9200 traffic inbound to Boundary instance(s). This is for Boundary Clients using the Boundary API."
  default     = ["0.0.0.0/0"]
}

variable "cidr_ingress_9201_allow" {
  type        = list(string)
  description = "CIDR ranges to allow 9201 traffic inbound to Boundary instance(s). This is for Boundary Ingress Workers accessing the Boundary Controller(s)."
  default     = ["0.0.0.0/0"]
}

#-----------------------------------------------------------------------------------
# Encryption Keys (KMS)
#-----------------------------------------------------------------------------------
variable "key_ring_location" {
  type        = string
  description = "Location of KMS key ring. If not set, the region of the Boundary deployment will be used."
  default     = null
}

variable "postgres_key_ring_name" {
  type        = string
  description = "Name of KMS Key Ring that contains KMS key to use for Cloud SQL for PostgreSQL database encryption. Geographic location of key ring must match location of database instance."
  default     = null
}

variable "postgres_key_name" {
  type        = string
  description = "Name of KMS Key to use for Cloud SQL for PostgreSQL encryption."
  default     = null
}

variable "create_key_ring" {
  type        = bool
  description = "Boolean to create a KMS key ring for Boundary."
  default     = true
}

variable "create_root_key" {
  type        = bool
  description = "Boolean to create a KMS root key for Boundary."
  default     = true
}

variable "create_recovery_key" {
  type        = bool
  description = "Boolean to create a KMS recovery key for Boundary."
  default     = true
}

variable "create_worker_key" {
  type        = bool
  description = "Boolean to create a KMS worker key for Boundary."
  default     = true
}

variable "create_bsr_key" {
  type        = bool
  description = "Boolean to create a KMS BSR key for Boundary."
  default     = false
}

variable "key_ring_name" {
  type        = string
  description = "Name of an existing KMS Key Ring to use for Boundary"
  default     = null
  validation {
    condition     = var.key_ring_name == false ? var.key_ring_name != null : true
    error_message = "Must set `key_ring_name` when `create_key_ring` is set to `false`."
  }
}

variable "root_key_name" {
  type        = string
  description = "Name of an existing KMS root key to use for Boundary"
  default     = null
  validation {
    condition     = var.root_key_name == false ? var.root_key_name != null : true
    error_message = "Must set `root_key_name` when `create_root_key` is set to `false`."
  }
}

variable "recovery_key_name" {
  type        = string
  description = "Name of an existing KMS recovery key to use for Boundary"
  default     = null
  validation {
    condition     = var.recovery_key_name == false ? var.recovery_key_name != null : true
    error_message = "Must set `recovery_key_name` when `create_recovery_key` is set to `false`."
  }
}

variable "worker_key_name" {
  type        = string
  description = "Name of an existing KMS worker key to use for Boundary"
  default     = null
  validation {
    condition     = var.worker_key_name == false ? var.worker_key_name != null : true
    error_message = "Must set `worker_key_name` when `create_worker_key` is set to `false`."
  }
}

variable "bsr_key_name" {
  type        = string
  description = "Name of an existing KMS BSR key to use for Boundary"
  default     = null
}

#-----------------------------------------------------------------------------------
# Compute
#-----------------------------------------------------------------------------------
variable "image_project" {
  type        = string
  description = "ID of project in which the resource belongs."
  default     = "ubuntu-os-cloud"
}

variable "image_name" {
  type        = string
  description = "VM image for Boundary instance(s)."
  default     = "ubuntu-2404-noble-amd64-v20240607"
}

variable "machine_type" {
  type        = string
  description = "(Optional string) Size of machine to create. Default `n2-standard-4` from https://cloud.google.com/compute/docs/machine-resource."
  default     = "n2-standard-4"
}

variable "disk_size_gb" {
  type        = number
  description = "Size in Gigabytes of root disk of Boundary instance(s)."
  default     = 50
}

variable "instance_count" {
  type        = number
  description = "Target size of Managed Instance Group for number of Boundary instances to run. Only specify a value greater than 1 if `enable_active_active` is set to `true`."
  default     = 1
}

variable "initial_delay_sec" {
  type        = number
  description = "The number of seconds that the managed instance group waits before it applies autohealing policies to new instances or recently recreated instances"
  default     = 300
}

variable "enable_iap" {
  type        = bool
  default     = true
  description = "(Optional bool) Enable https://cloud.google.com/iap/docs/using-tcp-forwarding#console, defaults to `true`. "
}

#-----------------------------------------------------------------------------------
# Cloud SQL for PostgreSQL
#-----------------------------------------------------------------------------------
variable "boundary_database_name" {
  type        = string
  description = "Name of boundary PostgreSQL database to create."
  default     = "boundary"
}

variable "boundary_database_user" {
  type        = string
  description = "Name of boundary PostgreSQL database user to create."
  default     = "boundary"
}

variable "postgres_version" {
  type        = string
  description = "PostgreSQL version to use."
  default     = "POSTGRES_16"
}

variable "postgres_availability_type" {
  type        = string
  description = "Availability type of Cloud SQL PostgreSQL instance."
  default     = "REGIONAL"
}

variable "postgres_machine_type" {
  type        = string
  description = "Machine size of Cloud SQL PostgreSQL instance."
  default     = "db-custom-4-16384"
}

variable "postgres_disk_size" {
  type        = number
  description = "Size in GB of PostgreSQL disk."
  default     = 50
}

variable "postgres_backup_start_time" {
  type        = string
  description = "HH:MM time format indicating when daily automatic backups of Cloud SQL for PostgreSQL should run. Defaults to 12 AM (midnight) UTC."

  default = "00:00"
}

variable "postgres_ssl_mode" {
  type        = string
  description = "Indicates whether to enforce TLS/SSL connections to the Cloud SQL for PostgreSQL instance."
  default     = "ENCRYPTED_ONLY"
}

variable "postgres_maintenance_window" {
  type = object({
    day          = number
    hour         = number
    update_track = string
  })
  description = "Optional maintenance window settings for the Cloud SQL for PostgreSQL instance."
  default = {
    day          = 7 # default to Sunday
    hour         = 0 # default to midnight
    update_track = "stable"
  }

  validation {
    condition     = var.postgres_maintenance_window.day >= 0 && var.postgres_maintenance_window.day <= 7
    error_message = "`day` must be an integer between 0 and 7 (inclusive)."
  }

  validation {
    condition     = var.postgres_maintenance_window.hour >= 0 && var.postgres_maintenance_window.hour <= 23
    error_message = "`hour` must be an integer between 0 and 23 (inclusive)."
  }

  validation {
    condition     = contains(["stable", "canary", "week5"], var.postgres_maintenance_window.update_track)
    error_message = "`update_track` must be either 'canary', 'stable', or 'week5'."
  }
}

variable "postgres_insights_config" {
  type = object({
    query_insights_enabled  = bool
    query_plans_per_minute  = number
    query_string_length     = number
    record_application_tags = bool
    record_client_address   = bool
  })
  description = "Configuration settings for Cloud SQL for PostgreSQL insights."
  default = {
    query_insights_enabled  = false
    query_plans_per_minute  = 5
    query_string_length     = 1024
    record_application_tags = false
    record_client_address   = false
  }
}

variable "postgres_kms_keyring_name" {
  type        = string
  description = "Name of Cloud KMS Key Ring that contains KMS key to use for Cloud SQL for PostgreSQL. Geographic location (region) of key ring must match the location of the boundary Cloud SQL for PostgreSQL database instance."
  default     = null
}

variable "postgres_kms_cmek_name" {
  type        = string
  description = "Name of Cloud KMS customer managed encryption key (CMEK) to use for Cloud SQL for PostgreSQL database instance."
  default     = null
}
variable "custom_user_data_template" {
  type        = string
  description = "(optional) Alternative template file to provide for instance template metadata script. place the file in your local `./templates folder` no path required"
  default     = "boundary_custom__data.sh.tpl"
  validation {
    condition     = can(fileexists("${path.cwd}/templates/${var.custom_user_data_template}") || fileexists("${path.module}/templates/${var.custom_user_data_template}"))
    error_message = "File `${path.cwd}/templates/${var.custom_user_data_template}` or `${path.module}/templates/${var.custom_user_data_template} not found or not readable"
  }
}
#------------------------------------------------------------------------------
# Google cloud storage (GCS) bucket for Boundary Session Recording
#------------------------------------------------------------------------------
variable "bsr_gcs_location" {
  type        = string
  description = "Location of TFE GCS bucket to create."
  default     = "US"

  validation {
    condition     = contains(["US", "EU", "ASIA"], var.bsr_gcs_location)
    error_message = "Supported values are 'US', 'EU', and 'ASIA'."
  }
}

variable "bsr_gcs_storage_class" {
  type        = string
  description = "Storage class of TFE GCS bucket."
  default     = "MULTI_REGIONAL"
}

variable "bsr_gcs_uniform_bucket_level_access" {
  type        = bool
  description = "Boolean to enable uniform bucket level access on TFE GCS bucket."
  default     = true
}

variable "bsr_gcs_force_destroy" {
  type        = bool
  description = "Boolean indicating whether to allow force destroying the TFE GCS bucket. GCS bucket can be destroyed if it is not empty when `true`."
  default     = false
}

variable "bsr_gcs_versioning_enabled" {
  type        = bool
  description = "Boolean to enable versioning on TFE GCS bucket."
  default     = true
}

variable "bsr_gcs_kms_key_ring_name" {
  type        = string
  description = "Name of Cloud KMS key ring that contains KMS customer managed encryption key (CMEK) to use for TFE GCS bucket encryption. Geographic location (region) of the key ring must match the location of the TFE GCS bucket."
  default     = null
}

variable "bsr_gcs_kms_key_name" {
  type        = string
  description = "Name of Cloud KMS customer managed encryption key (CMEK) to use for TFE GCS bucket encryption."
  default     = null
}

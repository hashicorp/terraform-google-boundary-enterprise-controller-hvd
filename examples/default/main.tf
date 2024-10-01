# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.39"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.39"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "boundary" {
  source = "../.."

  # Common
  friendly_name_prefix = var.friendly_name_prefix
  common_labels        = var.common_labels
  project_id           = var.project_id
  region               = var.region

  # Pre-requisites
  boundary_license_secret_id                = var.boundary_license_secret_id
  boundary_tls_cert_secret_id               = var.boundary_tls_cert_secret_id
  boundary_tls_privkey_secret_id            = var.boundary_tls_privkey_secret_id
  boundary_tls_ca_bundle_secret_id          = var.boundary_tls_ca_bundle_secret_id
  postgres_key_ring_name                    = var.postgres_key_ring_name
  postgres_key_name                         = var.postgres_key_name
  boundary_database_password_secret_version = var.boundary_database_password_secret_version

  # Boundary configuration settings
  boundary_fqdn            = var.boundary_fqdn
  boundary_version         = var.boundary_version
  enable_session_recording = var.enable_session_recording

  # DNS (optional)
  create_cloud_dns_record = var.create_cloud_dns_record
  cloud_dns_managed_zone  = var.cloud_dns_managed_zone

  # Networking
  vpc                       = var.vpc
  vpc_project_id            = var.vpc_project_id
  subnet_name               = var.subnet_name
  api_load_balancing_scheme = var.api_load_balancing_scheme
  cidr_ingress_ssh_allow    = var.cidr_ingress_ssh_allow
  cidr_ingress_9200_allow   = var.cidr_ingress_9200_allow
  cidr_ingress_9201_allow   = var.cidr_ingress_9201_allow

  # Compute
  instance_count = var.instance_count
  enable_iap     = var.enable_iap

  #KMS
  key_ring_location = var.key_ring_location
  create_bsr_key    = var.create_bsr_key
}

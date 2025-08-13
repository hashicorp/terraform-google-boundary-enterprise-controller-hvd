# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#-----------------------------------------------------------------------------------
# User Data (cloud-init) arguments
#-----------------------------------------------------------------------------------
locals {
  custom_user_data_template = fileexists("${path.cwd}/templates/${var.custom_user_data_template}") ? "${path.cwd}/templates/${var.custom_user_data_template}" : "${path.module}/templates/${var.custom_user_data_template}"
  custom_data_args = {

    # # https://developer.hashicorp.com/boundary/docs/configuration/controller

    # prereqs
    boundary_license_secret_id       = var.boundary_license_secret_id
    boundary_tls_cert_secret_id      = var.boundary_tls_cert_secret_id
    boundary_tls_privkey_secret_id   = var.boundary_tls_privkey_secret_id
    boundary_tls_ca_bundle_secret_id = var.boundary_tls_ca_bundle_secret_id == null ? "NONE" : var.boundary_tls_ca_bundle_secret_id
    additional_package_names         = join(" ", var.additional_package_names)

    # Boundary settings
    boundary_version     = var.boundary_version
    systemd_dir          = "/etc/systemd/system",
    boundary_dir_bin     = "/usr/bin",
    boundary_dir_config  = "/etc/boundary.d",
    boundary_dir_home    = "/opt/boundary",
    boundary_install_url = format("https://releases.hashicorp.com/boundary/%s/boundary_%s_linux_amd64.zip", var.boundary_version, var.boundary_version), boundary_tls_disable = var.boundary_tls_disable

    # Database settings
    boundary_database_host     = google_sql_database_instance.boundary.private_ip_address
    boundary_database_name     = google_sql_database.boundary.name
    boundary_database_user     = google_sql_user.boundary.name
    boundary_database_password = google_sql_user.boundary.password #nonsensitive(data.google_secret_manager_secret_version.boundary_database_password_secret_id[0].secret_data)

    # KMS settings
    key_ring_project       = var.project_id
    key_ring_region        = var.key_ring_location != null || data.google_client_config.default.region != null ? var.key_ring_location != null ? var.key_ring_location : data.google_client_config.default.region : var.region
    root_key_ring_name     = var.key_ring_name != null ? var.key_ring_name : google_kms_key_ring.kms[0].name
    root_crypto_name       = var.root_key_name != null ? var.root_key_name : google_kms_crypto_key.root[0].name
    recovery_key_ring_name = var.key_ring_name != null ? var.key_ring_name : google_kms_key_ring.kms[0].name
    recovery_crypto_name   = var.recovery_key_name != null ? var.recovery_key_name : google_kms_crypto_key.recovery[0].name
    worker_key_ring_name   = var.key_ring_name != null ? var.key_ring_name : google_kms_key_ring.kms[0].name
    worker_crypto_name     = var.worker_key_name != null ? var.worker_key_name : google_kms_crypto_key.worker[0].name
    bsr_key_ring_name      = var.key_ring_name != null ? var.key_ring_name : google_kms_key_ring.kms[0].name
    bsr_crypto_name        = try(data.google_kms_crypto_key.bsr[0].name, google_kms_crypto_key.bsr[0].name, "")
  }
}

data "cloudinit_config" "boundary_cloudinit" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "boundary_custom_data.sh"
    content_type = "text/x-shellscript"
    content      = templatefile(local.custom_user_data_template, local.custom_data_args)
  }
}

#-----------------------------------------------------------------------------------
# Instance Template
#-----------------------------------------------------------------------------------

resource "google_compute_instance_template" "boundary" {
  name_prefix    = "${var.friendly_name_prefix}-boundary-controller-template-"
  machine_type   = var.machine_type
  can_ip_forward = true

  disk {
    source_image = data.google_compute_image.boundary.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-ssd"
    mode         = "READ_WRITE"
    type         = "PERSISTENT"
  }

  network_interface {
    subnetwork = var.subnet_name
  }

  metadata = {
    user-data          = data.cloudinit_config.boundary_cloudinit.rendered
    user-data-encoding = "base64"
  }

  service_account {
    scopes = ["cloud-platform"]
    email  = google_service_account.boundary.email
  }

  labels = var.common_labels
  tags   = ["boundary-controller"]

  lifecycle {
    create_before_destroy = true
  }
}

#-----------------------------------------------------------------------------------
# Instance Group
#-----------------------------------------------------------------------------------
data "google_compute_zones" "up" {
  project = var.project_id
  status  = "UP"
}

data "google_compute_image" "boundary" {
  name    = var.image_name
  project = var.image_project
}

resource "google_compute_region_instance_group_manager" "boundary" {
  name                      = "${var.friendly_name_prefix}-boundary-ig-mgr"
  base_instance_name        = "${var.friendly_name_prefix}-boundary-controller-vm"
  distribution_policy_zones = data.google_compute_zones.up.names
  target_size               = var.instance_count

  version {
    instance_template = google_compute_instance_template.boundary.self_link
  }

  dynamic "named_port" {
    for_each = var.api_load_balancing_scheme == true ? [] : [1]

    content {
      name = "boundary-api"
      port = 9200
    }
  }

  named_port {
    name = "boundary-cluster"
    port = 9201
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.boundary_auto_healing.self_link
    initial_delay_sec = var.initial_delay_sec
  }

  update_policy {
    minimal_action = "REPLACE"
    type           = "PROACTIVE"

    max_surge_fixed       = length(data.google_compute_zones.up.names)
    max_unavailable_fixed = length(data.google_compute_zones.up.names)
  }
}

resource "google_compute_health_check" "boundary_auto_healing" {
  name                = "${var.friendly_name_prefix}-boundary-autohealing-health-check"
  check_interval_sec  = 30
  healthy_threshold   = 2
  unhealthy_threshold = 7
  timeout_sec         = 10

  https_health_check {
    port         = 9203
    request_path = "/health"
  }
}

#-----------------------------------------------------------------------------------
# Firewall
#-----------------------------------------------------------------------------------
resource "google_compute_firewall" "allow_ssh" {
  name        = "${var.friendly_name_prefix}-${data.google_compute_network.vpc.name}-boundary-firewall-ssh-allow"
  description = "Allow SSH ingress to Boundary instances from specified CIDR ranges."
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [22]
  }
  source_ranges = var.cidr_ingress_ssh_allow
  target_tags   = ["boundary-controller"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_9200" {
  name        = "${var.friendly_name_prefix}-boundary-firewall-9200-allow"
  description = "Allow 9200 traffic ingress to Boundary instances in ${data.google_compute_network.vpc.name} from specified CIDR ranges."
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [9200]
  }

  source_ranges = var.cidr_ingress_9200_allow
  target_tags   = ["boundary-controller"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_9201" {
  name        = "${var.friendly_name_prefix}-boundary-firewall-9201-allow"
  description = "Allow 9201 traffic ingress to Boundary instances in ${data.google_compute_network.vpc.name} from specified CIDR ranges."
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [9201]
  }

  source_ranges = var.cidr_ingress_9201_allow
  target_tags   = ["boundary-controller"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_iap" {
  count       = var.enable_iap == true ? 1 : 0
  name        = "${var.friendly_name_prefix}-boundary-firewall-iap-allow"
  description = "Allow https://cloud.google.com/iap/docs/using-tcp-forwarding#console traffic"
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [3389, 22]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["boundary-controller"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "health_checks" {
  name        = "${var.friendly_name_prefix}-boundary-health-checks-allow"
  description = "Allow GCP Health Check CIDRs to talk to Boundary in ${data.google_compute_network.vpc.name}."
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [9203]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = ["boundary-controller"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# ------------------------------------------------------------------------------
# Debug rendered boundary custom_data script from template
# ------------------------------------------------------------------------------
# Uncomment this block to debug the rendered boundary custom_data script
# resource "local_file" "debug_custom_data" {
#   content  = templatefile("${path.module}/templates/boundary_custom_data.sh.tpl", local.custom_data_args)
#   filename = "${path.module}/debug/debug_boundary_custom_data.sh"
# }

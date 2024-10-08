# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#-----------------------------------------------------------------------------------
# Networking
#-----------------------------------------------------------------------------------
data "google_compute_subnetwork" "subnet" {
  name = var.subnet_name
}

#-----------------------------------------------------------------------------------
# API Frontend
#-----------------------------------------------------------------------------------
resource "google_compute_address" "api" {
  name         = "${var.friendly_name_prefix}-boundary-controller-api-frontend-lb-ip"
  description  = "Static IP to associate with Boundary Forwarding Rule (frontend of TCP load balancer)."
  address_type = upper(var.api_load_balancing_scheme)
  network_tier = var.api_load_balancing_scheme == "internal" ? null : "PREMIUM"
  subnetwork   = var.api_load_balancing_scheme == "internal" ? data.google_compute_subnetwork.subnet.self_link : null
}

resource "google_compute_forwarding_rule" "api" {
  name                  = "${var.friendly_name_prefix}-boundary-controller-api-tcp-lb"
  backend_service       = google_compute_region_backend_service.api.id
  ip_protocol           = "TCP"
  load_balancing_scheme = upper(var.api_load_balancing_scheme)
  ports                 = [9200]
  network               = var.api_load_balancing_scheme == "internal" ? data.google_compute_subnetwork.subnet.self_link : null
  subnetwork            = var.api_load_balancing_scheme == "internal" ? data.google_compute_subnetwork.subnet.self_link : null
  ip_address            = google_compute_address.api.address
}

#-----------------------------------------------------------------------------------
# API Backend
#-----------------------------------------------------------------------------------
resource "google_compute_region_backend_service" "api" {
  name                  = "${var.friendly_name_prefix}-boundary-controller-api-backend-lb"
  protocol              = "TCP"
  load_balancing_scheme = upper(var.api_load_balancing_scheme)
  timeout_sec           = 60

  port_name = var.api_load_balancing_scheme == "internal" ? null : "boundary-api"
  backend {
    description = "Boundary Backend Regional Internal TCP/UDP Load Balancer"
    group       = google_compute_region_instance_group_manager.boundary.instance_group
  }

  health_checks = [google_compute_region_health_check.api.self_link]
}

resource "google_compute_region_health_check" "api" {
  name               = "${var.friendly_name_prefix}-boundary-controller-api-backend-svc-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  log_config {
    enable = true
  }

  https_health_check {
    port         = 9203
    request_path = "/health"
  }
}

#-----------------------------------------------------------------------------------
# cluster Frontend
#-----------------------------------------------------------------------------------
resource "google_compute_address" "cluster" {
  name         = "${var.friendly_name_prefix}-boundary-controller-cluster-frontend-lb-ip"
  description  = "Static IP to associate with Boundary Forwarding Rule (frontend of TCP load balancer)."
  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.subnet.self_link
}

resource "google_compute_forwarding_rule" "cluster" {
  name                  = "${var.friendly_name_prefix}-boundary-controller-cluster-tcp-lb"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = 9201
  target                = google_compute_region_target_tcp_proxy.cluster.id
  network               = var.vpc
  subnetwork            = data.google_compute_subnetwork.subnet.self_link
  network_tier          = "PREMIUM"
  ip_address            = google_compute_address.cluster.address
}

#-----------------------------------------------------------------------------------
# cluster Backend
#-----------------------------------------------------------------------------------
resource "google_compute_region_backend_service" "cluster" {
  name                  = "${var.friendly_name_prefix}-boundary-controller-cluster-backend-lb"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  locality_lb_policy    = "ROUND_ROBIN"
  timeout_sec           = 60


  port_name = "boundary-cluster"
  backend {
    description                  = "Boundary Backend Regional Internal TCP/UDP Load Balancer"
    group                        = google_compute_region_instance_group_manager.boundary.instance_group
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 1000
    capacity_scaler              = 1.0
  }

  health_checks = [google_compute_region_health_check.cluster.self_link]
}

resource "google_compute_region_target_tcp_proxy" "cluster" {
  name            = "${var.friendly_name_prefix}-boundary-controller-cluster-target-tcp-proxy"
  region          = var.region
  backend_service = google_compute_region_backend_service.cluster.id
}

resource "google_compute_region_health_check" "cluster" {
  name               = "${var.friendly_name_prefix}-boundary-controller-cluster-backend-svc-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  log_config {
    enable = true
  }

  https_health_check {
    port         = 9203
    request_path = "/health"
  }
}

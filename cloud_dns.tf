# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "google_dns_managed_zone" "boundary" {
  count = var.create_cloud_dns_record == true ? 1 : 0

  name = var.cloud_dns_managed_zone
}

resource "google_dns_record_set" "boundary" {
  count = var.create_cloud_dns_record == true ? 1 : 0

  managed_zone = data.google_dns_managed_zone.boundary[0].name
  name         = "${var.boundary_fqdn}."
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_address.api.address]
}
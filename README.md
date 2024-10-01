# Boundary Controller on Google

Terraform module used by HashiCorp Professional Services to deploy Boundary Controller on Google. For deploying workers, please see the [Boundary Workers on Google](https://github.com/hashicorp-services/terraform-google-boundary-worker) module. Prior to deploying in production, the code should be reviewed, potentially tweaked/customized, and tested in a non-production environment.

<!-- ## Boundary Architecture

This diagram shows a Boundary deployment with one controller and two sets of Boundary Workers, one for ingress and another for egress. Please review [Boundary deployment customizations doc](./docs/deployment-customizations.md) to understand different deployment settings for the Boundary deployment. diagram wip

![Boundary on Google](./docs/images/boundary-diagram.png) -->

## Prerequisites

### General

- Terraform CLI `>= 1.9` installed on workstations.
- `Git` CLI and Visual Studio Code editor installed on workstations are strongly recommended.
- Google account that Boundary will be hosted in with permissions to provision these [resources](#resources) via Terraform CLI.
- (Optional) Google GCS for [GCS Remote State backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs) that will solely be used to stand up the Boundary infrastructure via Terraform CLI (Community Edition).

### Google

- GCP Project Created
- Following APIs enabled
  - dns.googleapis.com
  - secretmanager.googleapis.com
  - compute.googleapis.com  
  - servicenetworking.googleapis.com  
  - cloudkms.googleapis.com
  - networkservices.googleapis.com

### Networking

- Google VPC
  - Subnet
  - Proxy Subnet with purpose set to `REGIONAL_MANAGED_PROXY`
  - Private Service Access Configured
  - Firewall rules will be created with this Module. If that is not possible (shared VPC) then the firewall rules in this module will need to be created in the shared VPC
  - [Boundary Network connectivity](https://developer.hashicorp.com/boundary/docs/install-boundary/architecture/system-requirements#network-connectivity)

### Secrets Manager

- **Boundary license file** - raw contents of Boundary license file (`*.hclic`) (ex: `cat boundary.hclic`)
- **Google SQL (PostgreSQL) database password** - random characters stored as plaintext secret.
- **Boundary TLS certificate** - file in PEM format, base64-encoded into a string, and stored as a plaintext secret.
- **Boundary TLS certificate private key** - file in PEM format, base64-encoded into a string, and stored as a plaintext secret.
- **TLS CA bundle** - file in PEM format, base64-encoded into a string, and stored as a plaintext secret.

>📝 Note: see the [Boundary cert rotation docs](./docs/boundary-cert-rotation.md) for instructions on how to base64-encode the certificates with proper formatting.

### Compute

One of the following mechanisms for shell access to Boundary VM instances:

- Ability to enable Google IAP (this module supports this via a boolean input variable).
- SSH key and user

## Usage

1. Create/configure/validate the applicable [prerequisites](#prerequisites).

2. Nested within the [examples](./examples/) directory are subdirectories that contain ready-made Terraform configurations of example scenarios for how to call and deploy this module. To get started, choose an example scenario. If you are not sure which example scenario to start with, then we recommend starting with the [default](examples/default) example.

3. Copy all of the Terraform files from your example scenario of choice into a new destination directory to create your root Terraform configuration that will manage your Boundary deployment. If you are not sure where to create this new directory, it is common for us to see users create an `environments/` directory at the root of this repo, and then a subdirectory for each Boundary instance deployment, like so:

```sh
.
└── environments
    ├── production
    │   ├── backend.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── terraform.tfvars
    │   └── variables.tf
    └── sandbox
        ├── backend.tf
        ├── main.tf
        ├── outputs.tf
        ├── terraform.tfvars
        └── variables.tf
```

  >📝 Note: in this example, the user will have two separate Boundary deployments; one for their `sandbox` environment, and one for their `production` environment. This is recommended, but not required.

4. (Optional) Uncomment and update the [gcs remote state backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs) configuration provided in the `backend.tf` file with your own custom values. While this step is highly recommended, it is technically not required to use a remote backend config for your Boundary deployment.

5. Populate your own custom values into the `terraform.tfvars.example` file that was provided, and remove the `.example` file extension such that the file is now named `terraform.tfvars`.

6. Navigate to the directory of your newly created Terraform configuration for your Boundary Controller deployment, and run `terraform init`, `terraform plan`, and `terraform apply`.

7. After your `terraform apply` finishes successfully, you can monitor the installation progress by connecting to your Boundary VM instance shell via SSH or Google IAP and observing the cloud-init (user_data) logs:

   Higher-level logs:

   ```sh
   tail -f /var/log/boundary-cloud-init.log
   ```

   Lower-level logs:

   ```sh
   journalctl -xu cloud-final -f
   ```

   >📝 Note: the `-f` argument is to follow the logs as they append in real-time, and is optional. You may remove the `-f` for a static view.

   The log files should display the following message after the cloud-init (user_data) script finishes successfully:

   ```sh
   [INFO] boundary_custom_data script finished successfully!
   ```

8.  Once the cloud-init script finishes successfully, while still connected to the VM via SSH you can check the status of the boundary service:

   ```sh
   sudo systemctl status boundary
   ```

9. After the Boundary Controller is deployed the Boundary system will be partially initialized. To complete the initialization process and setup an initial auth method, username and password, please use the [terraform-boundary-bootstrap-hvd](https://registry.terraform.io/modules/hashicorp/boundary-bootstrap-hvd/boundary/latest) module

10. Use the [terraform-google-boundary-worker-hvd](https://registry.terraform.io/modules/hashicorp/boundary-enterprise-worker-hvd/google/latest) module to deploy ingress, egress, etc workers as needed.

## Docs

Below are links to docs pages related to deployment customizations and day 2 operations of your Boundary Controller instance.

- [Deployment Customizations](./docs/deployment-customizations.md)
- [Upgrading Boundary version](./docs/boundary-version-upgrades.md)
- [Rotating Boundary TLS/SSL certificates](./docs/boundary-cert-rotation.md)
- [Updating/modifying Boundary configuration settings](./docs/boundary-config-settings.md)
- [Authenticate to Boundary Cluster with Boundary CLI](./docs/boundary-cli-auth.md)

## Module support

This open source software is maintained by the HashiCorp Technical Field Organization, independently of our enterprise products. While our Support Engineering team provides dedicated support for our enterprise offerings, this open source software is not included.

- For help using this open source software, please engage your account team.
- To report bugs/issues with this open source software, please open them directly against this code repository using the GitHub issues feature.

Please note that there is no official Service Level Agreement (SLA) for support of this software as a HashiCorp customer. This software falls under the definition of Community Software/Versions in your Agreement. We appreciate your understanding and collaboration in improving our open source projects.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.39 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 5.39 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | n/a |
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.39 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | ~> 5.39 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_project_service_identity.cloud_sql_sa](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_project_service_identity) | resource |
| [google-beta_google_sql_database_instance.boundary](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_sql_database_instance) | resource |
| [google_compute_address.api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_address.cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_firewall.allow_9200](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_9201](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_iap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_ssh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.health_checks](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_forwarding_rule.api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_forwarding_rule.cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_global_address.postgres_private_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_health_check.boundary_auto_healing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_instance_template.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | resource |
| [google_compute_region_backend_service.api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service) | resource |
| [google_compute_region_backend_service.cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service) | resource |
| [google_compute_region_health_check.api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_health_check) | resource |
| [google_compute_region_health_check.cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_health_check) | resource |
| [google_compute_region_instance_group_manager.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager) | resource |
| [google_compute_region_target_tcp_proxy.cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_target_tcp_proxy) | resource |
| [google_dns_record_set.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_kms_crypto_key.bsr](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key.recovery](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key.root](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key.worker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_binding.cloud_sql_sa_postgres_cmek](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_binding) | resource |
| [google_kms_crypto_key_iam_binding.gcp_project_gcs_cmek](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_binding) | resource |
| [google_kms_crypto_key_iam_member.created_bsr_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.created_bsr_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.created_recovery_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.created_recovery_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.created_root_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.created_root_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.created_worker_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.created_worker_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.existing_bsr_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.existing_bsr_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.existing_recovery_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.existing_recovery_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.existing_root_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.existing_root_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.existing_worker_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.existing_worker_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_key_ring.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_secret_manager_secret_iam_member.boundary_cert](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.boundary_license](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.boundary_privkey](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.ca_bundle](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.bsr](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_key.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key) | resource |
| [google_service_account_key.bsr](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key) | resource |
| [google_sql_database.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | resource |
| [google_sql_user.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
| [google_storage_bucket.bsr](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.bsr_object_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.bsr_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_hmac_key.bsr](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_hmac_key) | resource |
| [random_id.gcs_key_ring_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.gcs_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.postgres_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [cloudinit_config.boundary_cloudinit](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_compute_image.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_compute_subnetwork.subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_compute_zones.up](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [google_dns_managed_zone.boundary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/dns_managed_zone) | data source |
| [google_kms_crypto_key.bsr](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_crypto_key.bsr_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_crypto_key.postgres](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_crypto_key.recovery](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_crypto_key.root](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_crypto_key.worker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_key_ring.bsr_gcs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_kms_key_ring.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_kms_key_ring.postgres](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_project.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_secret_manager_secret_version.boundary_database_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version) | data source |
| [google_storage_project_service_account.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_project_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_boundary_fqdn"></a> [boundary\_fqdn](#input\_boundary\_fqdn) | Fully qualified domain name of boundary instance. This name should resolve to the load balancer IP address and will be what clients use to access boundary. | `string` | n/a | yes |
| <a name="input_boundary_license_secret_id"></a> [boundary\_license\_secret\_id](#input\_boundary\_license\_secret\_id) | ID of Secrets Manager secret for Boundary license file. | `string` | n/a | yes |
| <a name="input_boundary_tls_cert_secret_id"></a> [boundary\_tls\_cert\_secret\_id](#input\_boundary\_tls\_cert\_secret\_id) | ID of Secrets Manager secret for Boundary TLS certificate in PEM format. Secret must be stored as a base64-encoded string. | `string` | n/a | yes |
| <a name="input_boundary_tls_privkey_secret_id"></a> [boundary\_tls\_privkey\_secret\_id](#input\_boundary\_tls\_privkey\_secret\_id) | ID of Secrets Manager secret for Boundary TLS private key in PEM format. Secret must be stored as a base64-encoded string. | `string` | n/a | yes |
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix used for uniquely naming resources. This should be unique across all deployments | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID of GCP Project to create resources in. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region of GCP Project to create resources in. | `string` | n/a | yes |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Existing VPC subnetwork for Boundary instance(s) and optionally Boundary frontend load balancer. | `string` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Existing VPC network to deploy Boundary resources into. | `string` | n/a | yes |
| <a name="input_additional_package_names"></a> [additional\_package\_names](#input\_additional\_package\_names) | List of additional repository package names to install | `set(string)` | `[]` | no |
| <a name="input_api_load_balancing_scheme"></a> [api\_load\_balancing\_scheme](#input\_api\_load\_balancing\_scheme) | Determines whether API load balancer is internal-facing or external-facing. | `string` | `"internal"` | no |
| <a name="input_boundary_database_name"></a> [boundary\_database\_name](#input\_boundary\_database\_name) | Name of boundary PostgreSQL database to create. | `string` | `"boundary"` | no |
| <a name="input_boundary_database_password_secret_version"></a> [boundary\_database\_password\_secret\_version](#input\_boundary\_database\_password\_secret\_version) | Name of PostgreSQL database password secret to retrieve from GCP Secret Manager. | `string` | `null` | no |
| <a name="input_boundary_database_user"></a> [boundary\_database\_user](#input\_boundary\_database\_user) | Name of boundary PostgreSQL database user to create. | `string` | `"boundary"` | no |
| <a name="input_boundary_tls_ca_bundle_secret_id"></a> [boundary\_tls\_ca\_bundle\_secret\_id](#input\_boundary\_tls\_ca\_bundle\_secret\_id) | ID of Secrets Manager secret for private/custom TLS Certificate Authority (CA) bundle in PEM format. Secret must be stored as a base64-encoded string. | `string` | `null` | no |
| <a name="input_boundary_tls_disable"></a> [boundary\_tls\_disable](#input\_boundary\_tls\_disable) | Boolean to disable TLS for boundary. | `bool` | `false` | no |
| <a name="input_boundary_version"></a> [boundary\_version](#input\_boundary\_version) | Version of Boundary to install. | `string` | `"0.17.1+ent"` | no |
| <a name="input_bsr_gcs_force_destroy"></a> [bsr\_gcs\_force\_destroy](#input\_bsr\_gcs\_force\_destroy) | Boolean indicating whether to allow force destroying the TFE GCS bucket. GCS bucket can be destroyed if it is not empty when `true`. | `bool` | `false` | no |
| <a name="input_bsr_gcs_kms_key_name"></a> [bsr\_gcs\_kms\_key\_name](#input\_bsr\_gcs\_kms\_key\_name) | Name of Cloud KMS customer managed encryption key (CMEK) to use for TFE GCS bucket encryption. | `string` | `null` | no |
| <a name="input_bsr_gcs_kms_key_ring_name"></a> [bsr\_gcs\_kms\_key\_ring\_name](#input\_bsr\_gcs\_kms\_key\_ring\_name) | Name of Cloud KMS key ring that contains KMS customer managed encryption key (CMEK) to use for TFE GCS bucket encryption. Geographic location (region) of the key ring must match the location of the TFE GCS bucket. | `string` | `null` | no |
| <a name="input_bsr_gcs_location"></a> [bsr\_gcs\_location](#input\_bsr\_gcs\_location) | Location of TFE GCS bucket to create. | `string` | `"US"` | no |
| <a name="input_bsr_gcs_storage_class"></a> [bsr\_gcs\_storage\_class](#input\_bsr\_gcs\_storage\_class) | Storage class of TFE GCS bucket. | `string` | `"MULTI_REGIONAL"` | no |
| <a name="input_bsr_gcs_uniform_bucket_level_access"></a> [bsr\_gcs\_uniform\_bucket\_level\_access](#input\_bsr\_gcs\_uniform\_bucket\_level\_access) | Boolean to enable uniform bucket level access on TFE GCS bucket. | `bool` | `true` | no |
| <a name="input_bsr_gcs_versioning_enabled"></a> [bsr\_gcs\_versioning\_enabled](#input\_bsr\_gcs\_versioning\_enabled) | Boolean to enable versioning on TFE GCS bucket. | `bool` | `true` | no |
| <a name="input_bsr_key_name"></a> [bsr\_key\_name](#input\_bsr\_key\_name) | Name of an existing KMS BSR key to use for Boundary | `string` | `null` | no |
| <a name="input_cidr_ingress_9200_allow"></a> [cidr\_ingress\_9200\_allow](#input\_cidr\_ingress\_9200\_allow) | CIDR ranges to allow 9200 traffic inbound to Boundary instance(s). This is for Boundary Clients using the Boundary API. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cidr_ingress_9201_allow"></a> [cidr\_ingress\_9201\_allow](#input\_cidr\_ingress\_9201\_allow) | CIDR ranges to allow 9201 traffic inbound to Boundary instance(s). This is for Boundary Ingress Workers accessing the Boundary Controller(s). | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cidr_ingress_ssh_allow"></a> [cidr\_ingress\_ssh\_allow](#input\_cidr\_ingress\_ssh\_allow) | CIDR ranges to allow SSH traffic inbound to Boundary instance(s) via IAP tunnel. | `list(string)` | <pre>[<br/>  "10.0.0.0/16"<br/>]</pre> | no |
| <a name="input_cloud_dns_managed_zone"></a> [cloud\_dns\_managed\_zone](#input\_cloud\_dns\_managed\_zone) | Zone name to create Boundary Cloud DNS record in if `create_cloud_dns_record` is set to `true`. | `string` | `null` | no |
| <a name="input_common_labels"></a> [common\_labels](#input\_common\_labels) | Common labels to apply to GCP resources. | `map(string)` | `{}` | no |
| <a name="input_create_bsr_key"></a> [create\_bsr\_key](#input\_create\_bsr\_key) | Boolean to create a KMS BSR key for Boundary. | `bool` | `false` | no |
| <a name="input_create_cloud_dns_record"></a> [create\_cloud\_dns\_record](#input\_create\_cloud\_dns\_record) | Boolean to create Google Cloud DNS record for `boundary_fqdn` resolving to load balancer IP. `cloud_dns_managed_zone` is required when `true`. | `bool` | `false` | no |
| <a name="input_create_key_ring"></a> [create\_key\_ring](#input\_create\_key\_ring) | Boolean to create a KMS key ring for Boundary. | `bool` | `true` | no |
| <a name="input_create_recovery_key"></a> [create\_recovery\_key](#input\_create\_recovery\_key) | Boolean to create a KMS recovery key for Boundary. | `bool` | `true` | no |
| <a name="input_create_root_key"></a> [create\_root\_key](#input\_create\_root\_key) | Boolean to create a KMS root key for Boundary. | `bool` | `true` | no |
| <a name="input_create_worker_key"></a> [create\_worker\_key](#input\_create\_worker\_key) | Boolean to create a KMS worker key for Boundary. | `bool` | `true` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Size in Gigabytes of root disk of Boundary instance(s). | `number` | `50` | no |
| <a name="input_enable_iap"></a> [enable\_iap](#input\_enable\_iap) | (Optional bool) Enable https://cloud.google.com/iap/docs/using-tcp-forwarding#console, defaults to `true`. | `bool` | `true` | no |
| <a name="input_enable_session_recording"></a> [enable\_session\_recording](#input\_enable\_session\_recording) | Boolean to enable session recording in Boundary. | `bool` | `false` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | VM image for Boundary instance(s). | `string` | `"ubuntu-2404-noble-amd64-v20240607"` | no |
| <a name="input_image_project"></a> [image\_project](#input\_image\_project) | ID of project in which the resource belongs. | `string` | `"ubuntu-os-cloud"` | no |
| <a name="input_initial_delay_sec"></a> [initial\_delay\_sec](#input\_initial\_delay\_sec) | The number of seconds that the managed instance group waits before it applies autohealing policies to new instances or recently recreated instances | `number` | `300` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Target size of Managed Instance Group for number of Boundary instances to run. Only specify a value greater than 1 if `enable_active_active` is set to `true`. | `number` | `1` | no |
| <a name="input_key_ring_location"></a> [key\_ring\_location](#input\_key\_ring\_location) | Location of KMS key ring. If not set, the region of the Boundary deployment will be used. | `string` | `null` | no |
| <a name="input_key_ring_name"></a> [key\_ring\_name](#input\_key\_ring\_name) | Name of an existing KMS Key Ring to use for Boundary | `string` | `null` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | (Optional string) Size of machine to create. Default `n2-standard-4` from https://cloud.google.com/compute/docs/machine-resource. | `string` | `"n2-standard-4"` | no |
| <a name="input_postgres_availability_type"></a> [postgres\_availability\_type](#input\_postgres\_availability\_type) | Availability type of Cloud SQL PostgreSQL instance. | `string` | `"REGIONAL"` | no |
| <a name="input_postgres_backup_start_time"></a> [postgres\_backup\_start\_time](#input\_postgres\_backup\_start\_time) | HH:MM time format indicating when daily automatic backups of Cloud SQL for PostgreSQL should run. Defaults to 12 AM (midnight) UTC. | `string` | `"00:00"` | no |
| <a name="input_postgres_disk_size"></a> [postgres\_disk\_size](#input\_postgres\_disk\_size) | Size in GB of PostgreSQL disk. | `number` | `50` | no |
| <a name="input_postgres_insights_config"></a> [postgres\_insights\_config](#input\_postgres\_insights\_config) | Configuration settings for Cloud SQL for PostgreSQL insights. | <pre>object({<br/>    query_insights_enabled  = bool<br/>    query_plans_per_minute  = number<br/>    query_string_length     = number<br/>    record_application_tags = bool<br/>    record_client_address   = bool<br/>  })</pre> | <pre>{<br/>  "query_insights_enabled": false,<br/>  "query_plans_per_minute": 5,<br/>  "query_string_length": 1024,<br/>  "record_application_tags": false,<br/>  "record_client_address": false<br/>}</pre> | no |
| <a name="input_postgres_key_name"></a> [postgres\_key\_name](#input\_postgres\_key\_name) | Name of KMS Key to use for Cloud SQL for PostgreSQL encryption. | `string` | `null` | no |
| <a name="input_postgres_key_ring_name"></a> [postgres\_key\_ring\_name](#input\_postgres\_key\_ring\_name) | Name of KMS Key Ring that contains KMS key to use for Cloud SQL for PostgreSQL database encryption. Geographic location of key ring must match location of database instance. | `string` | `null` | no |
| <a name="input_postgres_kms_cmek_name"></a> [postgres\_kms\_cmek\_name](#input\_postgres\_kms\_cmek\_name) | Name of Cloud KMS customer managed encryption key (CMEK) to use for Cloud SQL for PostgreSQL database instance. | `string` | `null` | no |
| <a name="input_postgres_kms_keyring_name"></a> [postgres\_kms\_keyring\_name](#input\_postgres\_kms\_keyring\_name) | Name of Cloud KMS Key Ring that contains KMS key to use for Cloud SQL for PostgreSQL. Geographic location (region) of key ring must match the location of the boundary Cloud SQL for PostgreSQL database instance. | `string` | `null` | no |
| <a name="input_postgres_machine_type"></a> [postgres\_machine\_type](#input\_postgres\_machine\_type) | Machine size of Cloud SQL PostgreSQL instance. | `string` | `"db-custom-4-16384"` | no |
| <a name="input_postgres_maintenance_window"></a> [postgres\_maintenance\_window](#input\_postgres\_maintenance\_window) | Optional maintenance window settings for the Cloud SQL for PostgreSQL instance. | <pre>object({<br/>    day          = number<br/>    hour         = number<br/>    update_track = string<br/>  })</pre> | <pre>{<br/>  "day": 7,<br/>  "hour": 0,<br/>  "update_track": "stable"<br/>}</pre> | no |
| <a name="input_postgres_ssl_mode"></a> [postgres\_ssl\_mode](#input\_postgres\_ssl\_mode) | Indicates whether to enforce TLS/SSL connections to the Cloud SQL for PostgreSQL instance. | `string` | `"ENCRYPTED_ONLY"` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | PostgreSQL version to use. | `string` | `"POSTGRES_16"` | no |
| <a name="input_recovery_key_name"></a> [recovery\_key\_name](#input\_recovery\_key\_name) | Name of an existing KMS recovery key to use for Boundary | `string` | `null` | no |
| <a name="input_root_key_name"></a> [root\_key\_name](#input\_root\_key\_name) | Name of an existing KMS root key to use for Boundary | `string` | `null` | no |
| <a name="input_vpc_project_id"></a> [vpc\_project\_id](#input\_vpc\_project\_id) | ID of GCP Project where the existing VPC resides if it is different than the default project. | `string` | `null` | no |
| <a name="input_worker_key_name"></a> [worker\_key\_name](#input\_worker\_key\_name) | Name of an existing KMS worker key to use for Boundary | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_lb_ip_address"></a> [api\_lb\_ip\_address](#output\_api\_lb\_ip\_address) | IP Address of the API Load Balancer. |
| <a name="output_boundary_fqdn"></a> [boundary\_fqdn](#output\_boundary\_fqdn) | `boundary_fqdn` input. |
| <a name="output_boundary_url"></a> [boundary\_url](#output\_boundary\_url) | URL of Boundary application based on `boundary_fqdn` input. |
| <a name="output_bsr_bucket_name"></a> [bsr\_bucket\_name](#output\_bsr\_bucket\_name) | Name of the Google Cloud Storage bucket. |
| <a name="output_bsr_cloud_storage_endpoint_url"></a> [bsr\_cloud\_storage\_endpoint\_url](#output\_bsr\_cloud\_storage\_endpoint\_url) | Google Cloud Storage endpoint URL. |
| <a name="output_bsr_hmac_key_access_id"></a> [bsr\_hmac\_key\_access\_id](#output\_bsr\_hmac\_key\_access\_id) | Value of the Google Cloud Storage HMAC key access id. |
| <a name="output_bsr_hmac_key_secret"></a> [bsr\_hmac\_key\_secret](#output\_bsr\_hmac\_key\_secret) | Value of the Google Cloud Storage HMAC key access id. |
| <a name="output_cluster_lb_ip_address"></a> [cluster\_lb\_ip\_address](#output\_cluster\_lb\_ip\_address) | IP Address of the API Load Balancer. |
| <a name="output_created_boundary_bsr_key_name"></a> [created\_boundary\_bsr\_key\_name](#output\_created\_boundary\_bsr\_key\_name) | Name of the created Boundary BSR KMS key. |
| <a name="output_created_boundary_keyring_name"></a> [created\_boundary\_keyring\_name](#output\_created\_boundary\_keyring\_name) | Name of the created Boundary KMS key ring. |
| <a name="output_created_boundary_recovery_key_name"></a> [created\_boundary\_recovery\_key\_name](#output\_created\_boundary\_recovery\_key\_name) | Name of the created Boundary recovery KMS key. |
| <a name="output_created_boundary_root_key_name"></a> [created\_boundary\_root\_key\_name](#output\_created\_boundary\_root\_key\_name) | Name of the created Boundary root KMS key. |
| <a name="output_created_boundary_worker_key_name"></a> [created\_boundary\_worker\_key\_name](#output\_created\_boundary\_worker\_key\_name) | Name of the created Boundary worker KMS key. |
| <a name="output_gcp_db_instance_ip"></a> [gcp\_db\_instance\_ip](#output\_gcp\_db\_instance\_ip) | Cloud SQL DB instance IP. |
| <a name="output_google_sql_database_instance_id"></a> [google\_sql\_database\_instance\_id](#output\_google\_sql\_database\_instance\_id) | ID of Cloud SQL DB instance. |
| <a name="output_provided_boundary_bsr_key_name"></a> [provided\_boundary\_bsr\_key\_name](#output\_provided\_boundary\_bsr\_key\_name) | Name of the provided Boundary BSR KMS key. |
| <a name="output_provided_boundary_keyring_name"></a> [provided\_boundary\_keyring\_name](#output\_provided\_boundary\_keyring\_name) | Name of the Provided Boundary KMS key ring. |
| <a name="output_provided_boundary_recovery_key_name"></a> [provided\_boundary\_recovery\_key\_name](#output\_provided\_boundary\_recovery\_key\_name) | Name of the Provided Boundary recovery KMS key. |
| <a name="output_provided_boundary_root_key_name"></a> [provided\_boundary\_root\_key\_name](#output\_provided\_boundary\_root\_key\_name) | Name of the Provided Boundary root KMS key. |
| <a name="output_provided_boundary_worker_key_name"></a> [provided\_boundary\_worker\_key\_name](#output\_provided\_boundary\_worker\_key\_name) | Name of the Provided Boundary worker KMS key. |
<!-- END_TF_DOCS -->

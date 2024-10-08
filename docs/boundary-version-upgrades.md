# Boundary Version Upgrades

See the [Boundary Releases](https://developer.hashicorp.com/boundary/docs/release-notes) page for full details on the releases. Since we have bootstrapped and automated the Boundary Controller deployment and the Boundary Controller application data is decoupled from the compute layer, the VM(s) are stateless, ephemeral, and are treated as immutable. Therefore, the process of upgrading your Boundary Controller instance to a new version involves updating your Terraform code managing your Boundary deployment to reflect the new version, applying the change via Terraform to update the Boundary Managed Instance Group Template, and then replacing running VM(s).

This module includes an input variable named `boundary_version` that dictates which version of Boundary is deployed. Here are the steps to follow:

## Procedure

 Here are the steps to follow:

1. Determine your desired version of Boundary from the [Boundary Release Notes](https://developer.hashicorp.com/boundary/docs/release-notes) page.

2. Out of precaution, generate a backup of your Google SQL PostgreSQL database.

3. During a maintenance window, update the value of `instance_count` to 0 to scale down to 0 running Boundary Controller VM(s)

4. From within the directory managing your Boundary deployment, run `terraform apply` to update the sizing configuration. This will trigger the Managed Instance group to destroy all Boundary Controller VM(s)

5. Update the value of the `boundary_version` input variable within your `terraform.tfvars` file, and update the `instance_count` to 1.

```hcl
    boundary_version = "0.17.1+ent"
```

6. from within the directory managing your Boundary deployment, run `terraform apply` to update the Boundary Managed Instance Group Template. This will trigger the Managed Instance group to create a Boundary Controller VM

7. This will trigger the Managed Instance Group to deploy new Boundary Controllers. This process will effectively re-install Boundary on the new instance(s).

8. Ensure that the Boundary controller VM has have been created with the changes. Monitor the cloud-init processes to ensure a successful re-install.

9. After the Boundary service has started, it may fail requiring a database migration. To perform the migration, on the controller run this command `boundary database migrate -config /etc/boundary.d/controller.hcl`. This will perform the database migration and the Boundary service can be started.

10.  Once checkout is complete, Update the value of `instance_count` input variable within your `terraform.tfvars` file to the previous value.

11. From within the directory managing your Boundary deployment, run `terraform apply` to scale out the deployment

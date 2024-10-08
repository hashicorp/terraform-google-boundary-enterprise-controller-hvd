# Deployment Customizations

On this page are various deployment customizations and their corresponding input variables that you may set to meet your requirements.

## Load Balancing

This module creates two Network Load Balancers for the Boundary Controller. One is used for the API and is a passthrough type that can be set for `internal` or `external` load balancing scheme. Boundary Clients will use this NLB for communicating the Boundary Controllers. **The default is `internal`**, but the following module boolean input variable may be set to configure the load balancer to be `external` (public) if desirable.

```hcl
api_load_balancing_scheme = "internal"
```

The second NLB is used for Cluster communication strictly for initial upstream for Boundary Ingress Workers. Due to how the Google Passthrough NLB functions, it can not be used for the cluster LB. A Regional Proxy Network Load Balancer is used instead. This load balancer is strictly internal only and requires a proxy subnet be deployed in the VPC that the Boundary Cluster is deployed into.

## DNS

This module supports creating a dns record in Cloud DNS for the Boundary FQDN to resolve to the Boundary API load balancer IP address. To do so, the following module input variables may be set:

```hcl
create_cloud_dns_record = true
cloud_dns_managed_zone  = "<example.com>"
```

## Custom Image

If you have a custom Google Image you would like to use, you can specify it via the following module input variables:

```hcl
image_project = "<project-containting-image>"
image_name    = "<custom-rhel-image-name>"
```

## Deployment Troubleshooting

In the `compute.tf` there is a commented out local file resource that will render the Boundary custom data script to a local file where this module is being run. This can be useful for reviewing the custom data script as it will be rendered on the deployed VM. This fill will contain sensitive vaults so do not commit this and delete this file when done troubleshooting.

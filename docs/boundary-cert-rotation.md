# Boundary Controller Certificate Rotation

One of the required prerequisites to deploying this module is storing base64-encoded strings of your Boundary Controller TLS/SSL certificate, private key files in PEM format, and CA bundle as plaintext secrets within Google Secret Manager for bootstrapping automation purposes. The Boundary Controller cloud-init (user_data) script is designed to retrieve the latest value of these secrets every time it runs. Therefore, the process for updating Boundary Controller's TLS/SSL certificates are to update the values of the corresponding secrets in Google Secret Manager, and then to replace the running VM instance(s) within the Managed Instance Group such that when the new VM(s) spawn and re-install Boundary Controller, they pick up the new certs. See the section below for detailed steps.

## Secrets

| Certificate file    | Module input variable        |
|---------------------|------------------------------|
| TLS/SSL certificate | `boundary_tls_cert_secret_id`    |
| TLS/SSL private key | `boundary_tls_privkey_secret_id` |
| CA bundle | `boundary_tls_ca_bundle_secret_id` |

## Procedure

Follow these steps to rotate the certificates for your Boundary Controller instance.

1. Obtain your new Boundary Controller TLS/SSL certificate file, private key file and CA bundle, in PEM format.

2. Update the values of the existing secrets in Google Secret Manager (`boundary_tls_cert_secret_id`, `boundary_tls_privkey_secret_id` and `boundary_tls_ca_bundle_secret_id`, respectively). If you need assistance base64-encoding the files into strings prior to updating the secrets, see the examples below:

    On Linux (bash):

    ```sh
    cat new_boundary_cert.pem | base64 -w 0
    cat new_boundary_privkey.pem | base64 -w 0
    cat new_boundary_ca.pem | base64 -w 0
    ```

   On macOS (terminal):

   ```sh
   cat new_boundary_cert.pem | base64
   cat new_boundary_privkey.pem | base64
   cat new_boundary_ca.pem | base64
   ```

   On Windows (PowerShell):

   ```powershell
   function ConvertTo-Base64 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputString
    )
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $EncodedString = [Convert]::ToBase64String($Bytes)
    return $EncodedString
   }

   Get-Content new_boundary_cert.pem -Raw | ConvertTo-Base64 -Width 0
   Get-Content new_boundary_privkey.pem -Raw | ConvertTo-Base64 -Width 0
   Get-Content new_boundary_ca.pem -Raw | ConvertTo-Base64 -Width 0
   ```

    > **Note:**
    > When you update the value of an Google Secret Manager secret, the secret IDs should not change, so **no action should be needed** in terms of updating any input variable values. If the secret IDs _were_ to change due to other circumstances, you would need to update the following input variable values with the new IDs, and subsequently run `terraform apply` to update the Boundary Controller Instance Template:
   >
    >```hcl
    >boundary_tls_cert_secret_arn    = "<new-boundary-tls-cert-secret-id>"
    >boundary_tls_privkey_secret_arn = "<new-boundary-tls-privkey-secret-id>"
    >boundary_tls_privkey_secret_arn = "<new-boundary-tls-ca-secret-id>"
    >```

3. During a maintenance window, delete the running Boundary Controller VM(s) and scale the managed instance group back to the desired number of VM(s). This will trigger the Managed Instance Group to spawn new VM(s) from the latest version of the Boundary Controller Instance Template. This process will effectively re-install Boundary Controller on the new VM(s), including the retrieval of the latest certificates from the Google Secret Manager.
 
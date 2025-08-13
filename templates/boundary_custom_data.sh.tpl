#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/boundary-cloud-init.log"
SYSTEMD_DIR="${systemd_dir}"
BOUNDARY_DIR_CONFIG="${boundary_dir_config}"
BOUNDARY_CONFIG_PATH="$BOUNDARY_DIR_CONFIG/controller.hcl"
BOUNDARY_DIR_TLS="${boundary_dir_config}/tls"
BOUNDARY_DIR_DATA="${boundary_dir_home}/data"
BOUNDARY_DIR_LICENSE="${boundary_dir_home}/license"
BOUNDARY_LICENSE_PATH="$BOUNDARY_DIR_LICENSE/license.hclic"
BOUNDARY_DIR_LOGS="/var/log/boundary"
BOUNDARY_DIR_BIN="${boundary_dir_bin}"
BOUNDARY_USER="boundary"
BOUNDARY_GROUP="boundary"
PRODUCT="boundary"
BOUNDARY_VERSION="${boundary_version}"
VERSION=$BOUNDARY_VERSION
REQUIRED_PACKAGES="jq unzip"
ADDITIONAL_PACKAGES="${additional_package_names}"

function log {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local log_entry="$timestamp [$level] - $message"
  echo "$log_entry" | tee -a "$LOGFILE"
}

function detect_os_distro {
  local OS_DISTRO_NAME=$(grep "^NAME=" /etc/os-release | cut -d"\"" -f2)
  local OS_DISTRO_DETECTED

  case "$OS_DISTRO_NAME" in
  "Ubuntu"*)
    OS_DISTRO_DETECTED="ubuntu"
    ;;
  "CentOS Linux"*)
    OS_DISTRO_DETECTED="centos"
    ;;
  "Red Hat"*)
    OS_DISTRO_DETECTED="rhel"
    ;;
  *)
    log "ERROR" "'$OS_DISTRO_NAME' is not a supported Linux OS distro for Boundary."
    exit_script 1
    ;;
  esac
  echo "$OS_DISTRO_DETECTED"
}

function detect_architecture {
  local ARCHITECTURE=""
  local OS_ARCH_DETECTED=$(uname -m)

  case "$OS_ARCH_DETECTED" in
    "x86_64"*)
      ARCHITECTURE="linux_amd64"
      ;;
    "aarch64"*)
      ARCHITECTURE="linux_arm64"
      ;;
		"arm"*)
      ARCHITECTURE="linux_arm"
			;;
    *)
      log "ERROR" "Unsupported architecture detected: '$OS_ARCH_DETECTED'. "
		  exit_script 1
  esac

  echo "$ARCHITECTURE"

}

function install_prereqs {
  local OS_DISTRO="$1"
  log "[INFO]" "Installing required packages..."

  if [[ "$OS_DISTRO" == "ubuntu" ]]; then
    apt-get update -y
    apt-get install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
  elif [[ "$OS_DISTRO" == "rhel" ]]; then
    yum install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
  else
    log "ERROR" "Unsupported OS distro '$OS_DISTRO'. Exiting."
    exit_script 1
  fi
}

install_gcloud_sdk() {
  if [[ -n "$(command -v gcloud)" ]]; then
    echo "INFO: Detected gcloud SDK is already installed."
  else
    echo "INFO: Attempting to install gcloud SDK."
    if [[ -n "$(command -v python)" ]]; then
      curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-309.0.0-linux-x86_64.tar.gz -o google-cloud-sdk.tar.gz
      tar xzf google-cloud-sdk.tar.gz
      ./google-cloud-sdk/install.sh --quiet
    else
      echo "ERROR: gcloud SDK requires Python but it was not detected on system."
      exit_script 5
    fi
  fi
}

function scrape_vm_info {
  log "[INFO]" "Scraping VM metadata for private IP address..."
  VM_PRIVATE_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
  log "[INFO]" "Detected VM private IP address is '$VM_PRIVATE_IP'."
}

# user_create creates a dedicated linux user for Boundary
function user_group_create {
  log "[INFO]" "Creating Boundary user and group..."
  # Create the dedicated as a system group
  sudo groupadd --system $BOUNDARY_GROUP
  # Create a dedicated user as a system user
  sudo useradd --system --no-create-home -d $BOUNDARY_DIR_CONFIG -g $BOUNDARY_GROUP $BOUNDARY_USER
  log "[INFO]" "Done creating Boundary user and group"
}

function directory_create {
  log "[INFO]" "Creating necessary directories..."

  # Define all directories needed as an array
  directories=($BOUNDARY_DIR_CONFIG $BOUNDARY_DIR_DATA $BOUNDARY_DIR_TLS $BOUNDARY_DIR_LICENSE $BOUNDARY_DIR_LOGS)

  # Loop through each item in the array; create the directory and configure permissions
  for directory in "$${directories[@]}"; do
    log "[INFO]" "Creating $directory"
    mkdir -p $directory
    sudo chown $BOUNDARY_USER:$BOUNDARY_GROUP $directory
    sudo chmod 750 $directory
  done

  log "[INFO]" "Done creating necessary directories."
}

# # install_boundary_binary downloads the Boundary binary and puts it in dedicated bin directory
# function install_boundary_binary {
#   log "[INFO]" "Installing Boundary binary to: $BOUNDARY_DIR_BIN..."

#   # Download the Boundary binary to the dedicated bin directory
#   sudo curl -so $BOUNDARY_DIR_BIN/boundary.zip $BOUNDARY_INSTALL_URL

#   # Unzip the Boundary binary
#   sudo unzip $BOUNDARY_DIR_BIN/boundary.zip boundary -d $BOUNDARY_DIR_BIN
#   sudo unzip $BOUNDARY_DIR_BIN/boundary.zip -x boundary -d $BOUNDARY_DIR_LICENSE
#   sudo rm $BOUNDARY_DIR_BIN/boundary.zip

#   log "[INFO]" "Done installing Boundary binary."
# }

function retrieve_license_from_secret_manager {
  local SECRET_ID="$1"
  log "[INFO]" "Retrieving Boundary license file..."
  log "[INFO]" "Retrieving value of secret '$SECRET_ID' from Secret Manager."
  BOUNDARY_LICENSE=$(gcloud secrets versions access latest --secret="$SECRET_ID")
  echo "$BOUNDARY_LICENSE" >$BOUNDARY_LICENSE_PATH
}

function retrieve_certs_from_secret_manager {
  local SECRET_ID="$1"
  local DESTINATION_PATH="$2"
  local CERT_DATA
  log "[INFO]" "Retrieving Boundary TLS certificates"
  log "[INFO]" "Retrieving value of secret '$SECRET_ID' from Secret Manager."
  CERT_DATA=$(gcloud secrets versions access latest --secret="$SECRET_ID")
  echo "$CERT_DATA" | base64 -d >$DESTINATION_PATH
  chown $BOUNDARY_USER:$BOUNDARY_GROUP $DESTINATION_PATH
  chmod 640 $DESTINATION_PATH
}

function generate_boundary_config {
  log "[INFO]" "Generating $BOUNDARY_CONFIG_PATH file."

  declare -l host
  host=$(hostname -s)

  cat >$BOUNDARY_CONFIG_PATH <<EOF
disable_mlock = true

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname          = true
}

controller {
  name        = "$host"
  description = ""

  database {
    url = "postgresql://${boundary_database_user}:${boundary_database_password}@${boundary_database_host}/${boundary_database_name}?sslmode=require"
  }

  license = "file:///$BOUNDARY_LICENSE_PATH"
}

listener "tcp" {
  address              = "0.0.0.0:9200"
  purpose              = "api"
  tls_disable          = ${boundary_tls_disable}
  tls_cert_file        = "$BOUNDARY_DIR_TLS/cert.pem"
  tls_key_file         = "$BOUNDARY_DIR_TLS/key.pem"
%{ if boundary_tls_ca_bundle_secret_id != "NONE" ~}
  tls_client_ca_file   = "$BOUNDARY_DIR_TLS/bundle.pem"
%{ endif }
  cors_enabled         = true
  cors_allowed_origins = ["*"]
}

listener "tcp" {
  address = "$VM_PRIVATE_IP:9201"
  purpose = "cluster"
}

listener "tcp" {
  address            = "0.0.0.0:9203"
  purpose            = "ops"
  tls_disable        = ${boundary_tls_disable}
  tls_cert_file      = "$BOUNDARY_DIR_TLS/cert.pem"
  tls_key_file       = "$BOUNDARY_DIR_TLS/key.pem"
%{ if boundary_tls_ca_bundle_secret_id != "NONE" ~}
  tls_client_ca_file   = "$BOUNDARY_DIR_TLS/bundle.pem"
%{ endif }
}

kms "gcpckms" {
  purpose    = "root"
  project    = "${key_ring_project}"
  region     = "${key_ring_region}"
  key_ring   = "${root_key_ring_name}"
  crypto_key = "${root_crypto_name}"
}

kms "gcpckms" {
  purpose    = "recovery"
  project    = "${key_ring_project}"
  region     = "${key_ring_region}"
  key_ring   = "${recovery_key_ring_name}"
  crypto_key = "${recovery_crypto_name}"
}

kms "gcpckms" {
  purpose    = "worker-auth"
  project    = "${key_ring_project}"
  region     = "${key_ring_region}"
  key_ring   = "${worker_key_ring_name}"
  crypto_key = "${worker_crypto_name}"
}

%{ if bsr_crypto_name != "" ~}
kms "gcpckms" {
  purpose    = "bsr"
  project    = "${key_ring_project}"
  region     = "${key_ring_region}"
  key_ring   = "${bsr_key_ring_name}"
  crypto_key = "${bsr_crypto_name}"
}
%{ endif ~}
EOF
  chown $BOUNDARY_USER:$BOUNDARY_GROUP $BOUNDARY_CONFIG_PATH
  chmod 640 $BOUNDARY_CONFIG_PATH
}

# template_boundary_config templates out the Boundary system file
function template_boundary_systemd {
  log "[INFO]" "Templating out the Boundary service..."

  sudo bash -c "cat > $SYSTEMD_DIR/boundary.service" <<EOF
[Unit]
Description="HashiCorp Boundary"
Documentation=https://www.boundaryproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=$BOUNDARY_CONFIG_PATH
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=$BOUNDARY_USER
Group=$BOUNDARY_GROUP
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=$BOUNDARY_DIR_BIN/boundary server -config=$BOUNDARY_CONFIG_PATH
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

  # Ensure proper permissions on service file
  sudo chmod 644 $SYSTEMD_DIR/boundary.service
  log "[INFO]" "Done templating out the Boundary service."
}

function init_boundary_db {
  log "[INFO]" "Initializing Boundary database..."

  # Make sure to initialize the DB before starting the service. This will result in
  # a database already initialized warning if another controller has done this
  # already, making it a lazy, best effort initialization
  /usr/bin/boundary database init -skip-auth-method-creation -skip-host-resources-creation -skip-scopes-creation -skip-target-creation -config $BOUNDARY_CONFIG_PATH || true
  log "[INFO]" "Done initializing Boundary database."
}

# start_enable_boundary starts and enables the boundary service
function start_enable_boundary {
  log "[INFO]" "Starting and enabling the boundary service..."

  sudo systemctl enable boundary
  sudo systemctl start boundary

  log "[INFO]" "Done starting and enabling the boundary service."
}

function exit_script {
  if [[ "$1" == 0 ]]; then
    log "[INFO]" "boundary_custom_data script finished successfully!"
  else
    log "ERROR" "boundary_custom_data script finished with error code $1."
  fi
  exit "$1"
}

function main {
  log "[INFO]" "Beginning Boundary user_data script."

  OS_DISTRO=$(detect_os_distro)
  log "[INFO]" "Detected Linux OS distro is '$OS_DISTRO'."

	OS_ARCH=$(detect_architecture)
	log "INFO" "Detected system architecture is '$OS_ARCH'."

  scrape_vm_info
  install_prereqs "$OS_DISTRO"
  install_gcloud_sdk "$OS_DISTRO"
  user_group_create
  directory_create
  install_boundary_binary
  retrieve_license_from_secret_manager "${boundary_license_secret_id}"
  retrieve_certs_from_secret_manager "${boundary_tls_cert_secret_id}" "$BOUNDARY_DIR_TLS/cert.pem"
  retrieve_certs_from_secret_manager "${boundary_tls_privkey_secret_id}" "$BOUNDARY_DIR_TLS/key.pem"
%{ if boundary_tls_ca_bundle_secret_id != "NONE" }
  retrieve_certs_from_secret_manager "${boundary_tls_ca_bundle_secret_id}" "$BOUNDARY_DIR_TLS/bundle.pem"
%{ endif }
  generate_boundary_config
  template_boundary_systemd
  init_boundary_db
  start_enable_boundary
  log "[INFO]" "Sleeping for a minute while Boundary initializes."
  sleep 60

  log "[INFO]" "Polling Boundary health check endpoint until the app becomes ready..."
  while ! curl -ksfS --connect-timeout 5 https://$VM_PRIVATE_IP:9203/health; do
    sleep 5
  done

  exit_script 0
}

main

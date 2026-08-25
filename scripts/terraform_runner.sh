#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/terraform-runner.log | logger -t terraform-runner -s 2>/dev/console) 2>&1

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y awscli unzip curl gnupg lsb-release

curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list

apt-get update -y
apt-get install -y terraform

rm -rf /opt/infrastructure
mkdir -p /opt/infrastructure
aws s3 cp "s3://${bucket}/${key}" /tmp/infrastructure.zip --region "${region}"
unzip -q /tmp/infrastructure.zip -d /opt/infrastructure
rm -f /tmp/infrastructure.zip

cd /opt/infrastructure
terraform init -input=false
terraform apply -auto-approve -input=false#!/bin/bash

apt-get update -y
apt-get install -y git unzip curl

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
> /etc/apt/sources.list.d/hashicorp.list

apt-get update -y
apt-get install -y terraform
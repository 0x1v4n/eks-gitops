#!/bin/bash
set -euo pipefail

###############################################################################
# 1) Basic packages + AWS CLI v2 + kubectl
###############################################################################
yum install -y jq curl unzip >/var/log/user-data.log

# --- AWS CLI v2 (official) ---
curl -sSLo /tmp/awscliv2.zip \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

# --- kubectl 1.29 ---
curl -L -o /usr/local/bin/kubectl \
  https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl

###############################################################################
# 2) (Optional) kubeconfig update for CLI access (no port-forwarding)
###############################################################################
# NOTE: This is useful for enabling direct CLI access to EKS from the bastion.
export CLUSTER_NAME="${cluster_name}"
export AWS_REGION="${region}"

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"

# Patch for compatibility with newer CLI versions
sed -i 's/client.authentication.k8s.io\/v1alpha1/client.authentication.k8s.io\/v1beta1/' /home/ec2-user/.kube/config

###############################################################################
# 3) Enable SSM Agent on the bastion
###############################################################################
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

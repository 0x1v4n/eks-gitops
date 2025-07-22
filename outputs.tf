output "region" {
  description = "AWS region"
  value       = var.region
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = <<-EOT
    export KUBECONFIG="/tmp/${module.eks.cluster_name}"
    aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --profile ${var.profile}
  EOT
}

output "access_argocd" {
  description = "Terminal setup for accessing Argo CD via NodePort through SSM tunnel"
  value       = <<-EOT
    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $(kubectl get secret -n argocd argocd-initial-admin-secret --template='{{index .data.password | base64decode}}')"

    export REGION="${local.region}"
    export PROFILE="${var.profile}"
    export INSTANCE_ID="${aws_instance.bastion.id}"
    export NODE_IP=$(kubectl get pod -n argocd \
      -l app.kubernetes.io/name=argocd-server \
      -o jsonpath='{.items[0].status.hostIP}')

    To open the SSM port-forwarding tunnel to ArgoCD:
    aws ssm start-session --target "$INSTANCE_ID" \
      --document-name AWS-StartPortForwardingSessionToRemoteHost \
      --parameters "{\"host\":[\"$NODE_IP\"],\"portNumber\":[\"32080\"],\"localPortNumber\":[\"8080\"]}" \
      --region "$REGION" \
      --profile "$PROFILE"

    Then access ArgoCD at: http://localhost:8080
  EOT
}

output "bastion_instance_id" {
  description = "Instance ID for use with aws ssm start-session"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion (only if public IP is assigned)"
  value       = aws_instance.bastion.public_ip
}

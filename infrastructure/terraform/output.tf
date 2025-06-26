#ami-001b3fc6186c63470

#AMI copy name entry field
#ubuntu-eks-pro/k8s_1.31/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20250502

#AMI copy description
#[Copied ami-001b3fc6186c63470 from us-east-1] ubuntu-eks-pro/k8s_1.31/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20250502[Copied ami-001b3fc6186c63470 from us-east-1] ubuntu-eks-pro/k8s_1.31/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20250502


output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "fastapi_endpoint" {
  description = "URL to access the FastAPI application"
  value       = "http://${aws_instance.app_server.public_ip}:8000"
}
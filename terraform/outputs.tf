# =============================================================================
# outputs.tf — Values printed after `terraform apply` completes
#
# These mirror the summary block the shell scripts printed at the end.
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.f5_ce.id
}

output "public_ip" {
  description = "Elastic (public) IP address assigned to the instance"
  value       = aws_eip.f5_ce.public_ip
}

output "private_ip" {
  description = "Private IP address of the EC2 instance (within the VPC)"
  value       = aws_instance.f5_ce.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "slo_subnet_id" {
  description = "Public (SLO) subnet ID"
  value       = aws_subnet.slo.id
}

output "sli_subnet_id" {
  description = "Private (SLI) subnet ID"
  value       = aws_subnet.sli.id
}

output "security_group_id" {
  description = "F5 CE security group ID"
  value       = aws_security_group.f5_ce.id
}

output "ssh_key_file" {
  description = "Path to the generated SSH private key (.pem file)"
  value       = local_sensitive_file.ssh_key_pem.filename
}

output "ssh_command" {
  description = "Ready-to-run SSH command to connect to the instance"
  value       = "ssh -i ${local_sensitive_file.ssh_key_pem.filename} ec2-user@${aws_eip.f5_ce.public_ip}"
}
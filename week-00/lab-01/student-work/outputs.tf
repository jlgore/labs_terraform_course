# Output the instance ID
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.lab_instance.id
}

# Output the public IP
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.lab_instance.public_ip
}

# Output the public DNS
output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.lab_instance.public_dns
}

# Output SSH connection command
output "ssh_connection_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ~/.ssh/terraform-lab-01 ec2-user@${aws_instance.lab_instance.public_ip}"
}

# Output the AMI ID used
output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

# Output the key pair name
output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.lab_key.key_name
}

# Output security group ID
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.lab_sg.id
}

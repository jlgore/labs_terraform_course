output "instance_id" {
  description = "ID of the WordPress EC2 instance"
  value       = aws_instance.wordpress.id
}

output "public_ip" {
  description = "Public IP address of the WordPress server"
  value       = aws_instance.wordpress.public_ip
}

output "public_dns" {
  description = "Public DNS name of the WordPress server"
  value       = aws_instance.wordpress.public_dns
}

output "wordpress_url" {
  description = "URL to access WordPress"
  value       = "http://${aws_instance.wordpress.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/wordpress-lab ec2-user@${aws_instance.wordpress.public_ip}"
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.wordpress.id
}

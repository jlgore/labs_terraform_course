variable "student_name" {
  description = "Your GitHub username or student ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "my_ip" {
  description = "Your public IP address for SSH access (CIDR notation, e.g., 203.0.113.42/32)"
  type        = string
}

variable "student_name" {
  description = "Your GitHub username or student ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro" # Free tier eligible
}

variable "my_ip" {
  description = "Your public IP address for SSH access (CIDR notation)"
  type        = string
}

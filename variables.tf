variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "access_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "access_key of AWS IAM User"
}

variable "secret_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "secret_key of AWS IAM User"
}

variable "subnet_cidr" {
  type        = list(any)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "CIDR for the subnets"
}

variable "availability_zone" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "AZ for the subnets"
}

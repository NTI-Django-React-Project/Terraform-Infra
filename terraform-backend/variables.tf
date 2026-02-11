variable "region" {
  default = "eu-north-1"
}

variable "project_name" {
  description = "Project name (appears in tags and resource names)"
  type        = string
  default     = "gig-route-backend"
}

variable "environment" {
  description = "Environment label (appears in tags)"
  type        = string
  default     = "gig-route-production-backend"
}

variable "bucket_name" {
  default = "gig-route-terraform-bucket"
}

variable "dynamodb_table_name" {
  default = "gig-route-terraform-state-locks"
}

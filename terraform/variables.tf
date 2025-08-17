
variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "us-central1"
}

variable "db_password" {
  description = "The password for the database."
  type        = string
  sensitive   = true
}

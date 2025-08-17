variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "us-central1"
}

variable "tf_state_bucket" {
  description = "The name of the GCS bucket to store the Terraform state file."
  type        = string
}
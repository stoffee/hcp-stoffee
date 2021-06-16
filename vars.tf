variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "prefix" {
  type        = string
  description = "Prefix used in resource names"
  default     = "hashicorp"
}

variable "region" {
  type        = string
  description = "The Azure region to deploy resources to"
  default = "us-west-2"
}
variable "project_name" {
  description = "The name of the project, used for naming resources."
  type        = string
  default     = "over-engineered-portfolio"
}

variable "aws_region" {
  description = "The AWS region for state storage."
  type        = string
  default     = "us-west-2"
}
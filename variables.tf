variable "namespace" {
  default = "s3backend"
  type    = string
}

variable "principal_arns" {
  description = "arns allowed to assume IAM role"
  default     = null
  type        = list(string)
}

variable "force_destroy_state" {
  default = true
  type    = bool
}

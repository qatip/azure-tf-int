variable "stages" {
  description = "Environment stages"
  type        = list(string)
  default     = ["dev", "test", "prod"]
}

variable "projects" {
  description = "Project names"
  type        = list(string)
  default     = ["finance", "sales", "infra", "backup"]
}


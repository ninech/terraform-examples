variable "name" {
  default     = "demo-01"
  description = "name of the cluster and associated resources"
}

variable "namespace" {
  default     = "<your cockpit account name>"
  description = "namespace to create the resources in (matches cockpit account name)"
}

variable "location" {
  default     = "nine-es34"
  description = "location of the cluster (nine-cz42, nine-cz41, nine-es34)"
}

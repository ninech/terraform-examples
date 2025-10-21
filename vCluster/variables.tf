variable "name" {
  default     = "tf-sample"
  description = "name of the cluster and associated resources"
}

variable "namespace" {
  default     = "<your cockpit account name>"
  description = "namespace to create the resources in (matches cockpit account name)"
}

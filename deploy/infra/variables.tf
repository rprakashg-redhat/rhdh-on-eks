variable "region" {
  description = "EKS Cluster AWS region"
  type        = string
  default     = "us-west-2"
}

variable "name" {
  description = "EKS Cluster name"
  type = string
  default = "admincluster"
}

variable "k8sversion" {
  description = "Kubernetes version"
  type = string
  default = "1.31"
}

variable "dbname" {
  description = "Postgresql Database name"
  type      = string
  default = "rhdhdb"
}

variable "dbuser" {
  description = "user name to connect to the datbase"
  type = string
  default = "rhdh"
}
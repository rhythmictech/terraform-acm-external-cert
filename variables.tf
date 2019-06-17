locals {
  common_tags = {
    namespace = var.namespace
    env       = var.env
    owner     = var.owner
  }

}

variable "namespace" {
  type          = string
  default       = ""
}

variable "owner" {
  type          = string
  default       = ""
}

variable "env" {
  type          = string
  default       = ""
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "private_key_secret" {
  type          = string
  description   = "ARN for the Secrets Manager secret that holds the private key"
}

variable "certificate_body" {
  type          = string
  description   = "SSL certificate body"
}

variable "certificate_cabundle_body" {
  type          = string
  description   = "SSL certificate chain (omit if none)"
  default       = ""
  
}

variable "cert_domain" {
  description = "domain name of certificate"
  type = string
}


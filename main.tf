terraform {
  required_version = ">= 0.12"
}

locals {
  tag_keys = keys(merge(local.common_tags, var.additional_tags))
  tag_values = values(merge(local.common_tags, var.additional_tags))
}

data "null_data_source" "tag_list" {
  count = length(local.tag_keys)
  
  inputs = {
    Key                 = local.tag_keys[count.index]
    Value               = local.tag_values[count.index]
  }
}

resource "null_resource" "acm_external_cert_with_chain" {
  count = var.certificate_cabundle_body == "" ? 0 : 1

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    
    command = <<EOF
private_key="$(aws --output json secretsmanager get-secret-value --secret-id ${var.private_key_secret} | jq -j '.SecretString')"
aws --output json acm import-certificate \
  --private-key "$${private_key}" \
  --certificate "${var.certificate_body}" \
  --certificate-chain "${var.certificate_cabundle_body}"
EOF
  }
}

resource "null_resource" "acm_external_cert_no_chain" {
  count = var.certificate_cabundle_body == "" ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    
    command = <<EOF
private_key="$(aws --output json secretsmanager get-secret-value --secret-id ${var.private_key_secret} | jq -j '.SecretString')"
aws --output json acm import-certificate \
  --private-key "$${private_key}" \
  --certificate "${var.certificate_body}"
EOF
  }
}

data "aws_acm_certificate" "this" {
  domain      = var.cert_domain
  types       = ["IMPORTED"]
  most_recent = true

  depends_on = [
    "null_resource.acm_external_cert_with_chain",
    "null_resource.acm_external_cert_no_chain",
  ]
}

resource "null_resource" "acm_external_cert_tags" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    
    command = <<EOF
aws acm add-tags-to-certificate \
  --certificate-arn "${data.aws_acm_certificate.this.arn}" \
  --tags '${jsonencode(data.null_data_source.tag_list.*.outputs)}'
EOF
  }
}

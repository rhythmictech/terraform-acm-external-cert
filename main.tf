terraform {
  required_version = ">= 0.12"
}

data "aws_secretsmanager_secret" "private_key_secret" {
  arn = var.private_key_secret 
}

module "acm_cert_tags" {
  source = "rhythmictech/asg-tag-transform/aws"
  version = "~> 1.0.0"
  tag_map = merge(local.common_tags, var.additional_tags)
}

resource "null_resource" "acm_external_cert" {
  depends_on = [
    "data.aws_secretsmanager_secret.private_key_secret",
  ]

  provisioner "local-exec" {
    interpreter = ["bash"]
    
    command = <<EOF
aws --output json acm import-certificate \
  --private-key "$(aws --output json secretsmanager get-secret-value --secret-id ${secret_id} | jq -r '.SecretString')" \
  --certificate "${certificate_body}" \
  --certificate_chain "${certificate_chain}"
EOF
  }
}

data "aws_acm_certificate" "this" {
  domain      = var.cert_domain
  types       = ["IMPORTED"]
  most_recent = true

  depends_on = [
    "null_resource.acm_external_cert"
  ]
}

resource "null_resource" "acm_external_cert_tags" {
  provisioner "local-exec" {
    interpreter = ["bash"]
    
    command = <<EOF
aws acm add-tags-to-certificate \
  --certificate-arn ${data.aws_acm_certificate.this.arn} \
  --tags "${jsonencode(module.acm_cert_tags.tag_list)}"
EOF
  }
}

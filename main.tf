terraform {
  required_version = ">= 0.12"
}

module "acm_cert_tags" {
  source = "rhythmictech/asg-tag-transform/aws"
  version = "~> 1.0.0"
  tag_map = merge(local.common_tags, var.additional_tags)
}

resource "null_resource" "acm_external_cert" {

  provisioner "local-exec" {
    interpreter = ["bash"]
    
    command = <<EOF
aws --output json acm import-certificate \
  --private-key "$(aws --output json secretsmanager get-secret-value --secret-id ${var.private_key_secret} | jq -r '.SecretString')" \
  --certificate "${var.certificate_body}" \
  --certificate_chain "${var.certificate_cabundle_body}"
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

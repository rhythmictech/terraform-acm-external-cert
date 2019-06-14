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
    "data.aws_secretsmanager_secret",
  ]

  provisioner "local-exec" {
    interpreter = ["bash"]
    command = templatefile(
      "${path.module}/import-cert.sh.tpl",
      {
        secret_id         = data.aws_secretsmanager_secret.private_key_secret.id
        certificate_body  = var.certificate_body
        certificate_chain = var.certificate_cabundle_body == "" ? null : var.certificate_cabundle_body
        tag_list          = module.acm_cert_tags.tag_list
      }
    )
  }
}

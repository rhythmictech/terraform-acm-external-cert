
data "aws_secretsmanager_secret" "private_key_secret" {
  arn = var.private_key_secret 
}

data "aws_secretsmanager_secret_version" "private_key_secret_version" { 
  secret_id = data.aws_secretsmanager_secret.private_key_secret.id
}


resource "aws_acm_certificate" "external_cert" {
  #count             = var.certificate_cabundle_body == "" ? true : false
  private_key       = data.aws_secretsmanager_secret_version.private_key_secret_version.secret_string
  certificate_body  = var.certificate_body
  certificate_chain = var.certificate_cabundle_body == "" ? null : var.certificate_cabundle_body
  tags              = merge(local.common_tags, var.additional_tags)
}

# resource "aws_acm_certificate" "external_cert" {
#   count             = var.certificate_cabundle_body == "" ? false : true
#   private_key       = data.aws_secretsmanager_secret_version.private_key_secret_version.secret_string
#   certificate_body  = var.certificate_body
#   tags              = merge(local.common_tags, var.additional_tags)
# }

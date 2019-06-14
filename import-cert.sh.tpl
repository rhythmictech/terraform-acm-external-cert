CERT_ARN=$(aws --output json acm import-certificate \
  --private-key "$(aws --output json secretsmanager get-secret-value --secret-id ${secret_id} | jq -r '.SecretString')" \
  --certificate "${certificate_body}" \
  --certificate_chain "${certificate_chain}" \
  | jq -r '.CertificateArn')

aws acm add-tags-to-certificate --certificate-arn $${CERT_ARN} --tags "${tag_list}"

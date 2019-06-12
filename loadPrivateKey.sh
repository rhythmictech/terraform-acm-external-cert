#!/usr/bin/env bash

SECRET_NAME=$1
SECRET_FILE=$2

aws secretsmanager create-secret --name $SECRET_NAME \
	--description "SSL Cert (private key)" \
    --secret-string file://$2

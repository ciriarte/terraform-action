#! /usr/bin/env bash

TEMPLATE_PATH=$1
ENV_NAME=$2
TERRAFORM_SOURCE=$3

echo $TEMPLATE_PATH
echo $ENV_NAME
echo $TERRAFORM_SOURCE

/opt/resource/out "$TEMPLATE_PATH" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE"
  }
}
JSON
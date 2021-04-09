#! /usr/bin/env bash

TEMPLATE_PATH=$1
ENV_NAME=$2
TERRAFORM_SOURCE=$3
BACKEND_TYPE=$4
BACKEND_CONFIG=$5

/opt/resource/out "$TEMPLATE_PATH" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE"
  },
  "source": {
    "storage": {
      "backend_type": "$BACKEND_TYPE",
      "backend_config": $BACKEND_CONFIG
    }
  }
}
JSON
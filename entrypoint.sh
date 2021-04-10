#! /usr/bin/env bash

ENV_NAME=$1
TERRAFORM_SOURCE=$2
BACKEND_TYPE=$3
BACKEND_CONFIG=$4

/opt/resource/out "$PWD" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE"
  },
  "source": {
    "backend_type": "$BACKEND_TYPE",
    "backend_config": $BACKEND_CONFIG
  }
}
JSON
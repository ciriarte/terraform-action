#! /usr/bin/env bash

PATH=$1
ENV_NAME=$2
TERRAFORM_SOURCE=$3

/opt/resource/out "$PATH" <<JSON
{
  "params": {
    "env_name": $ENV_NAME
    "terraform_source": $TERRAFORM_SOURCE,
  }
}
JSON
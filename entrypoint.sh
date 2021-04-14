#! /usr/bin/env bash

ENV_NAME=$1
TERRAFORM_SOURCE=$2
SOURCE=$3
VAR_FILES=$4
OVERRIDE_FILES=$5
DELETE_ON_FAILURE=$6
VARS=$7

/opt/resource/out "$PWD" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE",
    "var_files": $VAR_FILES,
    "override_files": $OVERRIDE_FILES,
    "delete_on_failure": $DELETE_ON_FAILURE,
    "vars": $VARS
  },
  "source": $SOURCE
}
JSON

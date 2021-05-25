#!/usr/bin/env bash

set -eo pipefail

ENV_NAME=$1
TERRAFORM_SOURCE=$2
SOURCE=$3
VAR_FILES=$4
OVERRIDE_FILES=$5
DELETE_ON_FAILURE=$6
VARS=$7
OUTPUT_PATH=$8

if [[ -n $8 ]]; then
  OUTPUT_PATH=$8
  mkdir -p "$OUTPUT_PATH"
fi

tmp_dir=$(mktemp -d)

/opt/resource/out "$PWD" > "${tmp_dir}/check" <<JSON
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

VERSION=$(jq -r .version "${tmp_dir}/check")

cat <<JSON
{
  "version": $VERSION,
  "params": {
    "env_name": "$ENV_NAME"
  },
  "source": $SOURCE
}
JSON

/opt/resource/in "$OUTPUT_PATH" <<JSON
{
  "version": $VERSION,
  "params": {
    "env_name": "$ENV_NAME"
  },
  "source": $SOURCE
}
JSON

#! /usr/bin/env bash

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

# description: allow either directories or files to be specified.
#   recurse down directories and discover .tf files and pass through
#   regular files as is.
# input: json array of files or directories relative to the project root
# output: a json array of the resulting files
function parse_override_paths() {
  override_input=$1
  override_paths=( $(jq '.[]' -r <<< "${override_input}") )
  override_files=()

  for override_file in ${override_paths[@]}; do
    if [[ -d $override_file ]]; then
      while IFS=  read -r -d $'\0'; do
        override_files+=("$REPLY")
      done < <(find "${override_file}" -type f -name "*.tf" -print0)
    elif [[ -f $override_file ]]; then
      override_files+=("${override_file}")
    else
      echo "$override_file is not valid"
      exit 1
    fi
  done

  sorted_unique_override_files=($(echo "${override_files[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  printf '%s\n' "${sorted_unique_override_files[@]}" | jq -R . | jq -cs .
}

/opt/resource/out "$PWD" > "${tmp_dir}/check" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE",
    "var_files": $VAR_FILES,
    "override_files": $(parse_override_paths $OVERRIDE_FILES),
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

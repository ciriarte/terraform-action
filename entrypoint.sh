#!/usr/bin/env bash

set -eo pipefail

ENV_NAME=$1
TERRAFORM_SOURCE=$2
SOURCE=$3
VAR_FILES=$4
OVERRIDE_FILES=$5
DELETE_ON_FAILURE=$6
OUTPUT_PATH=$7
ACTION=$8

if [[ -n $OUTPUT_PATH ]]; then
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

  for override_path in ${override_paths[@]}; do
    if [[ -d $override_path ]]; then
      while IFS=  read -r -d $'\0'; do
        override_files+=("$REPLY")
      done < <(find "${override_path}" -type f -name "*.tf" -print0)
    elif [[ -f $override_path ]]; then
      override_files+=("${override_path}")
    else
      echo "$override_path is not valid"
      exit 1
    fi
  done

  sorted_unique_override_files=($(echo "${override_files[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  printf '%s\n' "${sorted_unique_override_files[@]}" | jq -R . | jq -cs .
}

if ! parsed_override_files="$(parse_override_paths "${OVERRIDE_FILES}")"; then
    echo "parse_override_paths failed to parse ${OVERRIDE_FILES}. Are the paths correct?"
    exit 1
fi

echo "parsed_override_files: ${parsed_override_files}"

if [ $ACTION = "destroy" ]; then
  cat > "${tmp_dir}/out.input" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE",
    "var_files": $VAR_FILES,
    "override_files": ${parsed_override_files},
    "delete_on_failure": $DELETE_ON_FAILURE,
    "action": "destroy"
  },
  "source": $SOURCE
}
JSON
  /opt/resource/out "$PWD" > "${tmp_dir}/check" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE",
    "var_files": $VAR_FILES,
    "override_files": ${parsed_override_files},
    "delete_on_failure": $DELETE_ON_FAILURE,
    "action": "destroy"
  },
  "source": $SOURCE
}
JSON

  version=$(jq -r .version "${tmp_dir}/check")

  /opt/resource/in "$OUTPUT_PATH" <<JSON
{
  "version": $version,
  "params": {
    "env_name": "$ENV_NAME",
    "var_files": $VAR_FILES,
    "action": "destroy"
  },
  "source": $SOURCE
}
JSON
else
  cat > "${tmp_dir}/out.input" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE",
    "var_files": $VAR_FILES,
    "override_files": ${parsed_override_files},
    "delete_on_failure": $DELETE_ON_FAILURE
  },
  "source": $SOURCE
}
JSON
  /opt/resource/out "$PWD" > "${tmp_dir}/check" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE",
    "var_files": $VAR_FILES,
    "override_files": ${parsed_override_files},
    "delete_on_failure": $DELETE_ON_FAILURE
  },
  "source": $SOURCE
}
JSON

  version=$(jq -r .version "${tmp_dir}/check")

  /opt/resource/in "$OUTPUT_PATH" <<JSON
{
  "version": $version,
  "params": {
    "env_name": "$ENV_NAME",
    "var_files": $VAR_FILES
  },
  "source": $SOURCE
}
JSON
fi

cat <<JSON
{
  "version": $version,
  "params": {
    "env_name": "$ENV_NAME"
  },
  "source": $SOURCE
}
JSON
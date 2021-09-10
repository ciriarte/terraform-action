#!/usr/bin/env bash

set -eox pipefail

ENV_NAME=$1
TERRAFORM_SOURCE=$2
SOURCE=$3
VAR_FILES=$4
OVERRIDE_FILES=$5
DELETE_ON_FAILURE=$6
OUTPUT_PATH=$7
ACTION=$8
RETRY_ATTEMPTS=$9

if [[ -n $OUTPUT_PATH ]]; then
  mkdir -p "$OUTPUT_PATH"
fi

function retry() {
  local -r -i max_attempts="$1"; shift
  local -i attempt_num=1
  until "$@"
  do
      if ((attempt_num==max_attempts))
      then
          >&2 echo "Attempt $attempt_num failed and there are no more attempts left!"
          exit 1
      else
          local sleep_time
          sleep_time=$((30 + "${RANDOM}" % 300))
          >&2 echo "Attempt $attempt_num of $max_attempts failed! Trying again in $sleep_time seconds..."
          attempt_num=$((attempt_num+1))
          sleep $sleep_time
      fi
  done
}

# description: allow either directories or files to be specified.
#   recurse down directories and discover .tf files and pass through
#   regular files as is.
# input: json array of files or directories relative to the project root
# output: a json array of the resulting files
function parse_override_paths() {
  override_input=$1
  override_paths=( $(jq '.[]' -r <<< "${override_input}") )
  override_files=()

  for override_path in "${override_paths[@]}"; do
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

function main() {
local cwd
cwd="$1"

cd "$cwd"

tmp_workdir=$(mktemp -d)
tmp_dir=$(mktemp -d)

mapfile -t < <(jq -r .[] <<< "${VAR_FILES}")
for f in "${MAPFILE[@]}"; do
  local subpath
  subpath="$(dirname "$f")"
  mkdir -p "$tmp_workdir/$subpath"
  cp "$f" "$tmp_workdir/$subpath"
done

mapfile -t < <(jq -r .[] <<< "${parsed_override_files}")
for f in "${MAPFILE[@]}"; do
  local subpath
  subpath="$(dirname "$f")"
  mkdir -p "$tmp_workdir/$subpath"
  cp "$f" "$tmp_workdir/$subpath"
done

mkdir -p "${tmp_workdir}/$(dirname "$TERRAFORM_SOURCE")"
cp -R "$TERRAFORM_SOURCE" "${tmp_workdir}/$(dirname "$TERRAFORM_SOURCE")"

ls "${tmp_workdir}"

cd "${tmp_workdir}" > /dev/null
if [[ -n $ACTION ]]; then
  cat > "${tmp_dir}/out.input" <<JSON
{
  "params": {
    "env_name": "$ENV_NAME",
    "terraform_source": "$TERRAFORM_SOURCE",
    "var_files": $VAR_FILES,
    "override_files": ${parsed_override_files},
    "delete_on_failure": $DELETE_ON_FAILURE,
    "action": $ACTION
  },
  "source": $SOURCE
}
JSON
  /opt/resource/out "${PWD}" > "${tmp_dir}/check" < "${tmp_dir}/out.input"
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
  /opt/resource/out "${PWD}" > "${tmp_dir}/check" < "${tmp_dir}/out.input"
fi

VERSION=$(jq -r .version "${tmp_dir}/check")

cat > "${tmp_dir}/in.input" <<JSON
{
  "version": $VERSION,
  "params": {
    "env_name": "$ENV_NAME"
  },
  "source": $SOURCE
}
JSON

/opt/resource/in "$OUTPUT_PATH" < "${tmp_dir}/in.input"

}

retry "$RETRY_ATTEMPTS" main "${PWD}"
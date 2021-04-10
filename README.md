# Terraform Actions

This project is a wrapper on Lyle Franklin's excellent terraform resource for Concourse.
It is meant to ease portability across Github Actions and Concourse Pipelines.

## Inputs

### `env_name`

**Optional** Name of the environment to manage, e.g. staging. A Terraform workspace will be created with this name.

### `terraform_source`

**Required** The relative path of the directory containing your Terraform configuration files. For example: if your .tf files are stored in a git repo called prod-config under a directory terraform-configs, you could do a get: prod-config in your pipeline with terraform_source: prod-config/terraform-configs/ as the source.

### `backend_config`

**Required** JSON object with the corresponding backend config.

### `backend_type`

**Required** We only support `s3` and `gcs` for now

## Example usage

```yaml
- name: Fetch Terraform Templates
  uses: actions/checkout@v2
  with:
    repository: "alfonsof/terraform-google-cloud-examples"
    path: terraforming-repo

- name: "Terraform Apply"
  uses: ciriarte/terraform-actions@main
  with:
    env_name: "cutekoala"
    terraform_source: "terraforming-repo"
    backend_type: s3
    backend_config: ${{ secrets.BACKEND_CONFIG }}
```

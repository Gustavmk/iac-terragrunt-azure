#!/bin/bash

set -e


usage() {
    cat <<EOF
Infrastructure deployment:
    -e (Required) environment name (daily, staging, production, etc)
    -s (Required) site name (us, eu, etc)
    -c (Optional) component name (app, networking, resource-group, etc), omit this to deploy all components
    -p (Optional) plan only, do not deploy
EOF
    exit 1
}

while getopts "e:s:c:p" opt; do
    case $opt in
    e)
        env=$OPTARG
        ;;
    s)
        site=$OPTARG
        ;;
    c)
        component=$OPTARG
        ;;
    p)
        planOnly="true"
        ;;
    *)
        usage
        ;;
    esac
done

# Check the Input parameters
[[ $# -eq 0 || -z $env || -z $site ]] && {
    usage
}

cat <<EOF
environment: ${env}
site: ${site}
component: ${component}
EOF

echo "=== Switch to subscription ${ARM_SUBSCRIPTION_ID} ==="
az account set -s "${ARM_SUBSCRIPTION_ID}" >/dev/null

path=$(dirname "$(cd "$(dirname "$0")" && pwd)")

# NOTE: This is only for re-init or migrate existing terraform state
# terragrunt init -reconfigure

terragrunt run-all validate \
    --terragrunt-working-dir $path/environments/$env/$site/$component \
    --terragrunt-include-external-dependencies \
    --terragrunt-non-interactive

if [[ $planOnly == "true" ]]; then
    terragrunt run-all plan \
        --terragrunt-working-dir $path/environments/$env/$site/$component \
        --terragrunt-include-external-dependencies \
        --terragrunt-non-interactive
else
    terragrunt run-all apply \
        --terragrunt-working-dir $path/environments/$env/$site/$component \
        --terragrunt-include-external-dependencies \
        --terragrunt-non-interactive
fi

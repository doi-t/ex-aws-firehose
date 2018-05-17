#!/bin/sh

set -e

if [[ -z ${TF_BACKEND_TFSTATE_BUCKET} ]]; then
    TF_BACKEND_TFSTATE_BUCKET='ex-aws-firehose'
fi

if [[ -z ${TF_BACKEND_TFSTATE_KEY} ]]; then
    TF_BACKEND_TFSTATE_KEY='ex-aws-firehose/terraform.tfstate'
fi

if [[ -z ${TF_BACKEND_REGION} ]]; then
    TF_BACKEND_REGION='ap-northeast-1'
fi

terraform init -backend=true \
    -backend-config="bucket=${TF_BACKEND_TFSTATE_BUCKET}" \
    -backend-config="key=${TF_BACKEND_TFSTATE_KEY}" \
    -backend-config="region=${TF_BACKEND_REGION}"
terraform apply --var "region=${TF_BACKEND_REGION}"

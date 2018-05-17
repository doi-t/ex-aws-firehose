#!/bin/sh

set -e

if [[ -z ${TF_BACKEND_TFSTATE_BUCKET} ]]; then
    TF_BACKEND_TFSTATE_BUCKET="ex-aws-firehose-tfstate-$(aws sts get-caller-identity --query Account --output text)"
fi

if [[ -z ${TF_BACKEND_TFSTATE_KEY} ]]; then
    TF_BACKEND_TFSTATE_KEY='ex-aws-firehose/terraform.tfstate'
fi

if [[ -z ${TF_BACKEND_REGION} ]]; then
    TF_BACKEND_REGION='ap-northeast-1'
fi

BUCKET_NAME="ex-aws-firehose-$(aws sts get-caller-identity --query Account --output text)"
read -p "Are you sure to delete all data in 's3://${BUCKET_NAME}'? [Y/n]" yn
if [[ $yn = [Yy]* || $yn == "" ]]; then
    aws s3 rm "s3://${BUCKET_NAME}" --recursive
else
    echo "Please save data to somewhere else."
    exit 1
fi

terraform init -backend=true \
    -backend-config="bucket=${TF_BACKEND_TFSTATE_BUCKET}" \
    -backend-config="key=${TF_BACKEND_TFSTATE_KEY}" \
    -backend-config="region=${TF_BACKEND_REGION}"

terraform destroy --var "region=${TF_BACKEND_REGION}"

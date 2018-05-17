# ex-aws-firehose
An Amazon Kinesis Data Firehose Experiment

```
CloudWatch Logs --> Kinesis Firehose [ Lambda Function (Data Transformation) ] --> S3
```

## Usage
### Deploy
```
make TF_BACKEND_TFSTATE_BUCKET=<your existing s3 bucket name> TF_BACKEND_REGION=<your region>
aws firehose describe-delivery-stream --delivery-stream-name ex-aws-firehose
```

### Send a test log to CloudWatch Logs
Check the destination before test.
```
aws s3 ls "ex-aws-firehose-$(aws sts get-caller-identity --query Account --output text)" --recursive
```
Send a test log to CloudWatch Logs.
```
make test
```

```
aws logs get-log-events --log-group-name /ex-aws-firehose --log-stream-name test
```

### Check the result
```
aws s3 ls "ex-aws-firehose-$(aws sts get-caller-identity --query Account --output text)" --recursive # Check after test
```

### Check the error log
```
aws logs get-log-events --log-group-name /ex-aws-firehose --log-stream-name firehose-service-logs
```

### Cleanup
```
make TF_BACKEND_TFSTATE_BUCKET=<your existing s3 bucket name> TF_BACKEND_REGION=<your region> destroy
```

# Refs
- https://aws.amazon.com/kinesis/data-firehose/
- pricing: https://aws.amazon.com/kinesis/data-firehose/pricing/
- limits: https://docs.aws.amazon.com/firehose/latest/dev/limits.html
- terraform: https://www.terraform.io/docs/providers/aws/r/kinesis_firehose_delivery_stream.html

provider "aws" {
  version = "~> 1.19.0"

  region = "${var.region}"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_kinesis_firehose_delivery_stream" "ex_aws_firehose" {
  name        = "${var.resource_name}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn        = "${aws_iam_role.ex_aws_firehose.arn}"
    bucket_arn      = "${aws_s3_bucket.ex_aws_firehose.arn}"
    buffer_interval = 60
    kms_key_arn     = "${aws_kms_key.ex_aws_firehose.arn}"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${aws_cloudwatch_log_group.ex_aws_firehose.name}"
      log_stream_name = "${aws_cloudwatch_log_stream.firehose_service_logs.name}"
    }

    s3_backup_mode = "Enabled"

    s3_backup_configuration = {
      role_arn        = "${aws_iam_role.ex_aws_firehose.arn}"
      bucket_arn      = "${aws_s3_bucket.ex_aws_firehose.arn}"
      prefix          = "backup/"
      buffer_interval = 60
      kms_key_arn     = "${aws_kms_key.ex_aws_firehose.arn}"

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = "${aws_cloudwatch_log_group.ex_aws_firehose.name}"
        log_stream_name = "${aws_cloudwatch_log_stream.firehose_backup_logs.name}"
      }
    }

    processing_configuration = [
      {
        enabled = "true"

        processors = [
          {
            type = "Lambda"

            parameters = [
              {
                parameter_name  = "LambdaArn"
                parameter_value = "${aws_lambda_function.lambda_for_firehose.arn}:$LATEST"
              },
            ]
          },
        ]
      },
    ]
  }
}

resource "aws_s3_bucket" "ex_aws_firehose" {
  bucket = "${var.resource_name}-${data.aws_caller_identity.current.account_id}" # make your bucket unique
  acl    = "private"
}

# Ref. https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
resource "aws_kms_key" "ex_aws_firehose" {
  description = "Encrypt data that comes from CloudWatch Logs when Kinesis Firehose save trasformed data to the destination."

  # Issue: https://github.com/terraform-providers/terraform-provider-aws/issues/245
  # policy = "${data.template_file.kms_policy.rendered}"

  tags = {
    Name = "${var.resource_name}"
  }
}

data "template_file" "kms_policy" {
  template = "${file("${path.module}/kms_policy.json.tpl")}"

  vars {
    account_id        = "${data.aws_caller_identity.current.account_id}"
    firehose_role_arn = "${aws_iam_role.ex_aws_firehose.arn}"
  }
}

resource "aws_kms_alias" "ex_aws_firehose" {
  name          = "alias/ex-aws-firehose"
  target_key_id = "${aws_kms_key.ex_aws_firehose.key_id}"
}

resource "aws_iam_role" "ex_aws_firehose" {
  name = "${var.resource_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ex_aws_firehose" {
  role = "${aws_iam_role.ex_aws_firehose.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.ex_aws_firehose.id}",
                "arn:aws:s3:::${aws_s3_bucket.ex_aws_firehose.id}/*"
            ]
        },
        {
           "Effect": "Allow",
           "Action": [
               "lambda:InvokeFunction",
               "lambda:GetFunctionConfiguration"
           ],
           "Resource": [
               "${aws_lambda_function.lambda_for_firehose.arn}:$LATEST"
           ]
        },
        {
           "Effect": "Allow",
           "Action": [
               "logs:PutLogEvents"
           ],
           "Resource": [
               "${aws_cloudwatch_log_stream.firehose_service_logs.arn}"
           ]
        },
        {
           "Effect": "Allow",
           "Action": [
               "kms:Decrypt",
               "kms:GenerateDataKey"
           ],
           "Resource": [
               "${aws_kms_key.ex_aws_firehose.arn}"
           ],
           "Condition": {
               "StringEquals": {
                   "kms:ViaService": "s3.${data.aws_region.current.name}.amazonaws.com"
               },
               "StringLike": {
                   "kms:EncryptionContext:aws:s3:arn": "arn:aws:s3:::${aws_s3_bucket.ex_aws_firehose.id}/*"
               }
           }
        }
    ]
}
EOF
}

resource "aws_iam_role" "lambda_for_firehose" {
  name = "${var.resource_name}_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_for_firehose" {
  role = "${aws_iam_role.lambda_for_firehose.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
        {
           "Effect": "Allow",
           "Action": [
               "logs:CreateLogGroup",
               "logs:CreateLogStream",
               "logs:PutLogEvents"
           ],
           "Resource": [
               "arn:aws:logs:*:*:*"
           ]
        }
    ]
}
EOF
}

resource "aws_lambda_function" "lambda_for_firehose" {
  function_name    = "${var.resource_name}"
  filename         = "build/${var.resource_name}.zip"
  source_code_hash = "${base64sha256(file("build/${var.resource_name}.zip"))}"
  role             = "${aws_iam_role.lambda_for_firehose.arn}"
  handler          = "main.handler"
  memory_size      = 256
  timeout          = 300
  runtime          = "python3.6"

  tags {
    Name = "${var.resource_name}"
  }
}

# Ref. https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html#FirehoseExample

resource "aws_iam_role" "cloudwatch_logs_to_firehose" {
  name = "${var.resource_name}-cloudwatch-logs-to-firehose"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "logs.${data.aws_region.current.name}.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch_logs_to_firehose" {
  role = "${aws_iam_role.cloudwatch_logs_to_firehose.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
      {
        "Effect":"Allow",
        "Action":["firehose:*"],
        "Resource":["arn:aws:firehose:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      },
      {
        "Effect":"Allow",
        "Action":["iam:PassRole"],
        "Resource":["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoKinesisFirehoseRole"]
      }
    ]
}
EOF
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs_to_firehose" {
  name            = "${var.resource_name}"
  role_arn        = "${aws_iam_role.cloudwatch_logs_to_firehose.arn}"
  log_group_name  = "${aws_cloudwatch_log_group.ex_aws_firehose.name}"
  filter_pattern  = ""
  destination_arn = "${aws_kinesis_firehose_delivery_stream.ex_aws_firehose.arn}"
}

resource "aws_cloudwatch_log_group" "ex_aws_firehose" {
  name = "/${var.resource_name}"
}

resource "aws_cloudwatch_log_stream" "ex_aws_firehose" {
  name           = "test"
  log_group_name = "${aws_cloudwatch_log_group.ex_aws_firehose.name}"
}

resource "aws_cloudwatch_log_stream" "firehose_service_logs" {
  name           = "firehose-service-logs"
  log_group_name = "${aws_cloudwatch_log_group.ex_aws_firehose.name}"
}

resource "aws_cloudwatch_log_stream" "firehose_backup_logs" {
  name           = "firehose-backup-logs"
  log_group_name = "${aws_cloudwatch_log_group.ex_aws_firehose.name}"
}

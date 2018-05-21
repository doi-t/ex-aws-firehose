output "firehose_arn" {
  value = "${aws_kinesis_firehose_delivery_stream.ex_aws_firehose.arn}"
}

output "lambda_arn" {
  value = "${aws_lambda_function.lambda_for_firehose.arn}"
}

output "kms_arn" {
  value = "${aws_kms_key.ex_aws_firehose.arn}"
}

output "firehose_role_arn" {
  value = "${aws_iam_role.ex_aws_firehose.arn}"
}

output "log_group" {
  value = "${aws_cloudwatch_log_group.ex_aws_firehose.arn}"
}

output "log_stream" {
  value = "${aws_cloudwatch_log_stream.ex_aws_firehose.arn}"
}

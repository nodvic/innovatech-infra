resource "aws_sns_topic" "soar_alerts" {
  name = "innovatech-soar-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.soar_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = length(var.instance_ids)
  alarm_name          = "high-cpu-web-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.soar_alerts.arn]

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/soar_action.py"
  output_path = "${path.module}/soar_action.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "innovatech_soar_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "soar_response" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "innovatech_soar_response"
  role             = aws_iam_role.lambda_role.arn
  handler          = "soar_action.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.soar_alerts.arn
}

resource "aws_sns_topic_subscription" "lambda_alert" {
  topic_arn = aws_sns_topic.soar_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.soar_response.arn
}
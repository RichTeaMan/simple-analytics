data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

locals {
  lambda_file_zip      = "analytics-api.zip"
  lambda_function_name = "analytics-api-backend"
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "analytics-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api_gateway_prod_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "Prod"
  auto_deploy = true
}

resource "aws_lambda_function" "analytics_api_lambda" {
  filename      = local.lambda_file_zip
  function_name = "analytics_api_lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "dist/app.handler"

  source_code_hash = filebase64sha256(local.lambda_file_zip)

  runtime       = "nodejs20.x"
  architectures = ["arm64"]

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.cloudwatch_log_group,
  ]
}

resource "aws_apigatewayv2_integration" "analytics_api_lambda" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "API"
  #integration_method   = "POST"
  integration_uri      = aws_lambda_function.analytics_api_lambda.arn
  #passthrough_behavior = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "analytics_api_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "analytics_api_lambda" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "ANY /v1/books"

  target = "integrations/${aws_apigatewayv2_integration.analytics_api_lambda.id}"
}

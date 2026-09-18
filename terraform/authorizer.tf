# Empaquetado del codigo del Authorizer
data "archive_file" "authorizer_zip" {
  type        = "zip"
  source_file = "${path.module}/../authorizer_function.py"
  output_path = "${path.module}/authorizer.zip"
}

# Rol de ejecucion para el Authorizer
resource "aws_iam_role" "authorizer_exec" {
  name = "${var.function_name}-authorizer-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "authorizer_logs" {
  role       = aws_iam_role.authorizer_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Funcion Lambda del Authorizer
resource "aws_lambda_function" "api_authorizer" {
  function_name    = "${var.function_name}-authorizer"
  filename         = data.archive_file.authorizer_zip.output_path
  source_code_hash = data.archive_file.authorizer_zip.output_base64sha256
  role             = aws_iam_role.authorizer_exec.arn
  handler          = "authorizer_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 5

  environment {
    variables = {
      API_KEY = var.authorizer_api_key
    }
  }
}

# Registro del Authorizer en el API Gateway
resource "aws_apigatewayv2_authorizer" "api_key_authorizer" {
  api_id                            = aws_apigatewayv2_api.motor_aws_api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.api_authorizer.invoke_arn
  identity_sources                  = ["$request.header.x-api-key"]
  name                              = "api-key-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

# Permiso para que API Gateway invoque el Authorizer
resource "aws_lambda_permission" "authorizer_invoke" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.motor_aws_api.execution_arn}/*/*"
}
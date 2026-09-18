# API Gateway HTTP API para exponer las Lambdas
resource "aws_apigatewayv2_api" "motor_aws_api" {
  name          = "${var.function_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

# Integracion: conecta la API con la Lambda existente
resource "aws_apigatewayv2_integration" "motor_aws_integration" {
  api_id                 = aws_apigatewayv2_api.motor_aws_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.motor_aws.invoke_arn
  payload_format_version = "2.0"
}

# Ruta: GET /validate (sin proteccion)
resource "aws_apigatewayv2_route" "valida_route" {
  api_id             = aws_apigatewayv2_api.motor_aws_api.id
  route_key          = "GET /validate"
  target             = "integrations/${aws_apigatewayv2_integration.motor_aws_integration.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_key_authorizer.id
}
# Ruta: GET /motor-data (protegida con API Key via Lambda Authorizer)
resource "aws_apigatewayv2_route" "motor_data_route" {
  api_id             = aws_apigatewayv2_api.motor_aws_api.id
  route_key          = "GET /motor-data"
  target             = "integrations/${aws_apigatewayv2_integration.motor_aws_integration.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_key_authorizer.id
}

# Stage con auto-deploy (publica cambios automaticamente)
resource "aws_apigatewayv2_stage" "motor_aws_stage" {
  api_id      = aws_apigatewayv2_api.motor_aws_api.id
  name        = "$default"
  auto_deploy = true
}

# Permiso para que API Gateway pueda invocar la Lambda
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.motor_aws.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.motor_aws_api.execution_arn}/*/*"
}
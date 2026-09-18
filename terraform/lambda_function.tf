# Empaquetado del codigo fuente de la funcion Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda_function.py"
  output_path = "${path.module}/function.zip"
}

# Bucket S3 para almacenamiento de la funcion Lambda
resource "aws_s3_bucket" "lambda_storage" {
  bucket        = "${var.function_name}-storage-${var.aws_account_id}"
  force_destroy = false
}

# Bloqueo total de acceso publico al bucket (buena practica de seguridad)
resource "aws_s3_bucket_public_access_block" "lambda_storage_pab" {
  bucket = aws_s3_bucket.lambda_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Rol de ejecucion IAM para la Funcion Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Permisos basicos de CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permiso de Minimo Privilegio para acceder al bucket S3
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${var.function_name}-s3-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.lambda_storage.arn}/*"
      }
    ]
  })
}

# Definicion de la Funcion Lambda
resource "aws_lambda_function" "motor_aws" {
  function_name    = var.function_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  architectures    = ["x86_64"]
  timeout          = 30
  memory_size      = 256

  # Asociacion de la Layer
  layers = [aws_lambda_layer_version.python_dependencies.arn]

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.lambda_storage.id
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.lambda_s3_access
  ]
}

# URL publica HTTPS para probar la Lambda directamente (sin API Gateway)
resource "aws_lambda_function_url" "motor_aws_url" {
  function_name      = aws_lambda_function.motor_aws.function_name
  authorization_type = "NONE"
}
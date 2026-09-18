output "layer_arn" {
  description = "ARN de la version publicada de la Lambda Layer"
  value       = aws_lambda_layer_version.python_dependencies.arn
}

output "layer_version" {
  description = "Numero de version publicado de la Lambda Layer"
  value       = aws_lambda_layer_version.python_dependencies.version
}

output "lambda_function_arn" {
  description = "ARN de la Funcion Lambda"
  value       = aws_lambda_function.motor_aws.arn
}

output "lambda_function_name" {
  description = "Nombre de la Funcion Lambda"
  value       = aws_lambda_function.motor_aws.function_name
}

output "s3_bucket_name" {
  description = "Nombre del Bucket S3 utilizado por la Lambda"
  value       = aws_s3_bucket.lambda_storage.id
}

output "github_actions_role_arn" {
  description = "ARN del rol asumido por GitHub Actions via OIDC"
  value       = var.create_oidc_role ? aws_iam_role.github_actions[0].arn : "arn:aws:iam::${var.aws_account_id}:role/${var.oidc_role_name}"
}

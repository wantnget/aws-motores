# Recurso para publicar la AWS Lambda Layer
resource "aws_lambda_layer_version" "python_dependencies" {
  layer_name               = var.layer_name
  filename                 = "${path.module}/../layer/layer.zip"
  source_code_hash         = fileexists("${path.module}/../layer/layer.zip") ? filebase64sha256("${path.module}/../layer/layer.zip") : null
  description              = "Dependencias Python para ${var.function_name} compiladas en Docker AL2023"
  compatible_runtimes      = ["python3.12"]
  compatible_architectures = ["x86_64"]
}

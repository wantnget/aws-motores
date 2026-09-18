variable "aws_region" {
  description = "Region de AWS donde se desplegaran los recursos"
  type        = string
  default     = "us-east-2"
}

variable "aws_account_id" {
  description = "ID de la cuenta de AWS (12 digitos)"
  type        = string
  default     = "532918216426"
}

variable "environment" {
  description = "Entorno de ejecucion (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "layer_name" {
  description = "Nombre de la AWS Lambda Layer"
  type        = string
  default     = "motor-aws-dependencies-layer"
}

variable "function_name" {
  description = "Nombre de la funcion Lambda"
  type        = string
  default     = "motor-aws"
}

variable "github_repo" {
  description = "Repositorio de GitHub en formato propietario/repositorio para la politica de confianza OIDC"
  type        = string
  default     = "wantnget/aws-motores"
}

variable "create_oidc_provider" {
  description = "Indica si se debe crear el proveedor OIDC de GitHub en IAM (solo se puede crear uno por cuenta AWS)"
  type        = bool
  default     = false
}

variable "oidc_role_name" {
  description = "Nombre del rol IAM a asumir por GitHub Actions via OIDC"
  type        = string
  default     = "github-actions-motor-aws-deploy"
}

variable "create_oidc_role" {
  description = "Indica si Terraform debe crear/administrar el rol IAM de GitHub Actions"
  type        = bool
  default     = true
}

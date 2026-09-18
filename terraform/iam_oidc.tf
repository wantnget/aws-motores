# Proveedor OIDC de GitHub en AWS IAM (opcional si ya existe en la cuenta)
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f8d264fcd9"
  ]
}

# Politica de confianza OIDC para GitHub Actions
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity", "sts:TagSession"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

# Rol IAM para GitHub Actions
resource "aws_iam_role" "github_actions" {
  count              = var.create_oidc_role ? 1 : 0
  name               = var.oidc_role_name
  description        = "Rol asumido por GitHub Actions via OIDC para desplegar Lambda y Layer"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# Politica de Minimo Privilegio para despliegue de Lambda, Layer, S3 y API Gateway
data "aws_iam_policy_document" "github_actions_permissions" {
  # Permisos para gestionar la Lambda Layer
  statement {
    sid    = "LambdaLayerManagement"
    effect = "Allow"
    actions = [
      "lambda:PublishLayerVersion",
      "lambda:GetLayerVersion",
      "lambda:GetLayerVersionPolicy",
      "lambda:DeleteLayerVersion"
    ]
    resources = [
      "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:layer:${var.layer_name}*"
    ]
  }

  # Permisos para gestionar las Funciones Lambda (motor-aws y motor-aws-authorizer)
  statement {
    sid    = "LambdaFunctionManagement"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:ListVersionsByFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunctionUrlConfig",
      "lambda:CreateFunctionUrlConfig",
      "lambda:UpdateFunctionUrlConfig",
      "lambda:DeleteFunctionUrlConfig",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy"
    ]
    resources = [
      "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:${var.function_name}*"
    ]
  }

  # Permisos para pasar los roles de ejecucion a las Lambdas
  statement {
    sid    = "PassRoleToLambda"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:role/${var.function_name}-exec-role",
      "arn:aws:iam::${var.aws_account_id}:role/${var.function_name}-authorizer-exec-role"
    ]
  }

  # Permisos para gestionar recursos de IAM asociados a las Lambdas
  statement {
    sid    = "IAMRoleReadManagement"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:TagRole",
      "iam:ListInstanceProfilesForRole"
    ]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:role/${var.function_name}-exec-role",
      "arn:aws:iam::${var.aws_account_id}:role/${var.function_name}-authorizer-exec-role"
    ]
  }

  # Permisos sobre CloudWatch Logs
  statement {
    sid    = "CloudWatchLogsManagement"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "logs:PutRetentionPolicy",
      "logs:DeleteLogGroup"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.function_name}*"
    ]
  }

  # Permisos sobre S3 para los archivos y el almacenamiento de la funcion
  statement {
    sid    = "S3StorageManagement"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketAcl",
      "s3:ListBucket",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:GetBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::*"
    ]
  }

  # Permisos sobre el bucket de Terraform state
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::motor-aws-tfstate-${var.aws_account_id}",
      "arn:aws:s3:::motor-aws-tfstate-${var.aws_account_id}/*"
    ]
  }

  # Permisos para el lock del state en DynamoDB
  statement {
    sid    = "TerraformStateLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/motor-aws-tfstate-locks"
    ]
  }

  # Permisos para gestionar el API Gateway (HTTP API, rutas, integraciones, stage, authorizer)
  statement {
    sid    = "ApiGatewayManagement"
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:DELETE"
    ]
    resources = [
      "arn:aws:apigateway:${var.aws_region}::/apis*"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_policy" {
  count  = var.create_oidc_role ? 1 : 0
  name   = "${var.oidc_role_name}-policy"
  role   = aws_iam_role.github_actions[0].id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
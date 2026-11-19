locals {
  common_tags = {
    Project   = "ScribeBA"
    ManagedBy = "Terraform"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "app" {
  name                 = "scribeba-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

resource "aws_lightsail_container_service" "app" {
  name        = var.container_service_name
  power       = var.container_power
  scale       = 1
  is_disabled = false

  private_registry_access {
    ecr_image_puller_role {
      is_active = true
    }
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "allow_lightsail_pull" {
  statement {
    sid    = "AllowLightsailToPullScribeBAImage"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_lightsail_container_service.app.private_registry_access[0].ecr_image_puller_role[0].principal_arn]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
  }
}

resource "aws_ecr_repository_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy     = data.aws_iam_policy_document.allow_lightsail_pull.json
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the 10 most recent immutable application images."
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_cognito_user_pool" "app" {
  name                     = "scribeba-prod-users"
  user_pool_tier           = "LITE"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection      = "ACTIVE"

  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Verify your ScribeBA account"
    email_message        = "Your ScribeBA verification code is {####}. It expires after 24 hours."
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = local.common_tags
}

resource "aws_cognito_identity_provider" "google" {
  count         = var.google_client_id != "" && var.google_client_secret != "" ? 1 : 0
  user_pool_id  = aws_cognito_user_pool.app.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
    authorize_scopes = "openid email profile"
  }

  attribute_mapping = {
    email = "email"
    name  = "name"
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name                                 = "scribeba-prod-web"
  user_pool_id                         = aws_cognito_user_pool.app.id
  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers = concat(
    ["COGNITO"],
    length(aws_cognito_identity_provider.google) == 1 ? ["Google"] : []
  )

  callback_urls = ["${trimsuffix(aws_lightsail_container_service.app.url, "/")}/api/auth/cognito/callback"]
  logout_urls   = [aws_lightsail_container_service.app.url]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  depends_on = [aws_cognito_user_pool_domain.app]
}

resource "aws_cognito_user_pool_domain" "app" {
  domain                = "scribeba-${data.aws_caller_identity.current.account_id}"
  user_pool_id          = aws_cognito_user_pool.app.id
  managed_login_version = 1
}

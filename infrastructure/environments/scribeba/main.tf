locals {
  allowed_origin = var.allowed_origin != "" ? var.allowed_origin : try(aws_lightsail_container_service.app[0].url, "")
  common_tags = {
    Project   = "ScribeBA"
    ManagedBy = "Terraform"
  }
}

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
  count       = var.deploy_app ? 1 : 0
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
  count = var.deploy_app ? 1 : 0

  statement {
    sid    = "AllowLightsailToPullScribeBAImage"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_lightsail_container_service.app[0].private_registry_access[0].ecr_image_puller_role[0].principal_arn]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
  }
}

resource "aws_ecr_repository_policy" "app" {
  count      = var.deploy_app ? 1 : 0
  repository = aws_ecr_repository.app.name
  policy     = data.aws_iam_policy_document.allow_lightsail_pull[0].json
}

resource "aws_lightsail_container_service_deployment_version" "app" {
  count        = var.deploy_app ? 1 : 0
  service_name = aws_lightsail_container_service.app[0].name

  container {
    container_name = "scribeba"
    image          = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"

    ports = {
      "8000" = "HTTP"
    }

    environment = {
      PORT                     = "8000"
      SCRIBEBA_PUBLIC_MODE     = "true"
      SCRIBEBA_ALLOWED_ORIGIN  = local.allowed_origin
      SCRIBEBA_APP_PASSWORD    = var.app_password
      SCRIBEBA_SESSION_SECRET  = var.session_secret
      SCRIBEBA_MODE            = "live"
      NEBIUS_API_KEY           = var.nebius_api_key
      NEBIUS_BASE_URL          = var.nebius_base_url
      NEBIUS_MODEL             = var.nebius_model
      SCRIBEBA_COOKIE_SAMESITE = "Lax"
    }
  }

  public_endpoint {
    container_name = "scribeba"
    container_port = 8000

    health_check {
      path                = "/api/health"
      success_codes       = "200-299"
      interval_seconds    = 30
      timeout_seconds     = 10
      healthy_threshold   = 2
      unhealthy_threshold = 3
    }
  }

  depends_on = [aws_ecr_repository_policy.app]
}

module "notify_slack" {
  count   = var.enable_slack_notifications ? 1 : 0
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "7.5.3"

  create            = true
  sns_topic_name    = "scribeba-aws-alerts"
  slack_webhook_url = var.slack_webhook_url
  slack_channel     = var.slack_channel
  slack_username    = "ScribeBA AWS Alerts"
}

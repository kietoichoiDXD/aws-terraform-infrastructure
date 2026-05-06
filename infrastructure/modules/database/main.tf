# ---------------------------------------------------------------------------------------------------------------------
# MODULE: DATABASE - Quản lý DynamoDB
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_dynamodb_table" "this" {
  name         = "${var.project_name}-table-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Component = "Database"
  })
}

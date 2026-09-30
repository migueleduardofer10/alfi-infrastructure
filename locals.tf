locals {
  name_prefix = "${var.company}-${var.project}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Delosi"
  }
}

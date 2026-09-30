# ── Environment: stg ──────────────────────────────────────────────────

environment           = "stg"
project_name          = "delosi-alfie"
aws_region            = "us-east-1"
execution_environment = "Staging"

# ── VPC (VPC001) ──────────────────────────────────────────────────────
vpc_id            = "vpc-091d1a423dbf0b65c"
security_group_id = "sg-0ed47a0e01e1b83a5"
subnet_id1        = "subnet-0c69e6a6b2fe043fb"
subnet_id2        = "subnet-0318d1439886dc3fa"

# ── Lambda ────────────────────────────────────────────────────────────
lambda_source_path = "./lambda_code"

# ── Secrets Manager ──────────────────────────────────────────────────
invoicing_invoices_db_secret_name  = "delosi-alfie-stg/invoicing-invoices-db"
invoicing_invoices_app_secret_name = "delosi-alfie-stg/invoicing-invoices-app"

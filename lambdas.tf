# ── Lambda: Invoicing Invoices (API REST de facturas sobre PostgreSQL) ─

module "invoicing_invoices" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "invoicing-invoices"
  description      = "API de facturas: crear, actualizar, consultar y listar. Minimal API .NET 8 sobre PostgreSQL"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.InvoicingInvoices.Api"
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  # VPC: necesaria para llegar al PostgreSQL de facturación
  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.invoicing_invoices_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.invoicing_invoices_db_secret_name,
    var.invoicing_invoices_app_secret_name,
  ]

  # El API Gateway que expone esta Lambda todavía no se gestiona en este repo.

  tracing_mode = "Active"
  tags         = local.common_tags
}

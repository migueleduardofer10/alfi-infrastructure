# ── Lambdas de Alfie ──────────────────────────────────────────────────
#
# Un bloque por lambda, con la receta modules/lambda. Cada una tiene su rol IAM y
# permiso de lectura sobre sus dos secretos. El nombre en AWS queda como
# Delosi-Alfie-{Function-Name}-Lambda-{Env} y es el que va en el .gitlab-ci.yml
# de cada repo.
#
# handler = nombre del ensamblado .NET del proyecto Api. A CONFIRMAR en cada repo:
# solo el de invoicing-invoices está verificado.
#
# Lo que NO se gestiona aquí todavía: API Gateway, colas SQS, bucket S3 de PDFs,
# EventBridge, SES y WAF.

# ═══ Facturación ═══

# ── Lambda: Invoicing-Invoices ─

module "invoicing_invoices" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "invoicing-invoices"
  description      = "API de facturas: crear, actualizar, consultar y listar"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.InvoicingInvoices.Api"
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.invoicing_invoices_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.invoicing_invoices_db_secret_name,
    var.invoicing_invoices_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ── Lambda: Invoicing-Config-Approvers ─

module "invoicing_config_approvers" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "invoicing-config-approvers"
  description      = "API de configuración de aprobadores: crear, consultar, modificar y listar"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.InvoicingConfigApprovers.Api" # A CONFIRMAR en el repo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.invoicing_config_approvers_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.invoicing_config_approvers_db_secret_name,
    var.invoicing_config_approvers_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ── Lambda: Invoicing-Approval-Tray ─

module "invoicing_approval_tray" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "invoicing-approval-tray"
  description      = "API de bandeja de aprobaciones: pendientes, aprobadas, rechazadas y filtros"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.InvoicingApprovalTray.Api" # A CONFIRMAR en el repo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.invoicing_approval_tray_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.invoicing_approval_tray_db_secret_name,
    var.invoicing_approval_tray_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ── Lambda: Invoicing-Approvals ─

module "invoicing_approvals" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "invoicing-approvals"
  description      = "API de aprobaciones: aprobar, rechazar, cambiar estado y enviar facturas"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.InvoicingApprovals.Api" # A CONFIRMAR en el repo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.invoicing_approvals_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.invoicing_approvals_db_secret_name,
    var.invoicing_approvals_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ═══ Sincronización externa ═══

# ── Lambda: Invoicing-Sap-Sync ─

module "invoicing_sap_sync" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "invoicing-sap-sync"
  description      = "Sincronización de facturación con SAP: crear, consultar y estados"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.InvoicingSapSync::Delosi.InvoicingSapSync.Functions.SapSyncFunction::FunctionHandler" # A CONFIRMAR: lambda de cola, formato Ensamblado::Clase::Metodo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 300

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.invoicing_sap_sync_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.invoicing_sap_sync_db_secret_name,
    var.invoicing_sap_sync_app_secret_name,
  ]

  # Consume la cola "sap-sync" (envío a SAP). La receta crea el event source
  # mapping y la IAM policy de lectura. batch_size=1: una factura por invocación,
  # una excepción reintenta solo esa (hasta maxReceiveCount=3 → DLQ).
  sqs_event_sources = [
    {
      event_source_arn = module.sqs_queues.queue_arns["sap-sync"]
      enabled          = true
      batch_size       = 1
    }
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ── Lambda: Master-Data-Service ─

module "master_data_service" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "master-data-service"
  description      = "Consulta de datos maestros: proveedor, marca y otros"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.MasterDataService.Api" # A CONFIRMAR en el repo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.master_data_service_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.master_data_service_db_secret_name,
    var.master_data_service_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ═══ Sincronización interna ═══

# ── Lambda: Master-Data-Sync ─
# La dispara EventBridge Scheduler por horario, no el API Gateway. La receta crea
# el schedule y el rol que lo deja invocar la lambda.

module "master_data_sync" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "master-data-sync"
  description      = "Obtención y sincronización de maestros desde el API Delosi: productos, compañía, marcas, campañas"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.MasterDataSync::Delosi.MasterDataSync.Functions.MasterDataSyncFunction::FunctionHandler" # A CONFIRMAR: lambda de scheduler, formato Ensamblado::Clase::Metodo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 300

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.master_data_sync_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.master_data_sync_db_secret_name,
    var.master_data_sync_app_secret_name,
  ]

  # Corre dos veces al día. A CONFIRMAR las horas; provisional: 6:00 y 18:00 Lima.
  enable_scheduler               = true
  scheduler_description          = "Sincroniza maestros desde el API Delosi, 6:00 y 18:00 Lima"
  schedule_expression            = "cron(0 6,18 * * ? *)"
  scheduler_timezone             = "America/Lima"
  scheduler_state                = "ENABLED"
  scheduler_flexible_time_window = { mode = "OFF" }

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ═══ Notificación ═══

# ── Lambda: Invoicing-Notifications ─

module "invoicing_notifications" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "invoicing-notifications"
  description      = "Notificaciones por correo de facturas y vales"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.InvoicingNotifications::Delosi.InvoicingNotifications.Functions.NotificationFunction::FunctionHandler" # A CONFIRMAR: lambda de cola (la dispara SQS segun el diagrama), formato Ensamblado::Clase::Metodo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.invoicing_notifications_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.invoicing_notifications_db_secret_name,
    var.invoicing_notifications_app_secret_name,
  ]

  # Envía los correos de facturas y vales por Amazon SES
  enable_ses_permissions = true

  # Consume la cola "notifications" (pedidos de correo que publica invoicing-approvals).
  sqs_event_sources = [
    {
      event_source_arn = module.sqs_queues.queue_arns["notifications"]
      enabled          = true
      batch_size       = 1
    }
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ═══ Vales ═══

# ── Lambda: Voucher-Management ─

module "voucher_management" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "voucher-management"
  description      = "Gestor de vales: generar vales físicos y digitales, actualizar vigencia"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.VoucherManagement.Api" # A CONFIRMAR en el repo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.voucher_management_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.voucher_management_db_secret_name,
    var.voucher_management_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ── Lambda: Voucher-Models ─

module "voucher_models" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "voucher-models"
  description      = "Modelos de vales: crear, modificar, consultar y listar"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.VoucherModels.Api" # A CONFIRMAR en el repo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.voucher_models_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.voucher_models_db_secret_name,
    var.voucher_models_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ── Lambda: Voucher-Reasons ─

module "voucher_reasons" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "voucher-reasons"
  description      = "Motivos de cese para vales: crear, consultar y modificar"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.VoucherReasons.Api" # A CONFIRMAR en el repo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.voucher_reasons_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.voucher_reasons_db_secret_name,
    var.voucher_reasons_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ── Lambda: Document-Generation ─

module "document_generation" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "document-generation"
  description      = "Generación de PDF de vales hacia S3"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.DocumentGeneration::Delosi.DocumentGeneration.Functions.DocumentGenerationFunction::FunctionHandler" # A CONFIRMAR: lambda de cola, formato Ensamblado::Clase::Metodo
  source_code_path = var.lambda_source_path
  memory_size      = 1024
  timeout          = 300

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.document_generation_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.document_generation_db_secret_name,
    var.document_generation_app_secret_name,
  ]

  # Consume la cola "document-generation" (generar PDF). Un vale por invocación.
  sqs_event_sources = [
    {
      event_source_arn = module.sqs_queues.queue_arns["document-generation"]
      enabled          = true
      batch_size       = 1
    }
  ]

  # Guarda los PDF en S3. El bucket no lo crea este repo (no hay receta): lo crea
  # DevOps. La receta le pasa el nombre al lambda en S3_BUCKET_NAME.
  enable_s3_permissions = true
  s3_bucket_names       = [var.documents_bucket_name]

  tracing_mode = "Active"
  tags         = local.common_tags
}

# ═══ Sincronización Micros ═══

# ── Lambda: Voucher-Redemption ─

module "voucher_redemption" {
  source           = "git::https://gitlab.com/delosi/devops/iac-templates//modules/lambda?ref=main"
  company          = var.company
  project          = var.project
  environment      = var.environment
  function_name    = "voucher-redemption"
  description      = "Sincronización con Micros: consulta de vales y redenciones"
  runtime          = "dotnet8"
  architecture     = "x86_64"
  handler          = "Delosi.VoucherRedemption.Api" # A CONFIRMAR en el repo
  source_code_path = var.lambda_source_path
  memory_size      = 512
  timeout          = 28

  vpc_id             = var.vpc_id
  security_group_ids = [var.security_group_id]
  subnet_ids         = [var.subnet_id1, var.subnet_id2]

  environment_variables = local.voucher_redemption_environment

  enable_secrets_manager_permissions = true
  secrets_manager_secret_names = [
    var.voucher_redemption_db_secret_name,
    var.voucher_redemption_app_secret_name,
  ]

  tracing_mode = "Active"
  tags         = local.common_tags
}

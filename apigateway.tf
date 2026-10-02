# ── API Gateway: Ventas Corp ────────────────────────────────────────────────
#
# Un solo API Gateway REST para todas las lambdas que se exponen por HTTP, como
# en el diagrama. Cada lambda cuelga de su propio recurso raíz con integración
# proxy: /{path}/{proxy+} → lambda. El gateway no conoce las rutas reales, esas
# viven en la Minimal API dentro de cada lambda.
#
# Calcado de apigateway.tf de api-delosi-infrastructure (notifications).
#
# Lambdas que NO se exponen: invoicing-notifications, invoicing-sap-sync y
# document-generation las dispara SQS; master-data-sync la dispara EventBridge
# Scheduler. Ninguna recibe llamadas HTTP.
#
# El Authorizer es externo a este repo. Los métodos van con authorization = NONE
# y cada lambda valida el JWT. /voucher-redemption la llama Micros, que no tiene
# JWT; cómo se autentica (API key u otro) está por definir, hoy va abierta.

module "api" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-base?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_name        = "${local.name_prefix}-api"
  api_gateway_description = "REST API de Ventas Corp: facturación, vales y datos maestros"
  endpoint_type           = "REGIONAL"
  stage_name              = var.environment
  tags                    = local.common_tags
}

# ═══ /facturas → lambda invoicing-invoices ═══
# rutas /facturas/crear, /facturas/listar, etc. (verificado en el codigo)

module "invoicing_invoices_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "facturas"
}

module "invoicing_invoices_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.invoicing_invoices_resource.resource_id
  path_part          = "{proxy+}"
}

module "invoicing_invoices_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.invoicing_invoices_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "invoicing_invoices_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.invoicing_invoices_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "invoicing_invoices_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.invoicing_invoices_resource_proxy.resource_id
  resource_name           = "invoicing-invoices-integration-proxy"
  http_method             = module.invoicing_invoices_method_proxy.http_method
  lambda_function_name    = module.invoicing_invoices.function_name
  lambda_invoke_arn       = module.invoicing_invoices.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "invoicing_invoices_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.invoicing_invoices.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ═══ /config-approvers → lambda invoicing-config-approvers ═══
# A CONFIRMAR: debe coincidir con el prefijo de rutas de la app

module "invoicing_config_approvers_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "config-approvers"
}

module "invoicing_config_approvers_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.invoicing_config_approvers_resource.resource_id
  path_part          = "{proxy+}"
}

module "invoicing_config_approvers_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.invoicing_config_approvers_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "invoicing_config_approvers_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.invoicing_config_approvers_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "invoicing_config_approvers_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.invoicing_config_approvers_resource_proxy.resource_id
  resource_name           = "invoicing-config-approvers-integration-proxy"
  http_method             = module.invoicing_config_approvers_method_proxy.http_method
  lambda_function_name    = module.invoicing_config_approvers.function_name
  lambda_invoke_arn       = module.invoicing_config_approvers.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "invoicing_config_approvers_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.invoicing_config_approvers.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ═══ /approval-tray → lambda invoicing-approval-tray ═══
# A CONFIRMAR: debe coincidir con el prefijo de rutas de la app

module "invoicing_approval_tray_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "approval-tray"
}

module "invoicing_approval_tray_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.invoicing_approval_tray_resource.resource_id
  path_part          = "{proxy+}"
}

module "invoicing_approval_tray_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.invoicing_approval_tray_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "invoicing_approval_tray_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.invoicing_approval_tray_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "invoicing_approval_tray_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.invoicing_approval_tray_resource_proxy.resource_id
  resource_name           = "invoicing-approval-tray-integration-proxy"
  http_method             = module.invoicing_approval_tray_method_proxy.http_method
  lambda_function_name    = module.invoicing_approval_tray.function_name
  lambda_invoke_arn       = module.invoicing_approval_tray.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "invoicing_approval_tray_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.invoicing_approval_tray.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ═══ /approvals → lambda invoicing-approvals ═══
# A CONFIRMAR: debe coincidir con el prefijo de rutas de la app

module "invoicing_approvals_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "approvals"
}

module "invoicing_approvals_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.invoicing_approvals_resource.resource_id
  path_part          = "{proxy+}"
}

module "invoicing_approvals_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.invoicing_approvals_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "invoicing_approvals_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.invoicing_approvals_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "invoicing_approvals_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.invoicing_approvals_resource_proxy.resource_id
  resource_name           = "invoicing-approvals-integration-proxy"
  http_method             = module.invoicing_approvals_method_proxy.http_method
  lambda_function_name    = module.invoicing_approvals.function_name
  lambda_invoke_arn       = module.invoicing_approvals.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "invoicing_approvals_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.invoicing_approvals.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ═══ /vouchers → lambda voucher-management ═══
# A CONFIRMAR: debe coincidir con el prefijo de rutas de la app

module "voucher_management_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "vouchers"
}

module "voucher_management_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.voucher_management_resource.resource_id
  path_part          = "{proxy+}"
}

module "voucher_management_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.voucher_management_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "voucher_management_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.voucher_management_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "voucher_management_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.voucher_management_resource_proxy.resource_id
  resource_name           = "voucher-management-integration-proxy"
  http_method             = module.voucher_management_method_proxy.http_method
  lambda_function_name    = module.voucher_management.function_name
  lambda_invoke_arn       = module.voucher_management.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "voucher_management_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.voucher_management.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ═══ /voucher-models → lambda voucher-models ═══
# A CONFIRMAR: debe coincidir con el prefijo de rutas de la app

module "voucher_models_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "voucher-models"
}

module "voucher_models_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.voucher_models_resource.resource_id
  path_part          = "{proxy+}"
}

module "voucher_models_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.voucher_models_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "voucher_models_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.voucher_models_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "voucher_models_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.voucher_models_resource_proxy.resource_id
  resource_name           = "voucher-models-integration-proxy"
  http_method             = module.voucher_models_method_proxy.http_method
  lambda_function_name    = module.voucher_models.function_name
  lambda_invoke_arn       = module.voucher_models.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "voucher_models_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.voucher_models.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ═══ /voucher-reasons → lambda voucher-reasons ═══
# A CONFIRMAR: debe coincidir con el prefijo de rutas de la app

module "voucher_reasons_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "voucher-reasons"
}

module "voucher_reasons_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.voucher_reasons_resource.resource_id
  path_part          = "{proxy+}"
}

module "voucher_reasons_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.voucher_reasons_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "voucher_reasons_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.voucher_reasons_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "voucher_reasons_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.voucher_reasons_resource_proxy.resource_id
  resource_name           = "voucher-reasons-integration-proxy"
  http_method             = module.voucher_reasons_method_proxy.http_method
  lambda_function_name    = module.voucher_reasons.function_name
  lambda_invoke_arn       = module.voucher_reasons.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "voucher_reasons_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.voucher_reasons.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ═══ /master-data → lambda master-data-service ═══
# A CONFIRMAR: debe coincidir con el prefijo de rutas de la app

module "master_data_service_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "master-data"
}

module "master_data_service_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.master_data_service_resource.resource_id
  path_part          = "{proxy+}"
}

module "master_data_service_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.master_data_service_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "master_data_service_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.master_data_service_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "master_data_service_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.master_data_service_resource_proxy.resource_id
  resource_name           = "master-data-service-integration-proxy"
  http_method             = module.master_data_service_method_proxy.http_method
  lambda_function_name    = module.master_data_service.function_name
  lambda_invoke_arn       = module.master_data_service.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "master_data_service_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.master_data_service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ═══ /voucher-redemption → lambda voucher-redemption ═══
# La llama Micros por HTTPS (consulta y redención de vales). Micros no tiene JWT.
# A CONFIRMAR: cómo se autentica (API key u otro) y el prefijo de rutas de la app.

module "voucher_redemption_resource" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.api.root_resource_id
  path_part          = "voucher-redemption"
}

module "voucher_redemption_resource_proxy" {
  source             = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-resource?ref=main"
  company            = var.company
  project            = var.project
  environment        = var.environment
  api_gateway_id     = module.api.api_gateway_id
  parent_resource_id = module.voucher_redemption_resource.resource_id
  path_part          = "{proxy+}"
}

module "voucher_redemption_cors_proxy" {
  source          = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method-cors?ref=main"
  api_gateway_id  = module.api.api_gateway_id
  resource_id     = module.voucher_redemption_resource_proxy.resource_id
  allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Amz-Date",
    "X-Api-Key",
    "X-Amz-Security-Token",
    "X-Correlation-Id",
  ]
  allow_origin = var.allow_origin
}

module "voucher_redemption_method_proxy" {
  source         = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-method?ref=main"
  api_gateway_id = module.api.api_gateway_id
  resource_id    = module.voucher_redemption_resource_proxy.resource_id
  company        = var.company
  project        = var.project
  environment    = var.environment
  http_method    = "ANY"
  authorization  = "NONE"
}

module "voucher_redemption_integration_proxy" {
  source                  = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-lambda-integration?ref=main"
  company                 = var.company
  project                 = var.project
  environment             = var.environment
  api_gateway_id          = module.api.api_gateway_id
  resource_id             = module.voucher_redemption_resource_proxy.resource_id
  resource_name           = "voucher-redemption-integration-proxy"
  http_method             = module.voucher_redemption_method_proxy.http_method
  lambda_function_name    = module.voucher_redemption.function_name
  lambda_invoke_arn       = module.voucher_redemption.function_invoke_arn
  integration_type        = "AWS_PROXY"
  integration_http_method = "POST"
  create_permission       = true
  integration_timeout     = 29000
}

resource "aws_lambda_permission" "voucher_redemption_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.voucher_redemption.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# ── Deployment ────────────────────────────────────────────────────────

module "api_deployment" {
  source      = "git::https://gitlab.com/delosi/devops/iac-templates//modules/api-gateway-deployment?ref=main"
  rest_api_id = module.api.api_gateway_id
  stage_name  = var.environment
  company     = var.company
  project     = var.project
  environment = var.environment

  trigger = sha1(jsonencode({
    resources = [
      module.invoicing_invoices_resource.resource_id, module.invoicing_invoices_resource_proxy.resource_id,
      module.invoicing_config_approvers_resource.resource_id, module.invoicing_config_approvers_resource_proxy.resource_id,
      module.invoicing_approval_tray_resource.resource_id, module.invoicing_approval_tray_resource_proxy.resource_id,
      module.invoicing_approvals_resource.resource_id, module.invoicing_approvals_resource_proxy.resource_id,
      module.voucher_management_resource.resource_id, module.voucher_management_resource_proxy.resource_id,
      module.voucher_models_resource.resource_id, module.voucher_models_resource_proxy.resource_id,
      module.voucher_reasons_resource.resource_id, module.voucher_reasons_resource_proxy.resource_id,
      module.master_data_service_resource.resource_id, module.master_data_service_resource_proxy.resource_id,
      module.voucher_redemption_resource.resource_id, module.voucher_redemption_resource_proxy.resource_id,
    ]
    methods = [
      "${module.invoicing_invoices_resource_proxy.resource_id}:ANY",
      "${module.invoicing_config_approvers_resource_proxy.resource_id}:ANY",
      "${module.invoicing_approval_tray_resource_proxy.resource_id}:ANY",
      "${module.invoicing_approvals_resource_proxy.resource_id}:ANY",
      "${module.voucher_management_resource_proxy.resource_id}:ANY",
      "${module.voucher_models_resource_proxy.resource_id}:ANY",
      "${module.voucher_reasons_resource_proxy.resource_id}:ANY",
      "${module.master_data_service_resource_proxy.resource_id}:ANY",
      "${module.voucher_redemption_resource_proxy.resource_id}:ANY",
    ]
    integrations = [
      module.invoicing_invoices_integration_proxy.integration_id,
      module.invoicing_config_approvers_integration_proxy.integration_id,
      module.invoicing_approval_tray_integration_proxy.integration_id,
      module.invoicing_approvals_integration_proxy.integration_id,
      module.voucher_management_integration_proxy.integration_id,
      module.voucher_models_integration_proxy.integration_id,
      module.voucher_reasons_integration_proxy.integration_id,
      module.master_data_service_integration_proxy.integration_id,
      module.voucher_redemption_integration_proxy.integration_id,
    ]
  }))

  depends_on = [
    module.invoicing_invoices_method_proxy,
    module.invoicing_invoices_integration_proxy,
    module.invoicing_invoices_cors_proxy,
    module.invoicing_config_approvers_method_proxy,
    module.invoicing_config_approvers_integration_proxy,
    module.invoicing_config_approvers_cors_proxy,
    module.invoicing_approval_tray_method_proxy,
    module.invoicing_approval_tray_integration_proxy,
    module.invoicing_approval_tray_cors_proxy,
    module.invoicing_approvals_method_proxy,
    module.invoicing_approvals_integration_proxy,
    module.invoicing_approvals_cors_proxy,
    module.voucher_management_method_proxy,
    module.voucher_management_integration_proxy,
    module.voucher_management_cors_proxy,
    module.voucher_models_method_proxy,
    module.voucher_models_integration_proxy,
    module.voucher_models_cors_proxy,
    module.voucher_reasons_method_proxy,
    module.voucher_reasons_integration_proxy,
    module.voucher_reasons_cors_proxy,
    module.master_data_service_method_proxy,
    module.master_data_service_integration_proxy,
    module.master_data_service_cors_proxy,
    module.voucher_redemption_method_proxy,
    module.voucher_redemption_integration_proxy,
    module.voucher_redemption_cors_proxy,
  ]
}

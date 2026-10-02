output "invoicing_invoices_function_name" {
  value = module.invoicing_invoices.function_name
}

output "invoicing_invoices_function_arn" {
  value = module.invoicing_invoices.function_arn
}

output "invoicing_config_approvers_function_name" {
  value = module.invoicing_config_approvers.function_name
}

output "invoicing_config_approvers_function_arn" {
  value = module.invoicing_config_approvers.function_arn
}

output "invoicing_approval_tray_function_name" {
  value = module.invoicing_approval_tray.function_name
}

output "invoicing_approval_tray_function_arn" {
  value = module.invoicing_approval_tray.function_arn
}

output "invoicing_approvals_function_name" {
  value = module.invoicing_approvals.function_name
}

output "invoicing_approvals_function_arn" {
  value = module.invoicing_approvals.function_arn
}

output "invoicing_sap_sync_function_name" {
  value = module.invoicing_sap_sync.function_name
}

output "invoicing_sap_sync_function_arn" {
  value = module.invoicing_sap_sync.function_arn
}

output "master_data_service_function_name" {
  value = module.master_data_service.function_name
}

output "master_data_service_function_arn" {
  value = module.master_data_service.function_arn
}

output "master_data_sync_function_name" {
  value = module.master_data_sync.function_name
}

output "master_data_sync_function_arn" {
  value = module.master_data_sync.function_arn
}

output "invoicing_notifications_function_name" {
  value = module.invoicing_notifications.function_name
}

output "invoicing_notifications_function_arn" {
  value = module.invoicing_notifications.function_arn
}

output "voucher_management_function_name" {
  value = module.voucher_management.function_name
}

output "voucher_management_function_arn" {
  value = module.voucher_management.function_arn
}

output "voucher_models_function_name" {
  value = module.voucher_models.function_name
}

output "voucher_models_function_arn" {
  value = module.voucher_models.function_arn
}

output "voucher_reasons_function_name" {
  value = module.voucher_reasons.function_name
}

output "voucher_reasons_function_arn" {
  value = module.voucher_reasons.function_arn
}

output "document_generation_function_name" {
  value = module.document_generation.function_name
}

output "document_generation_function_arn" {
  value = module.document_generation.function_arn
}

output "voucher_redemption_function_name" {
  value = module.voucher_redemption.function_name
}

output "voucher_redemption_function_arn" {
  value = module.voucher_redemption.function_arn
}

output "api_invoke_url" {
  description = "URL base del API Gateway. Las rutas cuelgan de cada recurso (ej. {url}/facturas/listar)"
  value       = "https://${module.api.api_gateway_id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}

output "sqs_sap_sync_queue_url" {
  description = "SQS sap-sync queue URL"
  value       = module.sqs_queues.queue_urls["sap-sync"]
}

output "sqs_document_generation_queue_url" {
  description = "SQS document-generation queue URL"
  value       = module.sqs_queues.queue_urls["document-generation"]
}

output "sqs_notifications_queue_url" {
  description = "SQS notifications queue URL"
  value       = module.sqs_queues.queue_urls["notifications"]
}

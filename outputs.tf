output "invoicing_invoices_function_name" {
  description = "Invoicing invoices Lambda function name"
  value       = module.invoicing_invoices.function_name
}

output "invoicing_invoices_function_arn" {
  description = "Invoicing invoices Lambda function ARN"
  value       = module.invoicing_invoices.function_arn
}

output "invoicing_invoices_role_arn" {
  description = "Invoicing invoices Lambda execution role ARN"
  value       = module.invoicing_invoices.role_arn
}

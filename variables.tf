variable "company" {
  description = "Nombre de la compañía o proyecto"
  type        = string
  default     = "Delosi"
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
  default     = "alfie"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "delosi-alfie"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno (dev, stg, prd)"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "El entorno debe ser 'dev', 'stg' o 'prd'."
  }
}

# ── VPC ───────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "VPC ID for Lambda functions"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Lambda functions"
  type        = string
}

variable "subnet_id1" {
  description = "First private subnet ID (SUBPRIVZA002)"
  type        = string
}

variable "subnet_id2" {
  description = "Second private subnet ID (SUBPRIVZC002)"
  type        = string
}

# ── Lambda ────────────────────────────────────────────────────────────

variable "lambda_source_path" {
  description = "Path to Lambda function source code"
  type        = string
  default     = "./lambda_code"
}

variable "execution_environment" {
  description = "Execution environment for the Lambda function"
  type        = string
  default     = "Development"
}

# ── Secrets Manager (managed manually) ──────────────────────────────

variable "invoicing_invoices_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de invoicing-invoices"
  type        = string
}

variable "invoicing_invoices_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de invoicing-invoices"
  type        = string
}

variable "invoicing_config_approvers_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de invoicing-config-approvers"
  type        = string
}

variable "invoicing_config_approvers_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de invoicing-config-approvers"
  type        = string
}

variable "invoicing_approval_tray_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de invoicing-approval-tray"
  type        = string
}

variable "invoicing_approval_tray_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de invoicing-approval-tray"
  type        = string
}

variable "invoicing_approvals_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de invoicing-approvals"
  type        = string
}

variable "invoicing_approvals_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de invoicing-approvals"
  type        = string
}

variable "invoicing_sap_sync_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de invoicing-sap-sync"
  type        = string
}

variable "invoicing_sap_sync_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de invoicing-sap-sync"
  type        = string
}

variable "master_data_service_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de master-data-service"
  type        = string
}

variable "master_data_service_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de master-data-service"
  type        = string
}

variable "master_data_sync_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de master-data-sync"
  type        = string
}

variable "master_data_sync_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de master-data-sync"
  type        = string
}

variable "invoicing_notifications_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de invoicing-notifications"
  type        = string
}

variable "invoicing_notifications_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de invoicing-notifications"
  type        = string
}

variable "voucher_management_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de voucher-management"
  type        = string
}

variable "voucher_management_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de voucher-management"
  type        = string
}

variable "voucher_models_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de voucher-models"
  type        = string
}

variable "voucher_models_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de voucher-models"
  type        = string
}

variable "voucher_reasons_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de voucher-reasons"
  type        = string
}

variable "voucher_reasons_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de voucher-reasons"
  type        = string
}

variable "document_generation_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de document-generation"
  type        = string
}

variable "document_generation_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de document-generation"
  type        = string
}

variable "voucher_redemption_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de voucher-redemption"
  type        = string
}

variable "voucher_redemption_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de voucher-redemption"
  type        = string
}

variable "audit_db_secret_name" {
  description = "Secreto con la conexión a la base de datos de audit"
  type        = string
}

variable "audit_app_secret_name" {
  description = "Secreto con la configuración sensible (JwtAuth, etc.) de audit"
  type        = string
}

# ── API Gateway ──────────────────────────────────────────────────────

variable "allow_origin" {
  description = "Origen permitido en CORS del API Gateway. Lo consume el frontend de Alfie; ajustar al dominio real por ambiente"
  type        = string
  default     = "'*'"
}

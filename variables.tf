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

# ── Secrets Manager ──────────────────────────────────────────────────

variable "invoicing_invoices_db_secret_name" {
  description = "Secrets Manager secret name con la conexión a PostgreSQL de facturación (managed manually)"
  type        = string
}

variable "invoicing_invoices_app_secret_name" {
  description = "Secrets Manager secret name con la configuración JwtAuth del API de facturas (managed manually)"
  type        = string
}

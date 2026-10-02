# ── Environment: prd ──────────────────────────────────────────────────

environment           = "prd"
project_name          = "delosi-alfie"
aws_region            = "us-east-1"
execution_environment = "Production"

# ── VPC ──────────────────────────────────────────────────────
vpc_id            = "vpc-abd6f5d0"
security_group_id = "sg-0d64facc304dc364f"
subnet_id1        = "subnet-093ec91b2f0071dfd"
subnet_id2        = "subnet-00c01d9777a1865a6"

# ── Lambda ────────────────────────────────────────────────────────────
lambda_source_path = "./lambda_code"

# ── Secrets Manager ──────────────────────────────────────────────────
invoicing_invoices_db_secret_name          = "delosi-alfie-prd/invoicing-invoices-db"
invoicing_invoices_app_secret_name         = "delosi-alfie-prd/invoicing-invoices-app"
invoicing_config_approvers_db_secret_name  = "delosi-alfie-prd/invoicing-config-approvers-db"
invoicing_config_approvers_app_secret_name = "delosi-alfie-prd/invoicing-config-approvers-app"
invoicing_approval_tray_db_secret_name     = "delosi-alfie-prd/invoicing-approval-tray-db"
invoicing_approval_tray_app_secret_name    = "delosi-alfie-prd/invoicing-approval-tray-app"
invoicing_approvals_db_secret_name         = "delosi-alfie-prd/invoicing-approvals-db"
invoicing_approvals_app_secret_name        = "delosi-alfie-prd/invoicing-approvals-app"
invoicing_sap_sync_db_secret_name          = "delosi-alfie-prd/invoicing-sap-sync-db"
invoicing_sap_sync_app_secret_name         = "delosi-alfie-prd/invoicing-sap-sync-app"
master_data_service_db_secret_name         = "delosi-alfie-prd/master-data-service-db"
master_data_service_app_secret_name        = "delosi-alfie-prd/master-data-service-app"
master_data_sync_db_secret_name            = "delosi-alfie-prd/master-data-sync-db"
master_data_sync_app_secret_name           = "delosi-alfie-prd/master-data-sync-app"
invoicing_notifications_db_secret_name     = "delosi-alfie-prd/invoicing-notifications-db"
invoicing_notifications_app_secret_name    = "delosi-alfie-prd/invoicing-notifications-app"
voucher_management_db_secret_name          = "delosi-alfie-prd/voucher-management-db"
voucher_management_app_secret_name         = "delosi-alfie-prd/voucher-management-app"
voucher_models_db_secret_name              = "delosi-alfie-prd/voucher-models-db"
voucher_models_app_secret_name             = "delosi-alfie-prd/voucher-models-app"
voucher_reasons_db_secret_name             = "delosi-alfie-prd/voucher-reasons-db"
voucher_reasons_app_secret_name            = "delosi-alfie-prd/voucher-reasons-app"
document_generation_db_secret_name         = "delosi-alfie-prd/document-generation-db"
document_generation_app_secret_name        = "delosi-alfie-prd/document-generation-app"
voucher_redemption_db_secret_name          = "delosi-alfie-prd/voucher-redemption-db"
voucher_redemption_app_secret_name         = "delosi-alfie-prd/voucher-redemption-app"

# ── Storage ───────────────────────────────────────────────────────────
documents_bucket_name = "delosi-alfie-documents-prd"

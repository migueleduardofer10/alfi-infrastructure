# ── Environment: stg ──────────────────────────────────────────────────

environment           = "stg"
project_name          = "delosi-ventascorp"
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
invoicing_invoices_db_secret_name          = "delosi-ventascorp-stg/invoicing-invoices-db"
invoicing_invoices_app_secret_name         = "delosi-ventascorp-stg/invoicing-invoices-app"
invoicing_config_approvers_db_secret_name  = "delosi-ventascorp-stg/invoicing-config-approvers-db"
invoicing_config_approvers_app_secret_name = "delosi-ventascorp-stg/invoicing-config-approvers-app"
invoicing_approval_tray_db_secret_name     = "delosi-ventascorp-stg/invoicing-approval-tray-db"
invoicing_approval_tray_app_secret_name    = "delosi-ventascorp-stg/invoicing-approval-tray-app"
invoicing_approvals_db_secret_name         = "delosi-ventascorp-stg/invoicing-approvals-db"
invoicing_approvals_app_secret_name        = "delosi-ventascorp-stg/invoicing-approvals-app"
invoicing_sap_sync_db_secret_name          = "delosi-ventascorp-stg/invoicing-sap-sync-db"
invoicing_sap_sync_app_secret_name         = "delosi-ventascorp-stg/invoicing-sap-sync-app"
master_data_service_db_secret_name         = "delosi-ventascorp-stg/master-data-service-db"
master_data_service_app_secret_name        = "delosi-ventascorp-stg/master-data-service-app"
master_data_sync_db_secret_name            = "delosi-ventascorp-stg/master-data-sync-db"
master_data_sync_app_secret_name           = "delosi-ventascorp-stg/master-data-sync-app"
invoicing_notifications_db_secret_name     = "delosi-ventascorp-stg/invoicing-notifications-db"
invoicing_notifications_app_secret_name    = "delosi-ventascorp-stg/invoicing-notifications-app"
voucher_management_db_secret_name          = "delosi-ventascorp-stg/voucher-management-db"
voucher_management_app_secret_name         = "delosi-ventascorp-stg/voucher-management-app"
voucher_models_db_secret_name              = "delosi-ventascorp-stg/voucher-models-db"
voucher_models_app_secret_name             = "delosi-ventascorp-stg/voucher-models-app"
voucher_reasons_db_secret_name             = "delosi-ventascorp-stg/voucher-reasons-db"
voucher_reasons_app_secret_name            = "delosi-ventascorp-stg/voucher-reasons-app"
document_generation_db_secret_name         = "delosi-ventascorp-stg/document-generation-db"
document_generation_app_secret_name        = "delosi-ventascorp-stg/document-generation-app"
voucher_redemption_db_secret_name          = "delosi-ventascorp-stg/voucher-redemption-db"
voucher_redemption_app_secret_name         = "delosi-ventascorp-stg/voucher-redemption-app"

# ── Storage ───────────────────────────────────────────────────────────
documents_bucket_name = "delosi-ventascorp-vales-s3-stg"

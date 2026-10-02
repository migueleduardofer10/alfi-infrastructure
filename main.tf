# Variables de entorno de cada lambda. Los nombres de los secretos los lee el
# código via AWS SDK en startup (DB_SECRET_NAME / APP_SECRET_NAME).

locals {
  invoicing_invoices_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.invoicing_invoices_db_secret_name
    APP_SECRET_NAME        = var.invoicing_invoices_app_secret_name

    # Una sola Lambda atiende las cuatro operaciones: crear, actualizar, consultar y listar
    INVOICE_OPERATION = "All"

    Swagger__Enabled                = "false"
    Database__CommandTimeoutSeconds = "20"
  }
}

locals {
  invoicing_config_approvers_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.invoicing_config_approvers_db_secret_name
    APP_SECRET_NAME        = var.invoicing_config_approvers_app_secret_name
  }
}

locals {
  invoicing_approval_tray_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.invoicing_approval_tray_db_secret_name
    APP_SECRET_NAME        = var.invoicing_approval_tray_app_secret_name
  }
}

locals {
  invoicing_approvals_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.invoicing_approvals_db_secret_name
    APP_SECRET_NAME        = var.invoicing_approvals_app_secret_name

    # Colas a las que publica: facturas aprobadas para SAP y pedidos de correo.
    # A CONFIRMAR: el nombre de la variable que espera el código.
    Sqs__SapSyncQueueUrl       = module.sqs_queues.queue_urls["sap-sync"]
    Sqs__NotificationsQueueUrl = module.sqs_queues.queue_urls["notifications"]
  }
}

locals {
  invoicing_sap_sync_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.invoicing_sap_sync_db_secret_name
    APP_SECRET_NAME        = var.invoicing_sap_sync_app_secret_name
  }
}

locals {
  master_data_service_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.master_data_service_db_secret_name
    APP_SECRET_NAME        = var.master_data_service_app_secret_name
  }
}

locals {
  master_data_sync_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.master_data_sync_db_secret_name
    APP_SECRET_NAME        = var.master_data_sync_app_secret_name
  }
}

locals {
  invoicing_notifications_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.invoicing_notifications_db_secret_name
    APP_SECRET_NAME        = var.invoicing_notifications_app_secret_name
  }
}

locals {
  voucher_management_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.voucher_management_db_secret_name
    APP_SECRET_NAME        = var.voucher_management_app_secret_name

    # Cola a la que publica los vales generados para que se cree su PDF.
    # A CONFIRMAR: el nombre de la variable que espera el código.
    Sqs__DocumentGenerationQueueUrl = module.sqs_queues.queue_urls["document-generation"]
  }
}

locals {
  voucher_models_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.voucher_models_db_secret_name
    APP_SECRET_NAME        = var.voucher_models_app_secret_name
  }
}

locals {
  voucher_reasons_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.voucher_reasons_db_secret_name
    APP_SECRET_NAME        = var.voucher_reasons_app_secret_name
  }
}

locals {
  document_generation_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.document_generation_db_secret_name
    APP_SECRET_NAME        = var.document_generation_app_secret_name
  }
}

locals {
  voucher_redemption_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.voucher_redemption_db_secret_name
    APP_SECRET_NAME        = var.voucher_redemption_app_secret_name
  }
}

locals {
  audit_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment
    DB_SECRET_NAME         = var.audit_db_secret_name
    APP_SECRET_NAME        = var.audit_app_secret_name
  }
}

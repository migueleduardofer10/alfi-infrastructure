locals {
  invoicing_invoices_environment = {
    ENVIRONMENT            = var.execution_environment
    ASPNETCORE_ENVIRONMENT = var.execution_environment

    # Nombres de los secretos — el lambda los lee via AWS SDK en startup.
    # DB:  ConnectionStrings__Postgres
    # APP: JwtAuth__Enabled, JwtAuth__MetadataAddress, JwtAuth__ValidIssuer, JwtAuth__ValidAudience
    DB_SECRET_NAME  = var.invoicing_invoices_db_secret_name
    APP_SECRET_NAME = var.invoicing_invoices_app_secret_name

    # Una sola Lambda atiende las cuatro operaciones: crear, actualizar, consultar y listar
    INVOICE_OPERATION = "All"

    Swagger__Enabled                = "false"
    Database__CommandTimeoutSeconds = "20"
  }
}

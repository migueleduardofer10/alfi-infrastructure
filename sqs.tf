# ── Colas SQS de Ventas Corp ────────────────────────────────────────────────
#
# Cada cola trae su
# DLQ: tras max_receive_count intentos fallidos el mensaje pasa a la DLQ.
#
# El visibility_timeout debe ser mayor al timeout de la lambda que consume, si no
# el mensaje se vuelve visible y se procesa dos veces.
#
# Quién publica y quién consume, según el diagrama:
#   sap-sync            → publica invoicing-approvals (enviar facturas), consume invoicing-sap-sync
#   notifications       → publica invoicing-approvals (correos),         consume invoicing-notifications
#   document-generation → publica voucher-management (generar vales),   consume document-generation

module "sqs_queues" {
  source      = "git::https://gitlab.com/delosi/devops/iac-templates//modules/sqs?ref=main"
  company     = var.company
  project     = var.project
  environment = var.environment

  queues = [
    {
      name                       = "sap-sync"
      visibility_timeout_seconds = 310 # lambda invoicing-sap-sync: 300 s
      max_receive_count          = 3
      create_dlq                 = true
      message_retention_seconds  = 1209600 # 14 días
    },
    {
      name                       = "notifications"
      visibility_timeout_seconds = 60 # lambda invoicing-notifications: 28 s
      max_receive_count          = 3
      create_dlq                 = true
      message_retention_seconds  = 1209600
    },
    {
      name                       = "document-generation"
      visibility_timeout_seconds = 310 # lambda document-generation: 300 s
      max_receive_count          = 3
      create_dlq                 = true
      message_retention_seconds  = 1209600
    }
  ]

  enable_server_side_encryption = true
  tags                          = local.common_tags
}

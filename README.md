# alfie-infrastructure

Infraestructura (Terraform) de los componentes de Alfie. Solo usa las recetas de [iac-templates](https://gitlab.com/delosi/devops/iac-templates).

## Lambdas

Un bloque `module` por lambda en `lambdas.tf`, con la receta `modules/lambda`. Cada una tiene su rol IAM y permiso de lectura sobre sus dos secretos. El nombre en AWS es `Delosi-Alfie-{Function-Name}-Lambda-{Env}`.

| `function_name` | Repo | Lambda en dev |
|---|---|---|
| `invoicing-invoices` | api-invoicing-invoices | Delosi-Alfie-Invoicing-Invoices-Lambda-Dev |
| `invoicing-config-approvers` | api-invoicing-config-approvers | Delosi-Alfie-Invoicing-Config-Approvers-Lambda-Dev |
| `invoicing-approval-tray` | api-invoicing-approval-tray | Delosi-Alfie-Invoicing-Approval-Tray-Lambda-Dev |
| `invoicing-approvals` | api-invoicing-approvals | Delosi-Alfie-Invoicing-Approvals-Lambda-Dev |
| `invoicing-sap-sync` | api-invoicing-sap-sync | Delosi-Alfie-Invoicing-Sap-Sync-Lambda-Dev |
| `invoicing-notifications` | api-invoicing-notifications | Delosi-Alfie-Invoicing-Notifications-Lambda-Dev |
| `master-data-sync` | api-master-data-sync | Delosi-Alfie-Master-Data-Sync-Lambda-Dev |
| `master-data-service` | api-master-data-service | Delosi-Alfie-Master-Data-Service-Lambda-Dev |
| `voucher-management` | api-voucher-management | Delosi-Alfie-Voucher-Management-Lambda-Dev |
| `voucher-models` | api-voucher-models | Delosi-Alfie-Voucher-Models-Lambda-Dev |
| `voucher-reasons` | api-voucher-reasons | Delosi-Alfie-Voucher-Reasons-Lambda-Dev |
| `voucher-redemption` | api-voucher-redemption | Delosi-Alfie-Voucher-Redemption-Lambda-Dev |
| `document-generation` | api-document-generation | Delosi-Alfie-Document-Generation-Lambda-Dev |
| `audit` | a confirmar | Delosi-Alfie-Audit-Lambda-Dev |

Ese nombre es el que va en `DEV_AWS_FUNCTION_NAME`, `STG_AWS_FUNCTION_NAME` y `PRD_FUNCTION_NAME` del `.gitlab-ci.yml` de cada repo.

Para agregar una lambda: un bloque más en `lambdas.tf`, su `local` de variables de entorno en `main.tf` y sus dos variables de secreto en `variables.tf` y en los tfvars.

## API Gateway

Un solo API Gateway REST, `Delosi-alfie-{env}-api`, en `apigateway.tf`. Cada lambda expuesta cuelga de su propio recurso con integración proxy, `/{path}/{proxy+}` → lambda, calcado de notifications en `api-delosi-infrastructure`.

| Ruta base | Lambda |
|---|---|
| `/facturas` | invoicing-invoices |
| `/config-approvers` | invoicing-config-approvers |
| `/approval-tray` | invoicing-approval-tray |
| `/approvals` | invoicing-approvals |
| `/vouchers` | voucher-management |
| `/voucher-models` | voucher-models |
| `/voucher-reasons` | voucher-reasons |
| `/master-data` | master-data-service |
| `/master-data-sync` | master-data-sync |

Cada ruta base debe coincidir con el prefijo de rutas de la app dentro de la lambda: el gateway le pasa el path completo, por ejemplo `/facturas/listar`. Solo `/facturas` está verificado contra el código.

No se exponen `invoicing-sap-sync`, `document-generation`, `audit`, `invoicing-notifications` ni `voucher-redemption`: las disparan SQS, EventBridge o Micros, no un usuario. El Authorizer es externo; los métodos van con `authorization = NONE` y cada lambda valida su JWT. La URL base sale en `terraform output api_invoke_url`.

## Colas SQS

Tres colas con su DLQ en `sqs.tf`, con la receta `modules/sqs`. Nombre en AWS: `Delosi-alfie-{cola}{env}`.

| Cola | Publica | Consume | Estado |
|---|---|---|---|
| `sap-sync` | invoicing-approvals | invoicing-sap-sync | consumidor conectado |
| `document-generation` | voucher-management | document-generation | consumidor conectado |
| `audit` | EventBridge | audit | consumidor conectado |

La receta de lambda crea el event source mapping y el permiso de **lectura** del consumidor. El permiso de **escritura** del que publica no tiene receta: hay que resolverlo con DevOps antes de que `invoicing-approvals` y `voucher-management` puedan enviar mensajes. Las URLs de las colas les llegan en `Sqs__SapSyncQueueUrl` y `Sqs__DocumentGenerationQueueUrl`.

## Permisos

| Lambda | Qué tiene | Dónde |
|---|---|---|
| `document-generation` | Permiso de escritura en el bucket `documents_bucket_name` | `enable_s3_permissions` |
| `invoicing-notifications` | Permiso para enviar correos por SES | `enable_ses_permissions` |

El bucket de PDFs no lo crea este repo: `delosi-alfie-documents-{env}` lo crea DevOps a mano.

Lo que no se gestiona aquí (sin receta): bucket S3, EventBridge, WAF y la configuración de SES (dominio y remitentes verificados).

## Secretos

Ningún secreto pasa por Terraform ni por GitLab. Se crean a mano en Secrets Manager, dos por lambda y por ambiente. Los tfvars solo guardan sus nombres:

- `delosi-alfie-{env}/{function_name}-db` → conexión a la base
- `delosi-alfie-{env}/{function_name}-app` → JWT y demás configuración sensible

La receta le da a cada lambda permiso de lectura sobre sus dos secretos y le pasa los nombres en `DB_SECRET_NAME` y `APP_SECRET_NAME`. El código los lee al arrancar.

Ejemplo para `invoicing-invoices` en dev:

`delosi-alfie-dev/invoicing-invoices-db`
```json
{
  "ConnectionStrings__Postgres": "Host=HOST;Port=5432;Database=invoicing_db;Username=USER;Password=PASSWORD;SSL Mode=VerifyFull;Root Certificate=/var/task/certificates/global-bundle.pem;Pooling=true;Maximum Pool Size=10;Timeout=10;Command Timeout=20;Include Error Detail=false"
}
```

`delosi-alfie-dev/invoicing-invoices-app`
```json
{
  "JwtAuth__Enabled": true,
  "JwtAuth__MetadataAddress": "https://IDP/.well-known/openid-configuration",
  "JwtAuth__ValidIssuer": "https://IDP",
  "JwtAuth__ValidAudience": "api-invoicing-invoices"
}
```

El pipeline necesita estas variables CI/CD: `{DEV,STG,PRD}_AWS_ACCESS_KEY_ID`, `{DEV,STG,PRD}_AWS_SECRET_ACCESS_KEY`, `AWS_REGION` y `GITLAB_CI_TEST_TOKEN`.

## Despliegue local

```bash
terraform init -backend-config=backend-configs/backend-dev.tfvars
terraform plan -var-file=environments/dev.tfvars
```

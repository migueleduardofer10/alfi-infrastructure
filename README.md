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

Ese nombre es el que va en `DEV_AWS_FUNCTION_NAME`, `STG_AWS_FUNCTION_NAME` y `PRD_FUNCTION_NAME` del `.gitlab-ci.yml` de cada repo.

Para agregar una lambda: un bloque más en `lambdas.tf`, su `local` de variables de entorno en `main.tf` y sus dos variables de secreto en `variables.tf` y en los tfvars.

Lo que todavía no se gestiona aquí: API Gateway, colas SQS, bucket S3 de PDFs, EventBridge, SES y WAF.

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

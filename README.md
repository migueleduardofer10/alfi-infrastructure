# alfie-infrastructure

Infraestructura (Terraform) de los componentes de Alfie. Solo usa las recetas de [iac-templates](https://gitlab.com/delosi/devops/iac-templates).

## Recursos

| Recurso | Receta | Archivo |
|---|---|---|
| Lambda `Delosi-Alfie-Invoicing-Invoices-Lambda-{env}` + rol IAM | `modules/lambda` | `lambdas.tf` |

La Lambda es el API de facturas (`api-invoicing-invoices`). Una sola función atiende las cuatro operaciones, con `INVOICE_OPERATION = All`. El API Gateway que la expone todavía no se gestiona aquí.

## Secretos

Ningún secreto pasa por Terraform ni por GitLab. Se crean a mano en AWS Secrets Manager, dos por ambiente, y los tfvars solo guardan sus nombres. La receta le da al lambda permiso de lectura y le pasa los nombres en `DB_SECRET_NAME` y `APP_SECRET_NAME`. El lambda los lee al arrancar.

`delosi-alfie-{env}/invoicing-invoices-db`:

```json
{
  "ConnectionStrings__Postgres": "Host=HOST;Port=5432;Database=invoicing_db;Username=USER;Password=PASSWORD;SSL Mode=VerifyFull;Root Certificate=/var/task/certificates/global-bundle.pem;Pooling=true;Maximum Pool Size=10;Timeout=10;Command Timeout=20;Include Error Detail=false"
}
```

`delosi-alfie-{env}/invoicing-invoices-app`:

```json
{
  "JwtAuth__Enabled": true,
  "JwtAuth__MetadataAddress": "https://IDP/.well-known/openid-configuration",
  "JwtAuth__ValidIssuer": "https://IDP",
  "JwtAuth__ValidAudience": "api-invoicing-invoices"
}
```

`JwtAuth__Enabled` debe ir en `true` en el secreto: en dev el lambda corre con `ASPNETCORE_ENVIRONMENT=Development`, y ese perfil desactiva JWT si el secreto no lo pisa.

El pipeline necesita estas variables CI/CD: `{DEV,STG,PRD}_AWS_ACCESS_KEY_ID`, `{DEV,STG,PRD}_AWS_SECRET_ACCESS_KEY`, `AWS_REGION` y `GITLAB_CI_TEST_TOKEN`.

## Despliegue local

```bash
terraform init -backend-config=backend-configs/backend-dev.tfvars
terraform plan -var-file=environments/dev.tfvars
```

# alfie-infrastructure

Infraestructura (Terraform) de los componentes de Alfie. Solo usa las recetas de [iac-templates](https://gitlab.com/delosi/devops/iac-templates).

## Pendientes para el primer despliegue

Este repo ya tiene en Terraform todo lo del diagrama de arquitectura que se puede crear con las recetas de DevOps (`iac-templates`): 14 lambdas, el API Gateway, 3 colas SQS y los permisos de Secrets Manager, S3 y SES.

Para desplegarlo faltan datos que este repo no puede inventar. Algunos los tiene el equipo de Alfie y otros DevOps. Mientras no estén, los valores del repo son **supuestos** y van marcados con `A CONFIRMAR` en el código.

---

### Equipo de Alfie

#### 1. Falta la lambda de auditoría

El diagrama tiene una lambda **API-AUDITORÍA** (logs, trazabilidad e historial de cambios), pero no hay repo para ella.

En Terraform ya está creada con un nombre provisional, `audit`, y conectada a la cola `audit`. Necesitamos:

- **El nombre del repo**, por ejemplo `api-audit`.
- **El handler**, que tiene que ser de lambda de cola (ver punto 5).

Con eso se ajusta el bloque `module "audit"` en `lambdas.tf`.

#### 2. Mapeo repo → lambda → ruta base

Cada repo se despliega en una lambda con un nombre fijo, y las que reciben llamadas HTTP cuelgan del API Gateway bajo una **ruta base**. Por ejemplo:

```
api-voucher-models  →  Delosi-Alfie-Voucher-Models-Lambda-Dev  →  /voucher-models
```

Así, los endpoints de ese repo quedan como `{url-del-gateway}/voucher-models/crear`, `{url-del-gateway}/voucher-models/listar`, etc.

**Por qué importa:** el gateway le pasa a la lambda la ruta completa. Si la app define sus endpoints como `/modelos/crear` pero el gateway usa `/voucher-models`, toda llamada responde **404**.

Hoy el mapeo está así. Solo la primera fila está verificada contra el código. Necesitamos que cada equipo confirme o corrija su fila:

| Lambda (diagrama) | Repo | Ruta base | Handler |
|---|---|---|---|
| API-FACTURAS | `api-invoicing-invoices` | `/facturas` ✔ | `Delosi.InvoicingInvoices.Api` ✔ |
| API-CONFIG-APROBADORES | `api-invoicing-config-approvers` | `/config-approvers` | `Delosi.InvoicingConfigApprovers.Api` |
| API-BANDEJA-APROBACIONES | `api-invoicing-approval-tray` | `/approval-tray` | `Delosi.InvoicingApprovalTray.Api` |
| API-APROBACIONES | `api-invoicing-approvals` | `/approvals` | `Delosi.InvoicingApprovals.Api` |
| API-GESTOR | `api-voucher-management` | `/vouchers` | `Delosi.VoucherManagement.Api` |
| API-MODELOS | `api-voucher-models` | `/voucher-models` | `Delosi.VoucherModels.Api` |
| API-MOTIVOS | `api-voucher-reasons` | `/voucher-reasons` | `Delosi.VoucherReasons.Api` |
| API-Maestros | `api-master-data-service` | `/master-data` | `Delosi.MasterDataService.Api` |
| API-MAESTROS API | `api-master-data-sync` | `/master-data-sync` | `Delosi.MasterDataSync.Api` |
| API-SYNC-VALES | `api-voucher-redemption` | `/voucher-redemption` (la llama Micros) | `Delosi.VoucherRedemption.Api` |
| API-NOTIFICACION | `api-invoicing-notifications` | sin ruta, la dispara SQS | `Delosi.InvoicingNotifications::Delosi.InvoicingNotifications.Functions.NotificationFunction::FunctionHandler` |
| API-SYNC-FACTURACION | `api-invoicing-sap-sync` | sin ruta, la dispara SQS | `Delosi.InvoicingSapSync::Delosi.InvoicingSapSync.Functions.SapSyncFunction::FunctionHandler` |
| Generar PDF | `api-document-generation` | sin ruta, la dispara SQS | `Delosi.DocumentGeneration::Delosi.DocumentGeneration.Functions.DocumentGenerationFunction::FunctionHandler` |
| API-AUDITORIA | (falta repo) | sin ruta, la dispara SQS | `Delosi.Audit::Delosi.Audit.Functions.AuditFunction::FunctionHandler` |

- **Ruta base**: el prefijo con el que empiezan los endpoints de la app. En facturas, por ejemplo, es el `MapGroup("/facturas")`.
- **Handler**: en las APIs es el nombre del ensamblado del proyecto que se despliega, el `AssemblyName` del `.csproj`. En las de cola es `Ensamblado::Namespace.Clase::Metodo`; los de la tabla son supuestos, el equipo debe dar el real (ver punto 5). Si está mal, la lambda no arranca.

El nombre de cada lambda en AWS está en la tabla de la sección [Lambdas](#lambdas). Ese nombre es el que va en el `.gitlab-ci.yml` de cada repo, en `DEV_AWS_FUNCTION_NAME` y `PRD_FUNCTION_NAME`.

#### 3. Nombre del bucket de documentos

La lambda `document-generation` genera los PDF de los vales y los guarda en un bucket de S3. Ya tiene el permiso de escritura, pero sobre un nombre provisional:

```
delosi-alfie-documents-dev
delosi-alfie-documents-prd
```

Necesitamos el **nombre real** del bucket por ambiente. Se cambia en `environments/{env}.tfvars`, variable `documents_bucket_name`. La lambda lo recibe en la variable de entorno `S3_BUCKET_NAME`.

#### 4. Variable con la URL de la cola

Dos lambdas **envían** mensajes a una cola. Para eso necesitan la URL de la cola, que Terraform les pasa como variable de entorno:

| Lambda que envía | Variable de entorno | Cola |
|---|---|---|
| `invoicing-approvals` | `Sqs__SapSyncQueueUrl` | `sap-sync`, envío de facturas a SAP |
| `voucher-management` | `Sqs__DocumentGenerationQueueUrl` | `document-generation`, generar PDF |

En el código, .NET la lee como `config["Sqs:SapSyncQueueUrl"]` (el `__` se convierte en `:` solo).

**El nombre de la variable lo propusimos nosotros.** Si el código ya lee la URL con otra clave, por ejemplo `config["Queues:Sap"]`, nos dicen cuál y cambiamos el nombre en Terraform a `Queues__Sap`. No hace falta tocar el código.

#### 5. Cómo están hechas las lambdas que reciben mensajes de SQS

Tres lambdas no reciben llamadas HTTP: las despierta una cola cuando le llega un mensaje.

| Lambda | Cola |
|---|---|
| `invoicing-sap-sync` | `sap-sync` |
| `document-generation` | `document-generation` |
| `audit` | `audit` |

Una lambda de cola tiene un código de entrada distinto al de una API. No tiene rutas: tiene un método que recibe la lista de mensajes, por ejemplo:

```csharp
public class SapSyncFunction
{
    public async Task FunctionHandler(SQSEvent evt, ILambdaContext ctx)
    {
        foreach (var msg in evt.Records)
        {
            // procesar msg.Body
        }
    }
}
```

Y su handler en Terraform se escribe `Ensamblado::Namespace.Clase::Método`. Hoy está provisional así:

```
Delosi.InvoicingSapSync::Delosi.InvoicingSapSync.Functions.SapSyncFunction::FunctionHandler
```

Necesitamos saber, de cada una, **el ensamblado, la clase y el método** que recibe los mensajes. Si alguna hoy está hecha como API, hay que agregarle ese método: una lambda tiene un solo punto de entrada, y una API no entiende el evento de la cola.

#### 6. ¿API-MAESTROS API corre con un scheduler o solo por el API Gateway?

`master-data-sync` va a buscar productos, compañías, marcas y campañas al API Delosi. Hoy está expuesta en el gateway, en `/master-data-sync`: corre cuando alguien la llama.

Si además tiene que correr **sola por horario**, por ejemplo todos los días a las 6:00, se agrega un scheduler. Pero ojo: como hoy es una API, no entiende el evento del scheduler. Haría falta una segunda lambda con el mismo código y un handler de scheduler, como hace `menu-sync` en `api-delosi-integration-infrastructure`.

Necesitamos saber si aplica y, si sí, a qué hora.

---

### DevOps

#### 7. Red de las lambdas

Las lambdas corren dentro de una VPC. De esa red depende a qué pueden llegar. Necesitan alcance a:

- El **PostgreSQL** de Alfie (BD Facturación, BD Vales, BD Maestros).
- **Secrets Manager**, para leer sus secretos al arrancar.
- **Internet** por NAT, para el IDP de JWT, SAP PI, el API Delosi y Micros.

Hoy los IDs están **copiados de `api-delosi-integration-infrastructure`**, sin verificar. Necesitamos, por ambiente:

- `vpc_id`
- `subnet_id1` y `subnet_id2` (privadas, con NAT)
- `security_group_id` (con salida al Postgres por el 5432)

Se cambian en `environments/{env}.tfvars`.

#### 8. Buckets del state de Terraform

Terraform guarda el registro de lo que creó en un bucket de S3. **Ese bucket tiene que existir antes del primer despliegue**: si no, el pipeline falla en `terraform init`.

Nombre provisional, uno por ambiente:

```
terraform-bucket-delosi-alfie-dev
terraform-bucket-delosi-alfie-prd
```

Se cambian en `backend-configs/backend-{env}.tfvars`.

#### 9. Crear los secretos

Ninguna credencial está en el repo. Cada lambda lee dos secretos de Secrets Manager al arrancar, y Terraform solo le pasa el nombre y le da permiso de lectura. Los secretos hay que crearlos a mano, con esta convención:

```
delosi-alfie-{env}/{lambda}-db    → conexión a la base
delosi-alfie-{env}/{lambda}-app   → JWT y demás configuración sensible
```

Por ejemplo, para facturas en dev:

`delosi-alfie-dev/invoicing-invoices-db`
```json
{
  "ConnectionStrings__Postgres": "Host=...;Port=5432;Database=invoicing_db;Username=...;Password=..."
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

Son dos por lambda y por ambiente. La lista completa de nombres está en `environments/{env}.tfvars`. Las claves de cada secreto dependen de lo que lea el código de cada lambda.

#### 10. Permiso para enviar mensajes a SQS

La receta de lambda da permiso para **leer** una cola, pero no para **escribir**. `invoicing-approvals` y `voucher-management` necesitan enviar mensajes (punto 4) y, sin ese permiso, AWS les responde `AccessDenied`. Hace falta agregar la opción a la receta o definir cómo darlo.

#### 11. Cómo se autentica Micros

Micros llama a `/voucher-redemption` por HTTPS pero no tiene el JWT de Active Directory. Hoy la ruta va abierta en el gateway. Hay que definir con el equipo de Micros si manda una API key u otra credencial, y con eso se ajusta el método en `apigateway.tf`.

#### 12. Verificar el remitente en SES

`invoicing-notifications` ya tiene permiso para enviar correos por SES, pero SES solo envía desde un **dominio o correo verificado**. Hay que verificarlo en la cuenta.

---


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
| `/voucher-redemption` | voucher-redemption (la llama Micros) |

Cada ruta base debe coincidir con el prefijo de rutas de la app dentro de la lambda: el gateway le pasa el path completo, por ejemplo `/facturas/listar`. Solo `/facturas` está verificado contra el código.

No se exponen `invoicing-sap-sync`, `document-generation`, `audit` ni `invoicing-notifications`: las dispara SQS, no una llamada HTTP. El Authorizer es externo; los métodos van con `authorization = NONE` y cada lambda valida su JWT. La URL base sale en `terraform output api_invoke_url`.

`/voucher-redemption` la llama Micros, que no tiene JWT. Por ahora va abierta como las demás; cómo se autentica está por definir (punto 11).

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

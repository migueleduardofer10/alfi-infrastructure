# Pendientes antes del primer despliegue

Lo que falta para poder desplegar [ventasCorp-infrastructure](README.md). Cada punto dice quién lo resuelve y en qué archivo se aplica.

Faltan datos que este repo no puede inventar. Mientras no estén, los valores son supuestos y van marcados con `A CONFIRMAR` en el código.

### Equipo de Alfie

**1. Confirmar la ruta base y el handler de cada lambda.** Solo API-FACTURAS está verificada contra el código; el resto son supuestos. Cada equipo revisa su fila y dice si está bien o qué hay que corregir.

- **Ruta base**: el prefijo con el que empiezan los endpoints de la app, el `MapGroup`. Si no coincide, el gateway responde 404. Se corrige en el `path_part` de `apigateway.tf`.
- **Handler**: en las APIs es el `AssemblyName` del `.csproj` que se despliega, el mismo valor que `function-handler` en `aws-lambda-tools-defaults.json`. En las de cola y la de scheduler es `Ensamblado::Namespace.Clase::Metodo` (punto 4). Si no coincide, la lambda no arranca. Se corrige en `lambdas.tf`.

Lambdas de API:

| Lambda (diagrama) | Repo | Ruta base | Handler |
|:--|:--|:--|:--|
| API-FACTURAS | api-invoicing-invoices | `/facturas` ✔ | `Delosi.InvoicingInvoices.Api` ✔ |
| API-CONFIG-APROBADORES | api-invoicing-config-approvers | `/config-approvers` | `Delosi.InvoicingConfigApprovers.Api` |
| API-BANDEJA-APROBACIONES | api-invoicing-approval-tray | `/approval-tray` | `Delosi.InvoicingApprovalTray.Api` |
| API-APROBACIONES | api-invoicing-approvals | `/approvals` | `Delosi.InvoicingApprovals.Api` |
| API-GESTOR | api-voucher-management | `/vouchers` | `Delosi.VoucherManagement.Api` |
| API-MODELOS | api-voucher-models | `/voucher-models` | `Delosi.VoucherModels.Api` |
| API-MOTIVOS | api-voucher-reasons | `/voucher-reasons` | `Delosi.VoucherReasons.Api` |
| API-Maestros | api-master-data-service | `/master-data` | `Delosi.MasterDataService.Api` |
| API-SYNC-VALES | api-voucher-redemption | `/voucher-redemption` (la llama Micros) | `Delosi.VoucherRedemption.Api` |

Lambdas de cola, sin ruta:

| Lambda (diagrama) | Repo | Cola | Ensamblado | Clase | Método |
|:--|:--|:--|:--|:--|:--|
| API-NOTIFICACION | api-invoicing-notifications | `notifications` | `Delosi.InvoicingNotifications` | `Delosi.InvoicingNotifications.Functions.NotificationFunction` | `FunctionHandler` |
| API-SYNC-FACTURACION | api-invoicing-sap-sync | `sap-sync` | `Delosi.InvoicingSapSync` | `Delosi.InvoicingSapSync.Functions.SapSyncFunction` | `FunctionHandler` |
| Generar PDF | api-document-generation | `document-generation` | `Delosi.DocumentGeneration` | `Delosi.DocumentGeneration.Functions.DocumentGenerationFunction` | `FunctionHandler` |

Lambda de scheduler, sin ruta:

| Lambda (diagrama) | Repo | Horario | Ensamblado | Clase | Método |
|:--|:--|:--|:--|:--|:--|
| API-MAESTROS API | api-master-data-sync | 2 veces al día | `Delosi.MasterDataSync` | `Delosi.MasterDataSync.Functions.MasterDataSyncFunction` | `FunctionHandler` |

**2. Nombre del bucket de documentos.** document-generation guarda los PDF en el bucket `delosi-ventascorp-vales-s3-{env}`, el nombre que propuso DevOps en minúsculas (S3 no acepta mayúsculas). Falta que lo creen y confirmen el nombre de stg y prd. Se cambia en `environments/{env}.tfvars`, variable `documents_bucket_name`.

**3. Nombre de la variable con la URL de la cola.** Terraform le pasa la URL de la cola a la lambda que publica, como variable de entorno:

| Lambda que publica | Variable de entorno | Cola |
|:--|:--|:--|
| invoicing-approvals | `Sqs__SapSyncQueueUrl` | `sap-sync` |
| invoicing-approvals | `Sqs__NotificationsQueueUrl` | `notifications` |
| voucher-management | `Sqs__DocumentGenerationQueueUrl` | `document-generation` |

En .NET, una variable de entorno con `__` se lee como una clave con `:`. Es decir, `Sqs__SapSyncQueueUrl` equivale a tener esto en el `appsettings.json`:

```json
{
  "Sqs": {
    "SapSyncQueueUrl": "https://sqs.us-east-1.amazonaws.com/123456789/Delosi-ventasCorp-sap-syncdev"
  }
}
```

Y el código la lee con `config["Sqs:SapSyncQueueUrl"]` o con una clase de opciones enlazada a la sección `Sqs`. En Lambda, la variable de entorno rellena ese valor.

El nombre de la variable lo propusimos nosotros. Cada equipo revisa con qué clave lee la URL de la cola y nos dice en cuál de estos casos está:

| Cómo lo tiene el código | Qué hacer |
|:--|:--|
| Lee `Sqs:SapSyncQueueUrl` | Nada, ya coincide. |
| Lee otra clave, por ejemplo `Queues:Sap` | Nos dicen cuál y cambiamos la variable en `main.tf` a `Queues__Sap`. No hace falta tocar el código. |
| Todavía no la lee | Que use `Sqs:SapSyncQueueUrl`. |

**4. Handler de las lambdas de cola y de scheduler.** Las tres lambdas de cola (notifications, sap-sync, document-generation) y la de scheduler (master-data-sync) tienen un código de entrada distinto al de una API: un método que recibe la lista de mensajes.

```csharp
namespace Delosi.InvoicingSapSync.Functions;

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

Para ese ejemplo el handler es `Delosi.InvoicingSapSync::Delosi.InvoicingSapSync.Functions.SapSyncFunction::FunctionHandler`. Los de la tabla son supuestos: cada equipo confirma el ensamblado, la clase y el método reales. Si alguna hoy está hecha como API, hay que agregarle ese método: una API no entiende el evento de la cola.

**5. Horas del scheduler de API-MAESTROS API.** master-data-sync la dispara EventBridge Scheduler, no el gateway. Corre dos veces al día; provisional a las 6:00 y 18:00 Lima. Falta confirmar las horas; se cambian en `schedule_expression` del bloque `module "master_data_sync"` en `lambdas.tf`, por ejemplo `cron(0 6,18 * * ? *)`. El handler es de scheduler, no de API (punto 4): el método recibe el JSON del evento, no un request HTTP.

### DevOps

**6. Red de las lambdas.** Los IDs de VPC, subnets y security group están copiados de `api-delosi-integration-infrastructure` sin verificar. Las lambdas necesitan llegar al PostgreSQL de Ventas Corp (puerto 5432), a Secrets Manager y a internet por NAT (IDP del JWT, SAP PI, API Delosi, Micros). Se cambian en `environments/{env}.tfvars`: `vpc_id`, `subnet_id1`, `subnet_id2`, `security_group_id`.

**7. Buckets del state de Terraform.** Terraform guarda lo que creó en un bucket S3 que **tiene que existir antes del primer despliegue**; si no, el pipeline falla en `terraform init`. Nombre provisional: `terraform-bucket-delosi-ventascorp-{env}`. Se cambia en `backend-configs/backend-{env}.tfvars`.

**8. Crear los secretos.** Dos por lambda y por ambiente, con la convención de la sección Secretos del README. La lista completa de nombres está en `environments/{env}.tfvars`.

**9. Permiso para publicar en SQS.** La receta de lambda da permiso para leer una cola, no para escribir. invoicing-approvals publica en `sap-sync` y `notifications`, y voucher-management en `document-generation`; sin ese permiso AWS responde `AccessDenied`. Hace falta agregar la opción a la receta o definir cómo darlo.

**10. Cómo se autentica Micros.** Micros llama a `/voucher-redemption` sin JWT. Hoy la ruta va abierta. Hay que definir con el equipo de Micros si manda una API key u otra credencial, y con eso se ajusta el método en `apigateway.tf`.

**11. Verificar el remitente en SES.** invoicing-notifications ya tiene permiso para enviar correos, pero SES solo envía desde un dominio o correo verificado en la cuenta.


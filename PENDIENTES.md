# Pendientes antes del primer despliegue

Lo que falta para poder desplegar [alfie-infrastructure](README.md). Cada punto dice quién lo resuelve y en qué archivo se aplica.

Faltan datos que este repo no puede inventar. Mientras no estén, los valores son supuestos y van marcados con `A CONFIRMAR` en el código.

### Equipo de Alfie

**1. Falta la lambda de auditoría.** El diagrama tiene API-AUDITORIA pero no hay repo. En Terraform está con el nombre provisional `audit`, conectada a la cola `audit`. Falta el nombre del repo y el handler de cola (punto 5). Se ajusta en el bloque `module "audit"` de `lambdas.tf`.

**2. Dar conformidad a la ruta base y el handler de cada API.** Cada equipo revisa su fila y marca si está bien o qué hay que corregir. Solo API-FACTURAS está verificada contra el código; el resto son supuestos.

- **Ruta base**: el prefijo con el que empiezan los endpoints de la app, el `MapGroup`. Si no coincide, el gateway responde 404. Se corrige en el `path_part` de `apigateway.tf`.
- **Handler**: el `AssemblyName` del `.csproj` que se despliega, el mismo valor que `function-handler` en `aws-lambda-tools-defaults.json`. Si no coincide, la lambda no arranca. Se corrige en `lambdas.tf`.

| Lambda (diagrama) | Repo | Ruta base | Handler | Conformidad |
|:--|:--|:--|:--|:--|
| API-FACTURAS | api-invoicing-invoices | `/facturas` | `Delosi.InvoicingInvoices.Api` | ✔ verificada |
| API-CONFIG-APROBADORES | api-invoicing-config-approvers | `/config-approvers` | `Delosi.InvoicingConfigApprovers.Api` | pendiente |
| API-BANDEJA-APROBACIONES | api-invoicing-approval-tray | `/approval-tray` | `Delosi.InvoicingApprovalTray.Api` | pendiente |
| API-APROBACIONES | api-invoicing-approvals | `/approvals` | `Delosi.InvoicingApprovals.Api` | pendiente |
| API-GESTOR | api-voucher-management | `/vouchers` | `Delosi.VoucherManagement.Api` | pendiente |
| API-MODELOS | api-voucher-models | `/voucher-models` | `Delosi.VoucherModels.Api` | pendiente |
| API-MOTIVOS | api-voucher-reasons | `/voucher-reasons` | `Delosi.VoucherReasons.Api` | pendiente |
| API-Maestros | api-master-data-service | `/master-data` | `Delosi.MasterDataService.Api` | pendiente |
| API-MAESTROS API | api-master-data-sync | `/master-data-sync` | `Delosi.MasterDataSync.Api` | pendiente |
| API-SYNC-VALES | api-voucher-redemption | `/voucher-redemption` | `Delosi.VoucherRedemption.Api` | pendiente |

**3. Nombre del bucket de documentos.** document-generation guarda los PDF en un bucket que hoy se llama `delosi-alfie-documents-{env}`, un nombre provisional. Falta el nombre real por ambiente. Se cambia en `environments/{env}.tfvars`, variable `documents_bucket_name`.

**4. Nombre de la variable con la URL de la cola.** Terraform le pasa la URL de la cola a la lambda que publica, como variable de entorno:

| Lambda que publica | Variable de entorno | Cola |
|:--|:--|:--|
| invoicing-approvals | `Sqs__SapSyncQueueUrl` | `sap-sync` |
| voucher-management | `Sqs__DocumentGenerationQueueUrl` | `document-generation` |

El nombre de la variable lo propusimos nosotros. Si el código ya lee la URL con otra clave, por ejemplo `config["Queues:Sap"]`, se cambia el nombre en `main.tf` a `Queues__Sap`. No hace falta tocar el código.

**5. Handler de las lambdas de cola.** Las cuatro lambdas de cola (notifications, sap-sync, document-generation, audit) tienen un código de entrada distinto al de una API: un método que recibe la lista de mensajes.

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

**6. Cola de notificaciones.** En el diagrama a API-NOTIFICACION la dispara SQS, pero no está claro qué cola. Hay que definir si consume la de envío a SAP o una cola propia donde publiquen Facturas y Vales. Con eso se agrega la cola en `sqs.tf` y el `sqs_event_sources` en `lambdas.tf`.

**7. ¿API-MAESTROS API corre por horario?** master-data-sync hoy está en el gateway, en `/master-data-sync`: corre cuando alguien la llama. Si además debe correr sola, por ejemplo todos los días a las 6:00, hace falta un scheduler. Como hoy es una API, no entiende el evento del scheduler: haría falta una segunda lambda con el mismo código y handler de scheduler, como `menu-sync` en `api-delosi-integration-infrastructure`. Falta saber si aplica y a qué hora.

### DevOps

**8. Red de las lambdas.** Los IDs de VPC, subnets y security group están copiados de `api-delosi-integration-infrastructure` sin verificar. Las lambdas necesitan llegar al PostgreSQL de Alfie (puerto 5432), a Secrets Manager y a internet por NAT (IDP del JWT, SAP PI, API Delosi, Micros). Se cambian en `environments/{env}.tfvars`: `vpc_id`, `subnet_id1`, `subnet_id2`, `security_group_id`.

**9. Buckets del state de Terraform.** Terraform guarda lo que creó en un bucket S3 que **tiene que existir antes del primer despliegue**; si no, el pipeline falla en `terraform init`. Nombre provisional: `terraform-bucket-delosi-alfie-{env}`. Se cambia en `backend-configs/backend-{env}.tfvars`.

**10. Crear los secretos.** Dos por lambda y por ambiente, con la convención de la sección Secretos del README. La lista completa de nombres está en `environments/{env}.tfvars`.

**11. Permiso para publicar en SQS.** La receta de lambda da permiso para leer una cola, no para escribir. invoicing-approvals y voucher-management publican mensajes y, sin ese permiso, AWS responde `AccessDenied`. Hace falta agregar la opción a la receta o definir cómo darlo.

**12. Cómo se autentica Micros.** Micros llama a `/voucher-redemption` sin JWT. Hoy la ruta va abierta. Hay que definir con el equipo de Micros si manda una API key u otra credencial, y con eso se ajusta el método en `apigateway.tf`.

**13. Verificar el remitente en SES.** invoicing-notifications ya tiene permiso para enviar correos, pero SES solo envía desde un dominio o correo verificado en la cuenta.


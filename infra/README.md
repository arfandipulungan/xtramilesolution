# Infrastructure as Code

Three layers. Logic is written once; each environment only supplies parameters.

| Layer | Path | Contains |
| --- | --- | --- |
| Modules | `modules/<cloud>/<component>` | One building block each (network, app-service, alb, rds, ...), secure defaults baked in |
| Stacks | `stacks/<hosting-model>` | Composition of modules for one hosting model: `azure-api` (App Service), `azure-func` (Functions), `azure-iis-vm` (IIS on Windows VM), `aws-3tier` (EC2 + ALB + RDS + S3), and the pipeline identities `azure-github-oidc` / `aws-github-oidc` |
| Live | `live/<env>/<cloud>/<app>` | `backend.tf`, `providers.tf`, `main.tf` with parameters only |

## Estate coverage

| Live root | Stack | Hosting model |
| --- | --- | --- |
| `live/<env>/azure/customer-api` | `azure-api` | .NET 8 Web API on App Service |
| `live/<env>/azure/order-events` | `azure-func` | .NET 8 isolated on Azure Functions (Elastic Premium) |
| `live/<env>/azure/legacy-portal` | `azure-iis-vm` | .NET Framework 4.8 on IIS, Windows VM |
| `live/<env>/aws/legacy-web` | `aws-3tier` | EC2 behind ALB, RDS, S3 |
| `live/<env>/{azure,aws}/github-oidc` | `*-github-oidc` | OIDC identities for the pipelines (bootstrap once by a platform admin) |

## Add something new

- **New app on an existing hosting model:** add `live/<env>/<cloud>/<new-app>/` (3 small files) that calls the stack.
- **New environment:** add `live/<new-env>/...` folders; the pipeline discovers them automatically.
- **New hosting model or cloud target:** add modules + one stack; existing apps are untouched.

## Existing (click-built) resources

The estate is brownfield. Stateful resources are **imported** with `import` blocks and
`name_overrides`; unsafe hosts and networks are **replaced** and cut over. See
[`migration/README.md`](migration/README.md) for the strategy and worked examples.

## Local checks (no cloud account needed)

```bash
cd infra/live/dev/aws/legacy-web
terraform init -backend=false && terraform validate
tflint --init --config=../../../../.tflint.hcl && tflint --config=../../../../.tflint.hcl
checkov -d . --framework terraform --config-file ../../.checkov.yaml
```

Plan and apply run only from the pipeline (`.github/workflows/infra.yml`) with OIDC identities.

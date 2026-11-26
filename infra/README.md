# Infrastructure as Code

Three layers. Logic is written once; each environment only supplies parameters.

| Layer | Path | Contains |
| --- | --- | --- |
| Modules | `modules/<cloud>/<component>` | One building block each (network, app-service, alb, rds, ...), secure defaults baked in |
| Stacks | `stacks/<hosting-model>` | Composition of modules for one hosting model (`azure-api`, `aws-3tier`) |
| Live | `live/<env>/<cloud>/<app>` | `backend.tf`, `providers.tf`, `main.tf` with parameters only |

## Add something new

- **New app on an existing hosting model:** add `live/<env>/<cloud>/<new-app>/` (3 small files) that calls the stack.
- **New environment:** add `live/<new-env>/...` folders; the pipeline discovers them automatically.
- **New hosting model or cloud target:** add modules + one stack; existing apps are untouched.

## Local checks (no cloud account needed)

```bash
cd infra/live/dev/aws/legacy-web
terraform init -backend=false && terraform validate
tflint --init --config=../../../../.tflint.hcl && tflint --config=../../../../.tflint.hcl
checkov -d . --framework terraform --config-file ../../.checkov.yaml
```

Plan and apply run only from the pipeline (`.github/workflows/infra.yml`) with OIDC identities.

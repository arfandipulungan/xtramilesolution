# Configuration management (Ansible)

Terraform creates the hosts; Ansible configures what runs inside them. The same roles also
run inside Packer when the golden images are built, so new instances start hardened.

| Playbook | Hosts (dynamic inventory, by tag `ansible_group`) | Roles |
| --- | --- | --- |
| `playbooks/windows_iis.yml` | `windows_iis`: Azure VMs from `infra/modules/azure/windows-vm` | `windows_hardening`, `patching`, `iis_baseline` |
| `playbooks/linux_app.yml` | `linux_app`: EC2 instances from `infra/modules/aws/ec2-asg` | `linux_hardening`, `patching`, `dotnet_runtime`, `cloudwatch_agent` |

- **No open management ports:** EC2 via SSM Session Manager; Windows via WinRM over HTTPS (5986) only from the runner subnet in the hub.
- **No secrets in the repo:** inventories authenticate with the pipeline's OIDC login.
- **Idempotent:** every task converges to a state; a second run reports `changed=0`. IIS only sets the site path on first creation, so configuration runs never undo a deployment.
- **Safe rollout:** `serial` keeps part of each fleet serving; runs start with `--check --diff`.

Local checks (no hosts needed):

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml -p collections
for p in playbooks/*.yml; do ansible-playbook --syntax-check -i localhost, "$p"; done
ansible-lint
```

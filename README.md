<p align="center">
  <img src="assets/wordmark.svg" alt="Rubra" width="380"/>
</p>

**Deploy — Helm chart for deploying [rubra-server](https://github.com/pm1715/rubra-server) on Kubernetes.**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)
[![Helm OCI](https://img.shields.io/badge/ghcr.io-charts%2Frubra-blue?logo=helm)](https://github.com/pm1715/rubra-deploy/pkgs/container/charts%2Frubra)

---

## Testing this chart for real (no cloud cluster needed)

```bash
./scripts/test-in-kind.sh
```

This builds the actual `rubra-server` `Dockerfile`, loads it into a throwaway [kind](https://kind.sigs.k8s.io/) (Kubernetes-in-Docker) cluster, installs this chart via Helm, waits for a healthy rollout, and port-forwards it to `localhost:8000` — a genuine end-to-end deployment test with no image registry or real cluster required. Needs `docker`, `kind`, `helm`, and `kubectl`, which the [rubra-server devcontainer/Codespace](https://github.com/pm1715/rubra-server#try-the-full-stack-now--zero-cost-zero-setup) installs automatically.

---

## Install

### From the OCI registry (recommended)

```bash
helm install rubra oci://ghcr.io/pm1715/charts/rubra --version 0.1.0
```

### From source

```bash
git clone https://github.com/pm1715/rubra-deploy
cd rubra-deploy
helm install rubra ./helm/rubra
```

This deploys `rubra-server` with a `ClusterIP` service, a persistent volume for SQLite, and liveness/readiness probes against `/api/v1/health`.

To reach it locally:

```bash
kubectl port-forward svc/rubra 8000:8000
```

---

## Configuration

Key values in [`helm/rubra/values.yaml`](helm/rubra/values.yaml):

| Value | Default | Description |
|---|---|---|
| `image.repository` | `ghcr.io/pm1715/rubra-server` | Server image |
| `image.tag` | `0.1.0` | Image tag |
| `replicaCount` | `1` | Pod replicas |
| `service.type` | `ClusterIP` | Change to `LoadBalancer` for external access |
| `ingress.enabled` | `false` | Set `true` and configure `ingress.hosts` to expose via Ingress |
| `persistence.enabled` | `true` | Persistent volume for SQLite storage |
| `persistence.size` | `5Gi` | PVC size |
| `env.RUBRA_DATABASE_URL` | unset (SQLite) | Set to a PostgreSQL URL for multi-replica deployments — SQLite does not support concurrent writers across pods |
| `secrets.apiKeySecretName` | `""` | Name of a Kubernetes Secret holding `RUBRA_API_KEY`; leave empty to run in open dev mode |

Override with `--set` or a custom values file:

```bash
helm install rubra ./helm/rubra \
  --set replicaCount=2 \
  --set env.RUBRA_DATABASE_URL="postgresql://rubra:rubra@postgres:5432/rubra" \
  --set persistence.enabled=false
```

### Enabling the API key

```bash
kubectl create secret generic rubra-api-key --from-literal=api-key=<your-key>
helm upgrade rubra ./helm/rubra --set secrets.apiKeySecretName=rubra-api-key
```

### Enabling Ingress

```bash
helm upgrade rubra ./helm/rubra \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=rubra.yourdomain.com
```

---

## Uninstall

```bash
helm uninstall rubra
```

The PVC is not deleted automatically (Helm default) — remove it manually if you want to drop stored traces:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=rubra
```

---

## Security & Code of Conduct

This repo follows the same [Security Policy](https://github.com/pm1715/rubra-sdk/blob/main/SECURITY.md) and [Code of Conduct](https://github.com/pm1715/rubra-sdk/blob/main/CODE_OF_CONDUCT.md) as rubra-sdk.

## Author

Rubra was designed and built by **Prayansh Mishra** ([@pm1715](https://github.com/pm1715) · [LinkedIn](https://www.linkedin.com/in/prayansh-mishra-02a57724b/)).

## License

Apache 2.0 — see [LICENSE](LICENSE).

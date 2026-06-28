## spot-render-infra-aws

> **PT-BR:** Módulos Terraform para provisionar a fundação AWS (VPC, EKS, buckets S3, Secrets Manager, ingress+WAF e perfis IRSA) usados pelo Spot Render. Usa backend em S3 (sem DynamoDB) e segue ambientes `dev`/`prod`.

> **EN:** Terraform modules for the AWS foundation (VPC, EKS, S3 buckets, Secrets Manager, ingress+WAF and IRSA profiles). Uses S3 backend only and provides `dev`/`prod` environments.

### Estrutura / Structure

```
terraform/
├── backend.tf
├── main.tf
├── variables.tf
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── s3-buckets/
│   ├── irsa/
│   ├── secrets/
│   └── ingress-waf/
└── environments/
    ├── dev/
    └── prod/
```

### Como usar / How to use

1. Configure o backend S3 em `terraform/backend.tf` (bucket, key, região).  
2. Ajuste variáveis em `environments/<env>/terraform.tfvars`.  
3. Execute:

```bash
cd environments/dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Pipelines

- `.github/workflows/ci.yml` roda `terraform fmt`, `validate` e `plan` em cada PR.  
- `terraform apply` permanece manual via GitHub Actions `workflow_dispatch` (com aprovação).

### Componentes provisionados

- **VPC** com subnets públicas/privadas, NAT e tags obrigatórias.  
- **EKS** (node groups `api`, `portal`, `workers`).  
- **S3 buckets**: `spot-render-input|output|error` com versionamento/lifecycle.  
- **Secrets Manager** para tokens (API, Sonar, CLI).  
- **IRSA** para API, Portal e Argo Workers acessarem S3/Secrets.  
- **Ingress + WAF** (ingress-nginx/ALB) com TLS e regras OWASP.  
- **FinOps**: node group de workers configurado como **Spot** com fallback on-demand, Cluster Autoscaler habilitado e policies para desligar nós sem jobs; os buckets Input/Error possuem lifecycle para expirar artefatos após o prazo configurado.
- **HPA** não gerado no Terraform (arquiteto via manifests Kubernetes), mas outputs expõem nomes/ARNs necessários.

### Requisitos

- Terraform >= 1.9  
- AWS CLI configurado  
- Bucket S3 para state: `spot-render-tfstate` (criar previamente)

### Próximos passos

- Preencher variáveis sensíveis via Secrets Manager.  
- Integrar este módulo aos demais repositórios (API, Portal, Argo) através dos outputs.

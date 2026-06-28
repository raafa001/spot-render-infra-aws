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

### Tecnologias e FinOps
- Terraform 1.9 + AWS provider 5.x  
- Backend apenas S3 (sem DynamoDB)  
- Node group dos workers configurado para **Spot** com fallback on-demand e Cluster Autoscaler habilitado  
- Buckets input/error com lifecycle (economia de storage) e tagging obrigatória para showback  
- Secrets Manager centralizado (facilita rotação)  
- Ingress + WAF com regras OWASP e rate limit para reduzir custos de mitigação.

### Métricas / Alertas
- Utilize o AWS Cost Explorer + CloudWatch para monitorar custo de EKS/S3 (tags `Project=spot-render`).  
- Para adicionar novos alarmes (ex.: custo > limite), defina recursos em `modules/monitoring` (a ser criado) ou use `terraform/aws_cost_anomaly_detection`.  
- Log de mudanças: habilite `terraform plan` diário (workflow) para detectar drift.

### Testes locais
1. Configure credenciais AWS apontando para uma conta sandbox.  
2. Ajuste `environments/dev/terraform.tfvars` com buckets/cluster únicos (ex.: `spot-render-dev-local`).  
3. `terraform init`, `terraform plan -var-file=terraform.tfvars`.  
4. Para clusters locais Kind/Minikube, use o repositório [`spot-render-teste-local`](https://github.com/raafa001/spot-render-teste-local) – ele provisiona namespaces equivalentes (`spot-render`, `rendering`, `monitoring`) e simula os buckets com MinIO.

### TechDocs
Consulte `docs/index.md` + `mkdocs.yml` para a versão completa usada no Backstage.

### Requisitos

- Terraform >= 1.9  
- AWS CLI configurado  
- Bucket S3 para state: `spot-render-tfstate` (criar previamente)

### Próximos passos

- Preencher variáveis sensíveis via Secrets Manager.  
- Integrar este módulo aos demais repositórios (API, Portal, Argo) através dos outputs.

# Spot Render Infra AWS – TechDocs

## Visão geral
Provisiona toda a infraestrutura na AWS: VPC, EKS, buckets S3 (input/output/error), Secrets Manager, IRSA e ingress+WAF.

## Stack
- Terraform 1.9
- Backend S3
- AWS provider 5.x

## Estrutura
```
terraform/
  main.tf
  variables.tf
  modules/
    vpc/
    eks/
    s3-buckets/
    irsa/
    secrets/
    ingress-waf/
  environments/
    dev/
    prod/
```

## FinOps
- Workers GPU usam Spot (`capacity_type = SPOT`) + Cluster Autoscaler.
- Buckets input/error com lifecycle (`var.retention_days`).
- Tags obrigatórias (`Project=spot-render`).
- Recomenda-se habilitar Savings Plans para workloads estáveis (API/Portal node groups).

## Fluxo de uso
1. Configure `terraform/backend.tf` com o bucket `spot-render-tfstate`.
2. Ajuste `terraform/environments/<env>/terraform.tfvars`.
3. `terraform init`, `terraform plan`, `terraform apply`.

## Métricas/Alertas
- Use CloudWatch (VPC Flow Logs, EKS cluster metrics) e o exporter do repositório `spot-render-observability`.
- Para novos alertas (custos, capacity), adicione módulos extras ou use AWS Budgets.

## Teste local
- Para testes sem AWS, use `spot-render-teste-local` que provisiona namespaces em Kind e simula buckets com MinIO.

## TechDocs
Publicar via TechDocs (mkdocs). `mkdocs.yml` define a navegação.

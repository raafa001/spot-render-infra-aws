# Spot Render AWS - Deploy com Ollama (Spotinho AI)

Este documento explica como configurar e deployar o Ollama (Spotinho AI) na AWS.

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              EKS Cluster                             │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │   │
│  │  │ CPU Nodes   │  │ GPU Nodes   │  │ GPU Nodes  │ │   │
│  │  │ (t3.medium) │  │ (g4dn.xl)   │  │ (g4dn.xl)  │ │   │
│  │  └─────────────┘  └──────┬──────┘  └─────┬─────┘ │   │
│  │                           │                │        │   │
│  │                    ┌──────┴──────┐         │        │   │
│  │                    │  Ollama     │         │        │   │
│  │                    │  Deployment │         │        │   │
│  │                    │  (GPU)      │         │        │   │
│  │                    └──────┬──────┘         │        │   │
│  │                           │                │        │   │
│  │                    ┌──────┴──────┐         │        │   │
│  │                    │ Ollama      │         │        │   │
│  │                    │ LoadBalancer│         │        │   │
│  │                    │ (NLB)       │         │        │   │
│  │                    └─────────────┘         │        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────┐                                            │
│  │ EFS         │◄──── Persistent Storage para Modelos       │
│  │ File System │                                            │
│  └─────────────┘                                            │
└─────────────────────────────────────────────────────────────┘
```

## Pré-requisitos

1. **AWS CLI** configurada com credentials
2. **kubectl** configurado para o cluster EKS
3. **Terraform** para provisionar infraestrutura
4. **EFS File System** criado para存储 modelos

## Passo 1: Provisionar Infraestrutura com GPU

Edite o arquivo `terraform/terraform.tfvars` com as configurações:

```hcl
name               = "spot-render"
cluster_name       = "spot-render-prod"
vpc_cidr           = "10.0.0.0/16"
az_count           = 3

node_groups = {
  general = {
    instance_type = "t3.medium"
    min_size      = 2
    max_size      = 5
    desired_size  = 2
  }
}

enable_gpu_node_group = true
gpu_instance_type    = "g4dn.xlarge"
gpu_min_size         = 0
gpu_max_size         = 2
gpu_desired_size     = 1
gpu_count            = 1

domain = "spotrender.com"
```

Execute Terraform:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Passo 2: Configurar kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name spot-render-prod
```

## Passo 3: Criar EFS para Modelos

```bash
# Criar EFS File System
EFS_ID=$(aws efs create-file-system \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --query 'FileSystemId' \
    --output text)

echo "EFS File System ID: $EFS_ID"

# Criar mount targets nas subnets privadas
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name:vpc-id,Values=VPC_ID" "Name:tag:Name,Values=*-private*" \
    --query 'Subnets[*].SubnetId' \
    --output text)

for SUBNET in $SUBNETS; do
    aws efs create-mount-target \
        --file-system-id $EFS_ID \
        --subnet-id $SUBNET \
        --security-groups SECURITY_GROUP_ID
done
```

## Passo 4: Deploy Ollama

```bash
# Deploy Ollama com EFS
EFS_FILE_SYSTEM_ID=fs-xxxxx ./scripts/deploy-ollama.sh
```

## Passo 5: Configurar Variáveis de Ambiente

### API (.env)
```bash
OLLAMA_BASE_URL=http://ollama.spot-ai.svc.cluster.local:11434
```

### Portal
```bash
NEXT_PUBLIC_OLLAMA_BASE_URL=http://ollama-loadbalancer.amazonaws.com
```

Ou configure via ConfigMap/Secret no Kubernetes.

## Modelo Padrão

O deploy baixa automaticamente `llama3.2:latest`. Para usar outro modelo:

```bash
kubectl exec -n spot-ai deploy/ollama -- ollama pull mistral:latest
```

## Verificação

```bash
# Status do Ollama
kubectl get all -n spot-ai

# Logs
kubectl logs -n spot-ai -l app=ollama -f

# Testar API
curl http://localhost:11434/api/tags
```

## Custos Estimados (AWS)

| Recurso | Tipo | Custo Mensal ( estimado) |
|---------|------|---------------------------|
| GPU Node (g4dn.xlarge) | 1x | ~$0.526/hora × 730 = ~$384 |
| EFS Storage | 50GB | ~$2.50/GB = ~$125 |
| LoadBalancer (NLB) | 1x | ~$16.50 + $0.008/GB = ~$50 |
| **Total** | | **~$559/mês** |

## Escala

### Scale-up (mais GPU por instância)
```hcl
gpu_instance_type = "g4dn.2xlarge"  # 1 GPU
gpu_count = 1
```

### Scale-out (mais instâncias)
```hcl
gpu_desired_size = 2
gpu_max_size = 4
```

## Limpeza

```bash
./scripts/cleanup-ollama.sh
```

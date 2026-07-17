#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EFS_FILE_SYSTEM_ID=${EFS_FILE_SYSTEM_ID:-""}
AWS_REGION=${AWS_REGION:-"us-east-1"}

function info() { echo "[+] $1"; }
function warn() { echo "[!] $1"; }
function require_cmd() { command -v "$1" >/dev/null || { echo "Command '$1' not found"; exit 1; }; }

require_cmd kubectl
require_cmd aws

if [[ -z "$EFS_FILE_SYSTEM_ID" ]]; then
    warn "EFS_FILE_SYSTEM_ID não definido. Procure o EFS filesystems:"
    aws efs describe-file-systems --region "$AWS_REGION" --query 'FileSystems[*].[FileSystemId,Name]' --output table
    echo ""
    read -p "Digite o EFS File System ID: " EFS_FILE_SYSTEM_ID
fi

if [[ -z "$EFS_FILE_SYSTEM_ID" ]]; then
    warn "EFS File System ID é obrigatório"
    exit 1
fi

info "Criando namespace spot-ai..."
kubectl apply -f "$REPO_ROOT/k8s/overlays/ollama-aws/ollama.yaml"

info "Ajustando StorageClass com EFS File System ID: $EFS_FILE_SYSTEM_ID"
sed "s/REPLACE_WITH_EFS_FILESYSTEM_ID/$EFS_FILE_SYSTEM_ID/g" \
    "$REPO_ROOT/k8s/overlays/ollama-aws/storageclass-efs.yaml" | \
    kubectl apply -f -

info "Baixando modelo llama3.2:latest no Ollama..."
OLLAMA_POD=$(kubectl get pods -n spot-ai -l app=ollama -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [[ -n "$OLLAMA_POD" ]]; then
    kubectl exec -n spot-ai "$OLLAMA_POD" -- ollama pull llama3.2:latest
else
    warn "Ollama pod não encontrado. O modelo será baixado quando o primeiro request chegar."
fi

info "Verificando status do Ollama..."
kubectl get all -n spot-ai

info ""
info "Ollama está configurado!"
info "  - Namespace: spot-ai"
info "  - Serviço: ollama (ClusterIP: 11434)"
info "  - LoadBalancer: ollama-loadBalancer (porta 80)"
info ""
info "Para usar via API interna:"
info "  http://ollama.spot-ai.svc.cluster.local:11434"
info ""
info "Para expor externamente (via LoadBalancer):"
info "  kubectl get svc -n spot-ai ollama-loadBalancer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"

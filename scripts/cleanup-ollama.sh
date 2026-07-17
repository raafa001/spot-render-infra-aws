#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

function info() { echo "[+] $1"; }
function warn() { echo "[!] $1"; }

info "Removendo Ollama do cluster..."
kubectl delete -f "$REPO_ROOT/k8s/overlays/ollama-aws/storageclass-efs.yaml" --ignore-not-found
kubectl delete -f "$REPO_ROOT/k8s/overlays/ollama-aws/ollama.yaml" --ignore-not-found

info "Removendo namespace spot-ai..."
kubectl delete namespace spot-ai --ignore-not-found

info "Ollama removido com sucesso!"

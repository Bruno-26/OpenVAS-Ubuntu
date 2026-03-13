#!/bin/bash

# ==================================================================
# Script: 21-update_data_feeds.sh
#
# Propósito:
# 1. Sincroniza os feeds de dados essenciais: GVMD_DATA, SCAP e CERT.
# 2. Implementa lógica de retentativa automática via rsync em caso
#    de falha na sincronização padrão.
# 3. Garante que o GVM tenha as informações mais recentes sobre
#    vulnerabilidades e conformidade.
# ==================================================================

# --- Configurações de Segurança e Estilo ---
set -e
set -o pipefail
source "$(dirname "$0")/../style.sh"

# --- Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  print_error "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Pré-requisitos ---
if ! command -v greenbone-feed-sync &> /dev/null; then
  print_error "O comando 'greenbone-feed-sync' não foi encontrado."
  print_info "Execute o script 14 primeiro."
  exit 1
fi

# --- 2. Função de Sincronização ---
sync_feed() {
  local type="$1"
  print_info "Sincronizando feed: $type..."

  if sudo -Hiu gvm greenbone-feed-sync --type "$type"; then
    print_success "Feed '$type' sincronizado com sucesso."
  else
    print_warning "Falha na sincronia inicial de '$type'. Tentando via rsync..."
    if sudo -Hiu gvm greenbone-feed-sync --type "$type" --rsync; then
      print_success "Feed '$type' sincronizado via rsync."
    else
      print_error "Falha crítica na sincronização do feed '$type'."
      exit 1
    fi
  fi
}

# --- 3. Execução ---
sync_feed "GVMD_DATA"
sync_feed "SCAP"
sync_feed "CERT"

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Sincronização de todos os feeds de dados concluída!"
echo ""
print_info " Sugestão de Automação:"
echo "   Para manter os feeds atualizados, adicione ao crontab do root:"
echo "   0 3 * * * /home/bruno/OpenVAS-Ubuntu/scripts/21-update_data_feeds.sh"
print_warning "========================================================================"

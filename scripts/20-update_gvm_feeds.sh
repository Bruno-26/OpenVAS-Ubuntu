#!/bin/bash

# ==================================================================
# Script: 20-update_gvm_feeds.sh
#
# Propósito:
# 1. Configura privilégios de sudo para o binário 'openvas'.
# 2. Sincroniza os feeds de vulnerabilidade (NVTs) com o Greenbone.
# 3. Atualiza as informações de plugins no banco de dados Redis.
# 4. Garante que as permissões de log estejam corretas após a sincronia.
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

# --- 1. Configuração do Sudo para OpenVAS ---
print_info "Configurando privilégios para o scanner..."

OPENVAS_BIN=$(which openvas || echo "/usr/local/sbin/openvas")
SUDOERS_FILE="/etc/sudoers.d/gvm"
RULE="gvm ALL = NOPASSWD: $OPENVAS_BIN"

if [ ! -f "$SUDOERS_FILE" ] || ! grep -qF "$RULE" "$SUDOERS_FILE"; then
  echo "$RULE" >> "$SUDOERS_FILE"
  chmod 440 "$SUDOERS_FILE"
  print_success "Regra de sudo adicionada para $OPENVAS_BIN."
else
  print_info "Regra de sudo já existente."
fi

# --- 2. Sincronização de NVTs ---
print_info "Iniciando sincronização de feeds (isso pode levar vários minutos)..."

if sudo -Hiu gvm greenbone-nvt-sync; then
  print_success "Sincronização concluída."
else
  print_warning "Sincronização padrão falhou. Tentando via rsync..."
  if sudo -Hiu gvm greenbone-nvt-sync --rsync; then
    print_success "Sincronização rsync concluída."
  else
    print_error "Falha crítica na sincronização dos feeds."
    exit 1
  fi
fi

# --- 3. Atualização do Redis ---
print_info "Atualizando informações de plugins no Redis..."

if sudo -Hiu gvm sudo "$OPENVAS_BIN" --update-vt-info; then
  print_success "Informações de plugins atualizadas."
else
  print_error "Falha ao atualizar o Redis."
  exit 1
fi

# --- 4. Ajustes Finais ---
print_info "Corrigindo permissões de log..."
chown -R gvm:gvm /var/log/gvm
print_success "Permissões de log corrigidas."

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Atualização de feeds NVTs concluída!"
echo ""
print_info " Resumo das Ações:"
echo "   - Sincronização com servidores da Greenbone finalizada."
echo "   - Base de dados Redis alimentada com novos plugins."
echo "   - Logs de sistema ajustados para o usuário 'gvm'."
print_warning "========================================================================"

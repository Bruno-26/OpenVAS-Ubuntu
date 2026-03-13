#!/bin/bash

# ==================================================================
# Script: 26-set_feed_owner.sh
#
# Propósito:
# 1. Define o usuário proprietário para a importação de feeds (NVTs/SCAP/CERT).
# 2. Garante que as configurações de escaneamento do feed sejam
#    visíveis e utilizáveis pelo manager.
# 3. Vincula o UUID do usuário 'admin' à configuração global.
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

# --- 1. Definições ---
FEED_USER="admin"
GVMD_BIN="/usr/local/sbin/gvmd"
SETTING_UUID="78eceaec-3385-11ea-b237-28d24461215b"

print_info "Buscando UUID do usuário '$FEED_USER'..."

USER_LINE=$(sudo -Hiu gvm "$GVMD_BIN" --get-users --verbose | grep "^${FEED_USER} " || true)

if [ -z "$USER_LINE" ]; then
  print_error "Usuário '$FEED_USER' não encontrado no GVM."
  exit 1
fi

USER_UUID=$(echo "$USER_LINE" | awk '{print $2}')
print_info "UUID detectado: $USER_UUID"

# --- 2. Aplicação ---
print_info "Configurando Feed Import Owner..."

if sudo -Hiu gvm "$GVMD_BIN" --modify-setting "$SETTING_UUID" --value "$USER_UUID"; then
  print_success "Configuração aplicada com sucesso."
else
  print_error "Falha ao modificar configuração global."
  exit 1
fi

# --- 3. Verificação ---
CUR_VAL=$(sudo -Hiu gvm "$GVMD_BIN" --get-setting "$SETTING_UUID" | grep -oP '(?<=Value: ).*' || true)

if [ "$CUR_VAL" == "$USER_UUID" ]; then
  print_success "Verificação de UUID concluída e correta."
else
  print_warning "Valor atual ($CUR_VAL) diverge do esperado ($USER_UUID)."
fi

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Proprietário do feed configurado!"
echo ""
print_info " Resumo das Ações:"
echo "   - Usuário '$FEED_USER' definido como gestor dos feeds."
echo "   - Permissões de importação de recursos vinculadas."
print_warning "========================================================================"

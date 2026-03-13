#!/bin/bash

# ==================================================================
# Script: 19-set_gvm_permissions.sh
#
# Propósito:
# 1. Garante que todos os diretórios de dados, logs e sockets
#    do GVM existam.
# 2. Define as permissões de propriedade (gvm:gvm) necessárias
#    para a operação correta dos daemons.
# 3. Corrige permissões recursivamente em locais sensíveis.
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

# --- 1. Verificações Iniciais ---
print_info "Validando usuário e grupo 'gvm'..."

GVM_USER="gvm"
GVM_GROUP="gvm"

if ! id "$GVM_USER" &>/dev/null; then
  print_error "O usuário '$GVM_USER' não existe. Execute o script 04 primeiro."
  exit 1
fi

if ! getent group "$GVM_GROUP" &>/dev/null; then
  print_error "O grupo '$GVM_GROUP' não existe."
  exit 1
fi

print_success "Ambiente validado."

# --- 2. Gestão de Diretórios ---
print_info "Garantindo estrutura de diretórios do GVM..."

DIRS=(
  "/var/lib/gvm"
  "/var/lib/openvas"
  "/var/lib/notus"
  "/var/log/gvm"
  "/run/gvmd"
)

for dir in "${DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    print_info "Diretório criado: $dir"
  fi
done

# --- 3. Ajuste de Propriedade ---
print_info "Definindo permissões de propriedade para $GVM_USER:$GVM_GROUP..."

chown -R "${GVM_USER}:${GVM_GROUP}" "${DIRS[@]}"
print_success "Propriedade recursiva aplicada com sucesso."

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Permissões configuradas com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - Estrutura de diretórios em /var e /run garantida."
echo "   - Usuário 'gvm' definido como proprietário de todos os locais."
echo "   - Permissões preparadas para o início dos serviços."
print_warning "========================================================================"

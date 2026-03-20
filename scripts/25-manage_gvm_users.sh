#!/bin/bash

# ==================================================================
# Script: 25-manage_gvm_users.sh
#
# Propósito:
# 1. Cria automaticamente o usuário administrador padrão 'admin'
#    com senha aleatória gerada pelo gvmd.
# 2. Exibe a senha gerada ao final do script para que o
#    administrador possa anotá-la.
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

GVMD_BIN="/usr/local/sbin/gvmd"
DEFAULT_USER="admin"

if [ ! -x "$GVMD_BIN" ]; then
  print_error "Executável gvmd não encontrado em '$GVMD_BIN'."
  exit 1
fi

# --- Função Auxiliar ---
user_exists() {
  sudo -Hiu gvm "$GVMD_BIN" --get-users --verbose 2>/dev/null | grep -q "^$1 "
}

# --- Criação do Usuário Admin ---
print_info "Verificando se o usuário 'admin' já existe..."

if user_exists "$DEFAULT_USER"; then
  print_warning "O usuário '$DEFAULT_USER' já existe no sistema."
  print_info "Se precisar alterar a senha, use a ferramenta: ./gvm_user_manager_tool.sh"
  echo ""
else
  print_info "Criando usuário '$DEFAULT_USER' com senha aleatória..."

  # Captura a saída completa do comando
  CREATE_OUTPUT=$(sudo -Hiu gvm "$GVMD_BIN" --create-user="$DEFAULT_USER" 2>&1)

  # Extrai a senha gerada (formato: "User created with password 'SENHA'.")
  ADMIN_PASSWORD=$(echo "$CREATE_OUTPUT" | grep -oP "(?<=password ').*(?=')")

  if [ -n "$ADMIN_PASSWORD" ]; then
    echo ""
    print_success "Usuário '$DEFAULT_USER' criado com sucesso!"
    echo ""
    print_warning "========================================================================"
    print_warning "  CREDENCIAIS DO USUÁRIO ADMINISTRADOR"
    print_warning "========================================================================"
    echo ""
    printf "  %-15s: %s\n" "Usuário" "$DEFAULT_USER"
    printf "  %-15s: %s\n" "Senha" "$ADMIN_PASSWORD"
    echo ""
    print_warning "========================================================================"
    print_info "  IMPORTANTE: Anote estas credenciais em local seguro!"
    print_info "  Para gerenciar usuários posteriormente, use: ./gvm_user_manager_tool.sh"
    print_warning "========================================================================"
    echo ""
  else
    print_error "Falha ao criar o usuário '$DEFAULT_USER'."
    print_info "Saída do comando:"
    echo "$CREATE_OUTPUT"
    exit 1
  fi
fi

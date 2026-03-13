#!/bin/bash

# ==================================================================
# Script: 25-manage_gvm_users.sh
#
# Propósito:
# 1. Menu interativo para gestão de usuários do GVM.
# 2. Criação do usuário administrador padrão 'admin'.
# 3. Criação de novos usuários com senhas personalizadas.
# 4. Alteração de senhas de usuários existentes.
# ==================================================================

# --- Configurações de Segurança e Estilo ---
# Nota: set -e não é usado aqui para permitir que o menu continue em caso de erro de digitação
source "$(dirname "$0")/../style.sh"

# --- Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  print_error "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

GVMD_BIN="/usr/local/sbin/gvmd"
DEFAULT_USER="admin"

if [ ! -x "$GVMD_BIN" ]; then
  print_error "Executável gvmd não encontrado."
  exit 1
fi

# --- Funções Auxiliares ---
user_exists() {
  sudo -Hiu gvm "$GVMD_BIN" --get-users --verbose | grep -q "^$1 "
}

# --- Menu Principal ---
while true; do
  echo ""
  print_warning "------------------------------------------------------------"
  print_info "       Menu de Gerenciamento de Usuários GVM"
  print_warning "------------------------------------------------------------"
  echo "  1. Criar usuário 'admin' padrão (senha aleatória)"
  echo "  2. Criar novo usuário (senha personalizada)"
  echo "  3. Alterar senha de usuário existente"
  echo "  4. Sair"
  print_warning "------------------------------------------------------------"
  read -p "  Escolha uma opção [1-4]: " choice

  case $choice in
    1)
      print_info "Criando usuário 'admin'..."
      if user_exists "$DEFAULT_USER"; then
        print_warning "Usuário '$DEFAULT_USER' já existe. Use a opção 3."
      else
        sudo -Hiu gvm "$GVMD_BIN" --create-user="$DEFAULT_USER"
        print_success "Usuário '$DEFAULT_USER' criado."
      fi
      ;;
    2)
      read -p "  Nome do novo usuário: " new_user
      if [ -z "$new_user" ]; then print_error "Nome vazio."; continue; fi
      
      if user_exists "$new_user"; then
        print_warning "Usuário já existe."
      else
        read -s -p "  Senha para '$new_user': " p1; echo ""
        read -s -p "  Confirme a senha: " p2; echo ""
        if [ "$p1" == "$p2" ]; then
          sudo -Hiu gvm "$GVMD_BIN" --create-user="$new_user" --password="$p1"
          print_success "Usuário '$new_user' criado."
        else
          print_error "Senhas não coincidem."
        fi
      fi
      ;;
    3)
      read -p "  Nome do usuário: " user
      if user_exists "$user"; then
        read -s -p "  Nova senha para '$user': " p1; echo ""
        read -s -p "  Confirme a senha: " p2; echo ""
        if [ "$p1" == "$p2" ]; then
          sudo -Hiu gvm "$GVMD_BIN" --user="$user" --new-password="$p1"
          print_success "Senha alterada com sucesso."
        else
          print_error "Senhas não coincidem."
        fi
      else
        print_error "Usuário não encontrado."
      fi
      ;;
    4)
      print_info "Saindo..."
      break
      ;;
    *)
      print_error "Opção inválida."
      ;;
  esac
done

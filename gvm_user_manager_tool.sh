#!/bin/bash

# ==================================================================
# Script: gvm_user_manager_tool.sh
#
# Propósito:
# Ferramenta interativa para gerenciamento de usuários do GVM.
# - Criação de novos usuários com senhas personalizadas
# - Alteração de senhas de usuários existentes
# - Listagem de usuários cadastrados
# ==================================================================

# --- Configurações de Segurança e Estilo ---
# Nota: set -e não é usado aqui para permitir que o menu continue em caso de erro de digitação
source "$(dirname "$0")/style.sh"

# --- Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  print_error "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

GVMD_BIN="/usr/local/sbin/gvmd"

if [ ! -x "$GVMD_BIN" ]; then
  print_error "Executável gvmd não encontrado em '$GVMD_BIN'."
  print_info "Certifique-se de que o GVM está instalado corretamente."
  exit 1
fi

# --- Funções Auxiliares ---
user_exists() {
  sudo -Hiu gvm "$GVMD_BIN" --get-users --verbose 2>/dev/null | grep -q "^$1 "
}

list_users() {
  echo ""
  print_info "Listando usuários cadastrados no GVM:"
  echo ""
  sudo -Hiu gvm "$GVMD_BIN" --get-users --verbose 2>/dev/null || print_error "Falha ao listar usuários."
  echo ""
}

# --- Menu Principal ---
while true; do
  echo ""
  print_warning "============================================================"
  print_info "       Ferramenta de Gerenciamento de Usuários GVM"
  print_warning "============================================================"
  echo "  1. Listar todos os usuários"
  echo "  2. Criar novo usuário (senha personalizada)"
  echo "  3. Alterar senha de usuário existente"
  echo "  4. Criar usuário 'admin' (senha aleatória)"
  echo "  5. Sair"
  print_warning "============================================================"
  read -p "  Escolha uma opção [1-5]: " choice

  case $choice in
    1)
      list_users
      ;;
    2)
      echo ""
      read -p "  Nome do novo usuário: " new_user
      if [ -z "$new_user" ]; then
        print_error "Nome vazio."
        continue
      fi

      if user_exists "$new_user"; then
        print_warning "Usuário '$new_user' já existe."
      else
        read -s -p "  Senha para '$new_user': " p1; echo ""
        read -s -p "  Confirme a senha: " p2; echo ""
        if [ "$p1" == "$p2" ]; then
          sudo -Hiu gvm "$GVMD_BIN" --create-user="$new_user" --password="$p1"
          print_success "Usuário '$new_user' criado com sucesso."
        else
          print_error "Senhas não coincidem."
        fi
      fi
      ;;
    3)
      echo ""
      read -p "  Nome do usuário: " user
      if [ -z "$user" ]; then
        print_error "Nome vazio."
        continue
      fi

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
        print_error "Usuário '$user' não encontrado."
      fi
      ;;
    4)
      echo ""
      print_info "Criando usuário 'admin' com senha aleatória..."
      if user_exists "admin"; then
        print_warning "Usuário 'admin' já existe. Use a opção 3 para alterar a senha."
      else
        ADMIN_PASSWORD=$(sudo -Hiu gvm "$GVMD_BIN" --create-user="admin" 2>&1 | grep -oP "(?<=password ').*(?=' generated)")
        if [ -n "$ADMIN_PASSWORD" ]; then
          echo ""
          print_success "Usuário 'admin' criado com sucesso!"
          print_warning "============================================================"
          print_warning " SENHA DO USUÁRIO 'admin': $ADMIN_PASSWORD"
          print_warning "============================================================"
          print_info "IMPORTANTE: Anote esta senha em local seguro!"
          echo ""
        else
          print_error "Falha ao criar o usuário 'admin'."
        fi
      fi
      ;;
    5)
      echo ""
      print_info "Saindo da ferramenta de gerenciamento de usuários."
      break
      ;;
    *)
      print_error "Opção inválida. Escolha uma opção entre 1 e 5."
      ;;
  esac
done

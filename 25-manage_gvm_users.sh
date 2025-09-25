#!/bin/bash

# ==================================================================
# Script interativo para gerenciar usuários administradores do GVM.
#
# O que ele faz:
# 1. Permite criar o usuário 'admin' padrão com senha aleatória.
# 2. Permite criar um novo usuário com nome e senha personalizados.
# 3. Permite alterar a senha de um usuário existente.
# 4. Usa 'read -s' para ocultar a digitação da senha.
# 5. Valida se os usuários já existem para evitar erros.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Definições e Pré-requisitos ---
GVMD_CMD="/usr/local/sbin/gvmd"
DEFAULT_USER="admin"

if ! [ -x "$GVMD_CMD" ]; then
    echo "ERRO: O executável '$GVMD_CMD' não foi encontrado. A instalação do gvmd pode ter falhado."
    exit 1
fi

# --- Funções Auxiliares ---

# Função para verificar se um usuário existe
user_exists() {
    local username="$1"
    sudo -Hiu gvm "$GVMD_CMD" --get-users --verbose | grep -q "^$username "
    return $?
}

# --- Menu Principal ---
while true; do
    echo ""
    echo "----------------------------------------"
    echo "  Menu de Gerenciamento de Usuários GVM"
    echo "----------------------------------------"
    echo "1. Criar usuário 'admin' padrão (com senha aleatória)"
    echo "2. Criar um novo usuário (com senha personalizada)"
    echo "3. Alterar a senha de um usuário existente"
    echo "4. Sair"
    echo "----------------------------------------"
    read -p "Escolha uma opção [1-4]: " choice

    case $choice in
        1)
            echo ""
            echo "--- Criando usuário 'admin' padrão ---"
            if user_exists "$DEFAULT_USER"; then
                echo "AVISO: O usuário '$DEFAULT_USER' já existe. Use a opção 3 para alterar a senha."
            else
                echo "Criando o usuário '$DEFAULT_USER'. A senha gerada será exibida abaixo:"
                sudo -Hiu gvm "$GVMD_CMD" --create-user="$DEFAULT_USER"
            fi
            ;;
        2)
            echo ""
            echo "--- Criando um novo usuário ---"
            read -p "Digite o nome do novo usuário: " new_user
            if [ -z "$new_user" ]; then
                echo "ERRO: O nome de usuário não pode ser vazio."
                continue
            fi
            if user_exists "$new_user"; then
                echo "AVISO: O usuário '$new_user' já existe."
            else
                read -s -p "Digite a senha para '$new_user': " new_pass
                echo ""
                read -s -p "Confirme a senha: " new_pass_confirm
                echo ""
                if [ "$new_pass" != "$new_pass_confirm" ]; then
                    echo "ERRO: As senhas não coincidem."
                else
                    echo "Criando o usuário '$new_user'..."
                    sudo -Hiu gvm "$GVMD_CMD" --create-user="$new_user" --password="$new_pass"
                    echo "Usuário '$new_user' criado com sucesso."
                fi
            fi
            ;;
        3)
            echo ""
            echo "--- Alterando a senha de um usuário existente ---"
            read -p "Digite o nome do usuário a ser modificado: " existing_user
            if [ -z "$existing_user" ]; then
                echo "ERRO: O nome de usuário não pode ser vazio."
                continue
            fi
            if ! user_exists "$existing_user"; then
                echo "ERRO: O usuário '$existing_user' não foi encontrado."
            else
                read -s -p "Digite a NOVA senha para '$existing_user': " new_pass
                echo ""
                read -s -p "Confirme a NOVA senha: " new_pass_confirm
                echo ""
                if [ "$new_pass" != "$new_pass_confirm" ]; then
                    echo "ERRO: As senhas não coincidem."
                else
                    echo "Alterando a senha para o usuário '$existing_user'..."
                    sudo -Hiu gvm "$GVMD_CMD" --user="$existing_user" --new-password="$new_pass"
                    echo "Senha para '$existing_user' alterada com sucesso."
                fi
            fi
            ;;
        4)
            echo "Saindo."
            exit 0
            ;;
        *)
            echo "Opção inválida. Por favor, tente novamente."
            ;;
    esac
done

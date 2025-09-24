#!/bin/bash

# ==================================================================
# Script para criar e definir a propriedade correta para os
# diretórios de dados, logs e sockets do GVM.
#
# O que ele faz:
# 1. Verifica se está sendo executado como root.
# 2. Valida se o usuário e o grupo 'gvm' existem.
# 3. Garante que todos os diretórios necessários existam.
# 4. Define recursivamente a propriedade de todos os diretórios
#    para 'gvm:gvm'.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Definições e Validações ---
GVM_USER="gvm"
GVM_GROUP="gvm"

echo "--- Verificando pré-requisitos ---"
# Valida se o usuário gvm existe
if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado. Execute os scripts de criação de usuário primeiro."
    exit 1
fi

# Valida se o grupo gvm existe
if ! getent group "$GVM_GROUP" &>/dev/null; then
    echo "ERRO: O grupo '$GVM_GROUP' não foi encontrado."
    exit 1
fi
echo "Usuário e grupo '$GVM_USER' encontrados."
echo ""

# Define um array com todos os diretórios que precisam ser gerenciados
GVM_DIRS=(
    "/var/lib/gvm"
    "/var/lib/openvas"
    "/var/lib/notus"
    "/var/log/gvm"
    "/run/gvmd"
)

# --- 2. Criação dos Diretórios ---
echo "--- Garantindo a existência dos diretórios necessários ---"
for dir in "${GVM_DIRS[@]}"; do
    echo "Verificando/criando o diretório '$dir'..."
    mkdir -p "$dir"
done
echo ""

# --- 3. Definição da Propriedade ---
echo "--- Definindo a propriedade correta para os diretórios ---"
# O comando chown pode receber múltiplos diretórios de uma vez
chown -R "${GVM_USER}:${GVM_GROUP}" "${GVM_DIRS[@]}"

if [ $? -eq 0 ]; then
    echo "Propriedade de todos os diretórios foi definida com sucesso para ${GVM_USER}:${GVM_GROUP}."
else
    echo "ERRO: Falha ao definir a propriedade dos diretórios. Verifique as permissões."
    exit 1
fi
echo ""

# --- Conclusão ---
echo "================================================="
echo " Permissões dos diretórios GVM configuradas!"
echo "================================================="

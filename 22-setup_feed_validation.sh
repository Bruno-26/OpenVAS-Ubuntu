#!/bin/bash

# ==================================================================
# Script para configurar a chave GnuPG para validação dos Feeds GVM.
#
# O que ele faz:
# 1. Baixa a chave de assinatura da Greenbone Community.
# 2. Cria o diretório GnuPG para o GVM.
# 3. Importa a chave de assinatura.
# 4. Define a confiança (ownertrust) da chave como máxima (nível 6).
# 5. Define a propriedade correta para o diretório GnuPG.
# 6. Verifica se a chave foi importada com sucesso.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Definições e Validações ---
GVM_USER="gvm"
GVM_GROUP="gvm"
GPG_HOMEDIR="/etc/openvas/gnupg"
KEY_URL="https://www.greenbone.net/GBCommunitySigningKey.asc"
KEY_FILE="/tmp/GBCommunitySigningKey.asc"
KEY_FINGERPRINT="8AE4BE429B60A59B311C2E739823FAA60ED1E580"

echo "--- Verificando pré-requisitos ---"
if ! id -u "$GVM_USER" &>/dev/null || ! getent group "$GVM_GROUP" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' ou o grupo '$GVM_GROUP' não foi encontrado."
    exit 1
fi
echo "Usuário e grupo '$GVM_USER' encontrados."
echo ""

# --- 2. Baixando e Importando a Chave ---
echo "--- Baixando e importando a chave de assinatura ---"

echo "1. Criando o diretório GnuPG em '$GPG_HOMEDIR'..."
mkdir -p "$GPG_HOMEDIR"

echo "2. Baixando a chave de assinatura de '$KEY_URL'..."
# -O especifica o arquivo de saída
wget -q "$KEY_URL" -O "$KEY_FILE"
if [ $? -ne 0 ]; then
    echo "ERRO: Falha ao baixar a chave de assinatura."
    exit 1
fi

echo "3. Importando a chave para o diretório GnuPG..."
gpg --homedir="$GPG_HOMEDIR" --import "$KEY_FILE"

# Limpa o arquivo da chave baixado, independentemente do sucesso da importação
rm "$KEY_FILE"
echo ""

# --- 3. Configurando a Confiança da Chave ---
echo "--- Configurando a confiança (ownertrust) da chave ---"
echo "1. Definindo a confiança da chave para o nível 6 (máximo)..."
# O formato é FINGERPRINT:NÍVEL_DE_CONFIANÇA:
# Nível 6 significa que você confia absolutamente nesta chave.
echo "${KEY_FINGERPRINT}:6:" | gpg --import-ownertrust --homedir="$GPG_HOMEDIR"
echo ""

# --- 4. Definindo Permissões ---
echo "--- Definindo as permissões do diretório GnuPG ---"
chown -R "${GVM_USER}:${GVM_GROUP}" "$GPG_HOMEDIR"
echo "Propriedade do diretório '$GPG_HOMEDIR' definida para ${GVM_USER}:${GVM_GROUP}."
echo ""

# --- 5. Verificação Final ---
echo "--- Verificando a instalação da chave ---"
echo "Listando as chaves como o usuário '$GVM_USER':"
# Executa o comando e armazena a saída para análise
KEY_LIST=$(sudo -Hiu gvm gpg --homedir="$GPG_HOMEDIR" --list-keys)
echo "$KEY_LIST"

# Verifica se a chave "Greenbone Community" está na lista
if echo "$KEY_LIST" | grep -q "Greenbone Community"; then
    echo ""
    echo "SUCESSO: A chave foi importada e está visível para o usuário 'gvm'."
else
    echo ""
    echo "AVISO: A chave foi importada, mas não foi possível confirmar sua presença na lista de chaves do usuário 'gvm'."
fi
echo ""

# --- Conclusão ---
echo "================================================="
echo " Configuração da chave de validação concluída!"
echo "================================================="

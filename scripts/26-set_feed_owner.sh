#!/bin/bash

# ==================================================================
# Script para definir o "Feed Import Owner" no GVM.
#
# O que ele faz:
# 1. Procura o UUID do usuário administrador especificado (padrão 'admin').
# 2. Define esse UUID como o proprietário para a importação de
#    recursos do feed (ex: configurações de escaneamento).
# 3. Verifica se a configuração foi aplicada com sucesso.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Definições e Pré-requisitos ---

# <<<<---- CONFIGURE O USUÁRIO QUE SERÁ O PROPRIETÁRIO AQUI ---->>>>
FEED_OWNER_USER="admin"
# <<<<--------------------------------------------------------->>>>

GVMD_CMD="/usr/local/sbin/gvmd"
SETTING_UUID="78eceaec-3385-11ea-b237-28d24461215b" # UUID para 'feed_import_owner'

echo "--- Verificando pré-requisitos ---"
if ! [ -x "$GVMD_CMD" ]; then
    echo "ERRO: O executável '$GVMD_CMD' não foi encontrado. A instalação do gvmd pode ter falhado."
    exit 1
fi
echo "Executável '$GVMD_CMD' encontrado."
echo ""

# --- 2. Extração do UUID do Usuário ---
echo "--- Definindo o Proprietário de Importação do Feed para o usuário: '$FEED_OWNER_USER' ---"

echo "1. Procurando pelo UUID do usuário '$FEED_OWNER_USER'..."
# Executa o comando para obter a lista de usuários e filtra pelo nome do usuário
USER_LINE=$(sudo -Hiu gvm "$GVMD_CMD" --get-users --verbose | grep "^${FEED_OWNER_USER} ")

# Verifica se o usuário foi encontrado
if [ -z "$USER_LINE" ]; then
    echo "ERRO: O usuário '$FEED_OWNER_USER' não foi encontrado no GVM."
    echo "Por favor, crie o usuário primeiro ou configure um usuário existente no script."
    exit 1
fi

# Extrai o UUID (a segunda coluna)
USER_UUID=$(echo "$USER_LINE" | awk '{print $2}')

if [ -z "$USER_UUID" ]; then
    echo "ERRO: O usuário '$FEED_OWNER_USER' foi encontrado, mas não foi possível extrair seu UUID."
    exit 1
fi

echo "   - UUID encontrado: $USER_UUID"
echo ""

# --- 3. Modificação da Configuração ---
echo "--- Aplicando a configuração ---"
echo "1. Definindo o UUID do proprietário na configuração do gvmd..."

if sudo -Hiu gvm "$GVMD_CMD" --modify-setting "$SETTING_UUID" --value "$USER_UUID"; then
    echo "   - Comando de modificação executado com sucesso."
else
    echo "   - ERRO: O comando para modificar a configuração falhou."
    exit 1
fi
echo ""

# --- 4. Verificação Final ---
echo "--- Verificando se a configuração foi aplicada corretamente ---"
# Obtém o valor atual da configuração
CURRENT_VALUE=$(sudo -Hiu gvm "$GVMD_CMD" --get-setting "$SETTING_UUID" | awk -F"Value: " '{print $2}')

echo "Valor esperado: $USER_UUID"
echo "Valor atual:    $CURRENT_VALUE"

if [ "$CURRENT_VALUE" == "$USER_UUID" ]; then
    echo "SUCESSO: A configuração foi verificada e está correta."
else
    echo "AVISO: A verificação falhou. O valor atual não corresponde ao esperado."
fi
echo ""

# --- Conclusão ---
echo "================================================="
echo " Configuração do Feed Import Owner concluída!"
echo "================================================="

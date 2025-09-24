#!/bin/bash

# ==================================================================
# Script para criar e/ou verificar um scanner OpenVAS personalizado no GVM.
#
# O que ele faz:
# 1. Verifica se um scanner com o nome definido já existe.
# 2. Se não existir, ele o cria.
# 3. Extrai automaticamente o UUID do scanner (existente ou recém-criado).
# 4. Usa o UUID para executar o comando de verificação do scanner.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Definições e Pré-requisitos ---
# <<<<---- CONFIGURE O NOME DO SEU SCANNER AQUI ---->>>>
SCANNER_NAME="Scanner OpenVAS Principal"
# <<<<------------------------------------------->>>>

SCANNER_TYPE="OpenVAS"
SCANNER_SOCKET="/run/ospd/ospd-openvas.sock"
GVMD_CMD="/usr/local/sbin/gvmd"

echo "--- Verificando pré-requisitos ---"
if ! [ -x "$GVMD_CMD" ]; then
    echo "ERRO: O executável '$GVMD_CMD' não foi encontrado. A instalação do gvmd pode ter falhado."
    exit 1
fi
echo "Executável '$GVMD_CMD' encontrado."
echo ""

# --- 2. Obtenção ou Criação do Scanner ---
echo "--- Gerenciando o scanner: '$SCANNER_NAME' ---"
SCANNER_UUID=""

# Verifica se o scanner já existe
echo "1. Verificando se o scanner já existe..."
# `grep -w` para corresponder à palavra inteira e evitar correspondências parciais
EXISTING_SCANNER_LINE=$(sudo -Hiu gvm "$GVMD_CMD" --get-scanners | grep -w "$SCANNER_NAME")

if [ -n "$EXISTING_SCANNER_LINE" ]; then
    # Se o scanner existe, extrai seu UUID
    SCANNER_UUID=$(echo "$EXISTING_SCANNER_LINE" | awk '{print $1}')
    echo "   - Scanner encontrado com UUID: $SCANNER_UUID"
else
    # Se o scanner não existe, cria um novo
    echo "   - Scanner não encontrado. Criando um novo..."
    if sudo -Hiu gvm "$GVMD_CMD" --create-scanner="$SCANNER_NAME" --scanner-type="$SCANNER_TYPE" --scanner-host="$SCANNER_SOCKET"; then
        echo "   - Scanner criado com sucesso."
        # Agora, encontra o UUID do scanner que acabamos de criar
        SCANNER_UUID=$(sudo -Hiu gvm "$GVMD_CMD" --get-scanners | grep -w "$SCANNER_NAME" | awk '{print $1}')
        if [ -z "$SCANNER_UUID" ]; then
            echo "ERRO: O scanner foi criado, mas não foi possível encontrar seu UUID."
            exit 1
        fi
        echo "   - UUID do novo scanner extraído: $SCANNER_UUID"
    else
        echo "ERRO: Falha ao criar o scanner '$SCANNER_NAME'."
        exit 1
    fi
fi
echo ""

# --- 3. Verificação do Scanner ---
if [ -n "$SCANNER_UUID" ]; then
    echo "--- Verificando o scanner ---"
    echo "1. Executando a verificação para o scanner com UUID: $SCANNER_UUID..."
    if sudo -Hiu gvm "$GVMD_CMD" --verify-scanner="$SCANNER_UUID"; then
        echo "   - A verificação do scanner foi iniciada com sucesso."
    else
        echo "   - ERRO: Falha ao iniciar a verificação do scanner."
        exit 1
    fi
else
    echo "ERRO FATAL: Não foi possível obter um UUID para o scanner. Abortando."
    exit 1
fi
echo ""

# --- Conclusão ---
echo "================================================="
echo " Gerenciamento do scanner concluído!"
echo "================================================="

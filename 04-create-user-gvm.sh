#!/bin/bash

# ==================================================================
# Script para criar e configurar o usuário 'gvm'
#
# O que ele faz:
# 1. Verifica se está sendo executado como root.
# 2. Cria o usuário de sistema 'gvm' com home em /opt/gvm.
# 3. Cria o diretório /opt/gvm e define 'gvm' como proprietário.
# 4. Concede permissões de sudo sem senha para comandos específicos.
# 5. Valida a sintaxe do arquivo de permissões sudo para segurança.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Criação do Usuário ---
echo "--- Configurando o usuário 'gvm' ---"
if id -u gvm &>/dev/null; then
    echo "Usuário 'gvm' já existe. Pulando a criação."
else
    echo "1. Criando o usuário de sistema 'gvm' com home e arquivos de shell..."
    useradd -r -m -d /opt/gvm -c "GVM User" -s /bin/bash gvm
    echo "   - Usuário 'gvm' criado com sucesso."
fi



# --- 2. Criação do Diretório Home ---
echo "2. Configurando o diretório home /opt/gvm..."

if [ ! -d "/opt/gvm" ]; then
    mkdir /opt/gvm
    echo "   - Diretório /opt/gvm criado."
fi

chown gvm:gvm /opt/gvm
echo "   - Propriedade do diretório /opt/gvm definida para gvm:gvm."


# --- 3. Configuração de Permissões Sudo ---
SUDOERS_FILE="/etc/sudoers.d/gvm"
echo "3. Configurando permissões de sudo em $SUDOERS_FILE..."

# Cria o arquivo de configuração para o sudo
echo 'gvm ALL = NOPASSWD: /usr/bin/make install, /usr/bin/python3' > "$SUDOERS_FILE"

# Define as permissões de segurança recomendadas para arquivos sudoers
chmod 440 "$SUDOERS_FILE"

echo "   - Arquivo de permissões criado."

# --- 4. Validação do Arquivo Sudo ---
echo "4. Validando a sintaxe do arquivo sudoers (medida de segurança)..."

visudo -c -f "$SUDOERS_FILE"
if [ $? -eq 0 ]; then
    echo "   - Sintaxe do arquivo sudoers está correta."
else
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! AVISO CRÍTICO: A sintaxe do arquivo sudoers está INCORRETA !!!"
    echo "!!! Removendo o arquivo corrompido para evitar problemas.      !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    rm "$SUDOERS_FILE"
    exit 1
fi


# --- Conclusão ---
echo ""
echo "================================================="
echo "  Configuração do usuário 'gvm' concluída!"
echo "================================================="
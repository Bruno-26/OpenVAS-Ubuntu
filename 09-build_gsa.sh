#!/bin/bash

# ==================================================================
# Script para compilar e instalar o Greenbone Security Assistant (gsa)
#
# REQUISITO: A variável de ambiente GSA deve estar definida.
#
# Exemplo de uso:
#   export GSA="24.2.0"
#   sudo GSA="$GSA" ./build_gsa.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

if [ -z "$GSA" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: A variável de ambiente GSA não está definida.     !!!"
    echo "!!!                                                          !!!"
    echo "!!! Execute o script da seguinte forma:                      !!!"
    echo "!!!   sudo GSA=\"<versao>\" $0                                 !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# Define variáveis
GSA_VERSION="$GSA"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"
SOURCE_FOLDER="gsa-${GSA_VERSION}"
INSTALL_DIR="/usr/local/share/gvm/gsad/web"

if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado."
    exit 1
fi

# --- 1. Preparação do Ambiente ---
echo "--- Preparando o ambiente de compilação para gsa v${GSA_VERSION} ---"
mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de fontes '$SOURCE_DIR' está pronto."
echo ""

# --- 2. Build do Front-end (como usuário GVM) ---
echo "--- Executando o processo de build do Node.js como usuário '$GVM_USER' ---"

# Usa "Here Document" para executar o build no ambiente do usuário gvm
sudo -Hiu "$GVM_USER" GSA_VERSION="$GSA_VERSION" bash << 'EOF'
    set -e # Para o script se qualquer comando falhar

    # Carrega o NVM, Node e NPM no ambiente do shell
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Define variáveis internas
    SOURCE_DIR="$HOME/gvm-source"
    TARBALL_NAME="gsa-v${GSA_VERSION}.tar.gz"
    SOURCE_FOLDER="gsa-${GSA_VERSION}"

    cd "$SOURCE_DIR"

    echo "1. Baixando gsa versão ${GSA_VERSION}..."
    wget "https://github.com/greenbone/gsa/archive/refs/tags/v${GSA_VERSION}.tar.gz" -O "$TARBALL_NAME"

    echo "2. Extraindo o arquivo..."
    rm -rf "$SOURCE_FOLDER"
    tar xzf "$TARBALL_NAME"
    cd "$SOURCE_FOLDER"

    echo "3. Instalando dependências do Node.js com 'npm install' (isso pode levar alguns minutos)..."
    npm install

    echo "4. Executando o build de produção com 'npm run build'..."
    npm run build
EOF

# Captura o status de saída do bloco de build
BUILD_STATUS=$?

# --- 3. Instalação dos Arquivos (como root) ---
if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "--- Build concluído com sucesso. Iniciando a instalação dos arquivos web ---"

    echo "1. Criando o diretório de destino: $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"

    echo "2. Limpando o diretório de destino antigo..."
    # A sintaxe {:?} previne um 'rm -rf /*' acidental se a variável estiver vazia
    rm -rf "${INSTALL_DIR:?}/"*

    echo "3. Copiando os novos arquivos de build..."
    cp -r "$SOURCE_DIR/$SOURCE_FOLDER/build/"* "$INSTALL_DIR"

    echo "4. Ajustando permissões dos arquivos instalados..."
    chown -R gvm:gvm "$INSTALL_DIR"

    echo ""
    echo "================================================="
    echo " gsa versão ${GSA_VERSION} instalado com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de build do GSA.  !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
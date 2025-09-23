#!/bin/bash

# ==================================================================
# Script para compilar e instalar o Notus Scanner
#
# REQUISITO: A variável de ambiente NOTUS_SCANNER deve estar definida.
#
# Exemplo de uso:
#   export NOTUS_SCANNER="22.6.5"
#   sudo NOTUS_SCANNER="$NOTUS_SCANNER" ./build_notus-scanner.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

if [ -z "$NOTUS_SCANNER" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: A variável de ambiente NOTUS_SCANNER não está definida. !!!"
    echo "!!!                                                          !!!"
    echo "!!! Execute o script da seguinte forma:                      !!!"
    echo "!!!   sudo NOTUS_SCANNER=\"<versao>\" $0                       !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# --- 1. Definição de Variáveis ---
NOTUS_SCANNER_VERSION="$NOTUS_SCANNER"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"
SOURCE_FOLDER="notus-scanner-${NOTUS_SCANNER_VERSION}"

# Detecta a versão do Python para criar os caminhos de diretório corretos
PYTHON_VERSION_DIR=$(python3 -c 'import sys; print(f"python{sys.version_info.major}.{sys.version_info.minor}")')
if [ -z "$PYTHON_VERSION_DIR" ]; then
    echo "ERRO: Não foi possível determinar a versão do Python 3."
    exit 1
fi
echo "Versão do Python detectada: $PYTHON_VERSION_DIR"

if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado."
    exit 1
fi

# --- 2. Preparação do Ambiente ---
echo "--- Preparando o ambiente de compilação para notus-scanner v${NOTUS_SCANNER_VERSION} ---"
mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de fontes '$SOURCE_DIR' está pronto."
echo ""

# --- 3. Build do Pacote Python (como usuário GVM) ---
echo "--- Executando o processo de build do Python como usuário '$GVM_USER' ---"

sudo -Hiu "$GVM_USER" NOTUS_SCANNER_VERSION="$NOTUS_SCANNER_VERSION" bash << 'EOF'
    set -e # Para o script se qualquer comando falhar

    SOURCE_DIR="$HOME/gvm-source"
    TARBALL_NAME="notus-scanner-v${NOTUS_SCANNER_VERSION}.tar.gz"
    SOURCE_FOLDER="notus-scanner-${NOTUS_SCANNER_VERSION}"

    cd "$SOURCE_DIR"

    echo "1. Baixando notus-scanner versão ${NOTUS_SCANNER_VERSION}..."
    wget "https://github.com/greenbone/notus-scanner/archive/refs/tags/v${NOTUS_SCANNER_VERSION}.tar.gz" -O "$TARBALL_NAME"

    echo "2. Extraindo o arquivo..."
    rm -rf "$SOURCE_FOLDER"
    tar xzf "$TARBALL_NAME"
    cd "$SOURCE_FOLDER"

    echo "3. Criando um ambiente de build..."
    rm -rf build
    mkdir build

    echo "4. Instalando o pacote em um diretório de build local com 'pip'..."
    python3 -m pip install --user --root=./build .
EOF

# Captura o status de saída do bloco de build
BUILD_STATUS=$?

# --- 4. Instalação dos Arquivos (como root) ---
if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "--- Build concluído com sucesso. Instalando os arquivos no sistema ---"

    # Define os caminhos de origem e destino
    SOURCE_EXEC_PATH="${SOURCE_DIR}/${SOURCE_FOLDER}/build${GVM_HOME}/.local/bin/"
    DEST_EXEC_PATH="/usr/local/bin/"

    SOURCE_LIB_PATH="${SOURCE_DIR}/${SOURCE_FOLDER}/build${GVM_HOME}/.local/lib/${PYTHON_VERSION_DIR}/site-packages/"
    DEST_LIB_PATH="/usr/local/lib/${PYTHON_VERSION_DIR}/site-packages/"

    echo "1. Copiando executáveis para $DEST_EXEC_PATH..."
    # Usa um wildcard (*) para o caso de haver mais de um executável
    cp "${SOURCE_EXEC_PATH}"* "${DEST_EXEC_PATH}"

    echo "2. Criando o diretório de bibliotecas de destino: $DEST_LIB_PATH..."
    mkdir -p "$DEST_LIB_PATH"

    echo "3. Copiando os arquivos da biblioteca Python..."
    cp -r "${SOURCE_LIB_PATH}." "${DEST_LIB_PATH}"

    echo ""
    echo "================================================="
    echo " notus-scanner v${NOTUS_SCANNER_VERSION} instalado com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de build.         !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
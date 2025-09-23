#!/bin/bash

# ==================================================================
# Script para compilar e instalar o OSPD-OpenVAS
#
# REQUISITO: A variável de ambiente OSPD_OPENVAS deve estar definida.
#
# Exemplo de uso:
#   export OSPD_OPENVAS="22.8.0"
#   sudo OSPD_OPENVAS="$OSPD_OPENVAS" ./build_ospd-openvas.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

if [ -z "$OSPD_OPENVAS" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: A variável de ambiente OSPD_OPENVAS não está definida. !!!"
    echo "!!!                                                          !!!"
    echo "!!! Execute o script da seguinte forma:                      !!!"
    echo "!!!   sudo OSPD_OPENVAS=\"<versao>\" $0                        !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# --- 1. Definição de Variáveis ---
OSPD_OPENVAS_VERSION="$OSPD_OPENVAS"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"
SOURCE_FOLDER="ospd-openvas-${OSPD_OPENVAS_VERSION}"

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
echo "--- Preparando o ambiente de compilação para ospd-openvas v${OSPD_OPENVAS_VERSION} ---"
mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de fontes '$SOURCE_DIR' está pronto."
echo ""

# --- 3. Build do Pacote Python (como usuário GVM) ---
echo "--- Executando o processo de build do Python como usuário '$GVM_USER' ---"

sudo -Hiu "$GVM_USER" OSPD_OPENVAS_VERSION="$OSPD_OPENVAS_VERSION" bash << 'EOF'
    set -e # Para o script se qualquer comando falhar

    SOURCE_DIR="$HOME/gvm-source"
    TARBALL_NAME="ospd-openvas-v${OSPD_OPENVAS_VERSION}.tar.gz"
    SOURCE_FOLDER="ospd-openvas-${OSPD_OPENVAS_VERSION}"

    cd "$SOURCE_DIR"

    echo "1. Baixando ospd-openvas versão ${OSPD_OPENVAS_VERSION}..."
    wget "https://github.com/greenbone/ospd-openvas/archive/refs/tags/v${OSPD_OPENVAS_VERSION}.tar.gz" -O "$TARBALL_NAME"

    echo "2. Extraindo o arquivo..."
    rm -rf "$SOURCE_FOLDER"
    tar xzf "$TARBALL_NAME"
    cd "$SOURCE_FOLDER"

    echo "3. Criando um ambiente de build..."
    # Limpa o build antigo para garantir que está começando do zero
    rm -rf build
    mkdir build

    echo "4. Instalando o pacote em um diretório de build local com 'pip'..."
    # A flag --root faz o pip instalar os arquivos dentro de ./build como se fosse o diretório raiz
    python3 -m pip install --user --root=./build .
EOF

# Captura o status de saída do bloco de build
BUILD_STATUS=$?

# --- 4. Instalação dos Arquivos (como root) ---
if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "--- Build concluído com sucesso. Instalando os arquivos no sistema ---"

    # Define os caminhos de origem e destino
    SOURCE_EXEC_PATH="${SOURCE_DIR}/${SOURCE_FOLDER}/build${GVM_HOME}/.local/bin/ospd-openvas"
    DEST_EXEC_PATH="/usr/local/bin/"

    SOURCE_LIB_PATH="${SOURCE_DIR}/${SOURCE_FOLDER}/build${GVM_HOME}/.local/lib/${PYTHON_VERSION_DIR}/site-packages/"
    DEST_LIB_PATH="/usr/local/lib/${PYTHON_VERSION_DIR}/site-packages/"

    echo "1. Copiando o executável para $DEST_EXEC_PATH..."
    cp "$SOURCE_EXEC_PATH" "$DEST_EXEC_PATH"

    echo "2. Criando o diretório de bibliotecas de destino: $DEST_LIB_PATH..."
    mkdir -p "$DEST_LIB_PATH"

    echo "3. Copiando os arquivos da biblioteca Python..."
    # A sintaxe com /." no final garante que o *conteúdo* do diretório seja copiado
    cp -r "${SOURCE_LIB_PATH}." "${DEST_LIB_PATH}"

    echo ""
    echo "================================================="
    echo " ospd-openvas v${OSPD_OPENVAS_VERSION} instalado com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de build.         !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
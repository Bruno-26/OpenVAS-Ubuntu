#!/bin/bash

# ==================================================================
# Script para compilar e instalar o Greenbone Security Assistant Server (gsad)
#
# REQUISITO: A variável de ambiente GSAD deve estar definida.
#
# Exemplo de uso:
#   export GSAD="24.2.0"
#   sudo GSAD="$GSAD" ./build_gsad.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

if [ -z "$GSAD" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: A variável de ambiente GSAD não está definida.    !!!"
    echo "!!!                                                          !!!"
    echo "!!! Execute o script da seguinte forma:                      !!!"
    echo "!!!   sudo GSAD=\"<versao>\" $0                                !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# Define variáveis
GSAD_VERSION="$GSAD"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado."
    exit 1
fi

# --- 1. Preparação do Ambiente ---
echo "--- Preparando o ambiente de compilação para gsad v${GSAD_VERSION} ---"
mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de fontes '$SOURCE_DIR' está pronto."
echo ""

# --- 2. Execução como usuário GVM ---
echo "--- Executando o processo de compilação como usuário '$GVM_USER' ---"

# Usa "Here Document" para executar um bloco de comandos como outro usuário
# e exibir o output em tempo real.
sudo -Hiu "$GVM_USER" GSAD_VERSION="$GSAD_VERSION" bash << 'EOF'
    set -e # Para o script se qualquer comando falhar

    # Define variáveis internas
    SOURCE_DIR="$HOME/gvm-source"
    TARBALL_NAME="gsad-v${GSAD_VERSION}.tar.gz"
    SOURCE_FOLDER="gsad-${GSAD_VERSION}"

    cd "$SOURCE_DIR"

    echo "1. Baixando gsad versão ${GSAD_VERSION}..."
    wget "https://github.com/greenbone/gsad/archive/refs/tags/v${GSAD_VERSION}.tar.gz" -O "$TARBALL_NAME"

    echo "2. Extraindo o arquivo..."
    rm -rf "$SOURCE_FOLDER"
    tar xzf "$TARBALL_NAME"
    cd "$SOURCE_FOLDER"

    echo "3. Criando o diretório de build e configurando com CMake..."
    mkdir -p build && cd build
    cmake ..

    echo "4. Compilando com 'make' (usando todos os núcleos de CPU)..."
    make -j$(nproc)

    echo "5. Instalando com 'sudo make install'..."
    sudo make install
EOF

# Verifica o status de saída do bloco de compilação
if [ $? -eq 0 ]; then
    echo ""
    echo "================================================="
    echo " gsad versão ${GSAD_VERSION} instalado com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de compilação.    !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
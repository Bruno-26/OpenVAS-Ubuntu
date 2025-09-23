#!/bin/bash

# ==================================================================
# Script para compilar e instalar a extensão PostgreSQL pg-gvm
#
# REQUISITO: A variável de ambiente PG_GVM deve estar definida
#            antes de executar este script.
#
# Exemplo de uso:
#   export PG_GVM="22.6.7"
#   sudo PG_GVM="$PG_GVM" ./build_pg-gvm.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# Valida se a variável de ambiente PG_GVM está definida
if [ -z "$PG_GVM" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: A variável de ambiente PG_GVM não está definida.  !!!"
    echo "!!!                                                          !!!"
    echo "!!! Antes de executar, defina a versão com o comando:        !!!"
    echo "!!!   export PG_GVM=\"<versao>\"                               !!!"
    echo "!!!                                                          !!!"
    echo "!!! E execute o script passando a variável para o sudo:     !!!"
    echo "!!!   sudo PG_GVM=\"\$PG_GVM\" $0                               !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# Define variáveis
PG_GVM_VERSION="$PG_GVM"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

# Valida se o usuário gvm existe
if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado."
    exit 1
fi

# --- 1. Preparação do Ambiente ---
echo "--- Preparando o ambiente de compilação para pg-gvm v${PG_GVM_VERSION} ---"
mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de fontes '$SOURCE_DIR' está pronto."
echo ""

# --- 2. Execução como usuário GVM ---
echo "--- Executando o processo de compilação como usuário '$GVM_USER' ---"

# Usa "Here Document" para executar um bloco de comandos como outro usuário.
# A variável PG_GVM_VERSION é passada para o ambiente do novo shell.
sudo -Hiu "$GVM_USER" PG_GVM_VERSION="$PG_GVM_VERSION" bash << 'EOF'
    # 'set -e' garante que o script pare se houver qualquer erro.
    set -e

    # Define variáveis internas
    SOURCE_DIR="$HOME/gvm-source"
    TARBALL_NAME="pg-gvm-v${PG_GVM_VERSION}.tar.gz"
    SOURCE_FOLDER="pg-gvm-${PG_GVM_VERSION}"

    cd "$SOURCE_DIR"

    echo "1. Baixando pg-gvm versão ${PG_GVM_VERSION}..."
    wget "https://github.com/greenbone/pg-gvm/archive/refs/tags/v${PG_GVM_VERSION}.tar.gz" -O "$TARBALL_NAME"

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

# Verifica o status de saída do bloco de comandos acima
if [ $? -eq 0 ]; then
    echo ""
    echo "================================================="
    echo " pg-gvm versão ${PG_GVM_VERSION} instalado com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de compilação.    !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
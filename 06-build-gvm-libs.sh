#!/bin/bash

# ==================================================================
# Script para compilar e instalar gvm-libs (VERSÃO VERBOSA)
#
# REQUISITO: A variável de ambiente GVM_LIBS deve estar definida
#            antes de executar este script.
#
# Exemplo de uso:
#   export GVM_LIBS="22.7.0"
#   sudo GVM_LIBS="$GVM_LIBS" ./build_gvm_libs.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

if [ -z "$GVM_LIBS" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: A variável de ambiente GVM_LIBS não está definida. !!!"
    echo "!!!                                                          !!!"
    echo "!!! Execute-o da seguinte forma:                             !!!"
    echo "!!!   sudo GVM_LIBS=\"<versao>\" $0                             !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# Define variáveis
GVM_LIBS_VERSION="$GVM_LIBS"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado."
    exit 1
fi

# --- 1. Preparação do Ambiente ---
echo "--- Preparando o ambiente de compilação para gvm-libs v${GVM_LIBS_VERSION} ---"
mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de fontes '$SOURCE_DIR' está pronto."
echo ""

# --- 2. Execução como usuário GVM usando "Here Document" ---
echo "--- Executando o processo de compilação como usuário '$GVM_USER' ---"

# Esta sintaxe com "<< 'EOF'" é mais robusta para exibir o output em tempo real.
# A variável GVM_LIBS_VERSION é passada para o ambiente do novo shell.
sudo -Hiu "$GVM_USER" GVM_LIBS_VERSION="$GVM_LIBS_VERSION" bash << 'EOF'
    # 'set -e' garante que o script pare se houver qualquer erro.
    set -e

    # Define variáveis internas (herdando GVM_LIBS_VERSION)
    SOURCE_DIR="$HOME/gvm-source"
    TARBALL_NAME="gvm-libs-v${GVM_LIBS_VERSION}.tar.gz"
    SOURCE_FOLDER="gvm-libs-${GVM_LIBS_VERSION}"

    cd "$SOURCE_DIR"

    echo "1. Baixando gvm-libs versão ${GVM_LIBS_VERSION}..."
    # Removido -q para mostrar o progresso
    wget "https://github.com/greenbone/gvm-libs/archive/refs/tags/v${GVM_LIBS_VERSION}.tar.gz" -O "$TARBALL_NAME"

    echo "2. Extraindo o arquivo..."
    # Limpa a pasta antiga, se existir
    rm -rf "$SOURCE_FOLDER"
    tar xzf "$TARBALL_NAME"
    cd "$SOURCE_FOLDER"

    echo "3. Criando o diretório de build e configurando com CMake..."
    mkdir -p build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local

    echo "4. Compilando com 'make' (usando todos os núcleos de CPU)..."
    # Adicionado -j$(nproc) para acelerar a compilação
    make -j$(nproc)

    echo "5. Instalando com 'sudo make install'..."
    # Este comando funciona porque configuramos o sudoers para o usuário gvm
    sudo make install
EOF

# Verifica o status de saída do bloco de comandos acima
if [ $? -eq 0 ]; then
    echo ""
    echo "================================================="
    echo " gvm-libs versão ${GVM_LIBS_VERSION} instalado com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de compilação.    !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
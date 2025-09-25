#!/bin/bash

# ==================================================================
# Script para compilar e instalar o OpenVAS SMB e o OpenVAS Scanner.
#
# REQUISITO: As variáveis de ambiente OPENVAS_SMB e OPENVAS_SCANNER
#            devem ser definidas antes da execução.
#
# Exemplo de uso:
#   export OPENVAS_SMB="22.5.7"
#   export OPENVAS_SCANNER="23.15.3"
#   sudo OPENVAS_SMB="$OPENVAS_SMB" OPENVAS_SCANNER="$OPENVAS_SCANNER" ./build_scanners.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# Valida se as variáveis de ambiente estão definidas
if [ -z "$OPENVAS_SMB" ] || [ -z "$OPENVAS_SCANNER" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: Uma ou mais variáveis de ambiente não foram definidas. !!!"
    echo "!!!                                                          !!!"
    echo "!!! Defina OPENVAS_SMB e OPENVAS_SCANNER e execute assim:    !!!"
    echo "!!! sudo OPENVAS_SMB=\"...\" OPENVAS_SCANNER=\"...\" $0        !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# Define variáveis
OPENVAS_SMB_VERSION="$OPENVAS_SMB"
OPENVAS_SCANNER_VERSION="$OPENVAS_SCANNER"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado."
    exit 1
fi

# --- 1. Preparação do Ambiente ---
echo "--- Preparando o ambiente de compilação ---"
mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de fontes '$SOURCE_DIR' está pronto."
echo ""

# --- 2. Execução como usuário GVM ---
echo "--- Iniciando o processo de compilação como usuário '$GVM_USER' ---"

# Passa as duas variáveis de versão para o ambiente do shell do gvm
sudo -Hiu "$GVM_USER" \
    OPENVAS_SMB_VERSION="$OPENVAS_SMB_VERSION" \
    OPENVAS_SCANNER_VERSION="$OPENVAS_SCANNER_VERSION" \
    bash << 'EOF'
    set -e # Para o script se qualquer comando falhar

    SOURCE_DIR="$HOME/gvm-source"
    cd "$SOURCE_DIR"

    # --- Bloco de compilação para openvas-smb ---
    echo ""
    echo "--- Compilando openvas-smb v${OPENVAS_SMB_VERSION} ---"
    SMB_TARBALL_NAME="openvas-smb-v${OPENVAS_SMB_VERSION}.tar.gz"
    SMB_SOURCE_FOLDER="openvas-smb-${OPENVAS_SMB_VERSION}"

    echo "1. Baixando openvas-smb..."
    wget "https://github.com/greenbone/openvas-smb/archive/refs/tags/v${OPENVAS_SMB_VERSION}.tar.gz" -O "$SMB_TARBALL_NAME"

    echo "2. Extraindo..."
    rm -rf "$SMB_SOURCE_FOLDER"
    tar xzf "$SMB_TARBALL_NAME"
    cd "$SMB_SOURCE_FOLDER"

    echo "3. Configurando com CMake e compilando..."
    mkdir -p build && cd build
    cmake ..
    make -j$(nproc)

    echo "4. Instalando..."
    sudo make install
    cd "$SOURCE_DIR" # Retorna ao diretório base para a próxima compilação

    # --- Bloco de compilação para openvas-scanner ---
    echo ""
    echo "--- Compilando openvas-scanner v${OPENVAS_SCANNER_VERSION} ---"
    SCANNER_TARBALL_NAME="openvas-scanner-v${OPENVAS_SCANNER_VERSION}.tar.gz"
    SCANNER_SOURCE_FOLDER="openvas-scanner-${OPENVAS_SCANNER_VERSION}"

    echo "1. Baixando openvas-scanner..."
    wget "https://github.com/greenbone/openvas-scanner/archive/refs/tags/v${OPENVAS_SCANNER_VERSION}.tar.gz" -O "$SCANNER_TARBALL_NAME"

    echo "2. Extraindo..."
    rm -rf "$SCANNER_SOURCE_FOLDER"
    tar xzf "$SCANNER_TARBALL_NAME"
    cd "$SCANNER_SOURCE_FOLDER"

    echo "3. Configurando com CMake e compilando..."
    mkdir -p build && cd build
    cmake ..
    make -j$(nproc)

    echo "4. Instalando..."
    sudo make install
EOF

# Verifica o status de saída do bloco de compilação
if [ $? -eq 0 ]; then
    echo ""
    echo "================================================="
    echo " openvas-smb e openvas-scanner instalados com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de compilação.    !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
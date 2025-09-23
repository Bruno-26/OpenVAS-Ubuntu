#!/bin/bash

# ==================================================================
# Script para compilar e instalar Greenbone Vulnerability Manager (gvmd)
#
# REQUISITO: A variável de ambiente GVMD deve estar definida
#            antes de executar este script.
#
# Exemplo de uso:
#   export GVMD="24.3.4"
#   sudo GVMD="$GVMD" ./build_gvmd.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# Valida se a variável de ambiente GVMD está definida
if [ -z "$GVMD" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: A variável de ambiente GVMD não está definida.    !!!"
    echo "!!!                                                          !!!"
    echo "!!! Antes de executar, defina a versão com o comando:        !!!"
    echo "!!!   export GVMD=\"<versao>\"                               !!!"
    echo "!!!                                                          !!!"
    echo "!!! E execute o script passando a variável para o sudo:     !!!"
    echo "!!!   sudo GVMD=\"\$GVMD\" $0                               !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# Define variáveis
GVMD_VERSION="$GVMD"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"
TARBALL_NAME="gvmd-v${GVMD_VERSION}.tar.gz"
SOURCE_FOLDER="gvmd-${GVMD_VERSION}"

# Valida se o usuário gvm existe
if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado. Execute o script de criação de usuário primeiro."
    exit 1
fi

# --- 1. Preparação do Ambiente ---
echo "--- Preparando o ambiente de compilação para gvmd v${GVMD_VERSION} ---"
mkdir -p "$SOURCE_DIR"
# Garante que o diretório home e os subdiretórios sejam do usuário gvm
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de fontes '$SOURCE_DIR' está pronto."
echo ""

# --- 2. Execução como usuário GVM ---
echo "--- Executando o processo de compilação como usuário '$GVM_USER' ---"

# Usa "Here Document" para executar um bloco de comandos como outro usuário,
# preservando o output em tempo real.
# A variável GVMD_VERSION é passada para o ambiente do novo shell.
sudo -Hiu "$GVM_USER" GVMD_VERSION="$GVMD_VERSION" bash << 'EOF'
    # 'set -e' garante que o script pare se houver qualquer erro.
    set -e

    # Define variáveis internas (herdando GVMD_VERSION)
    SOURCE_DIR="$HOME/gvm-source"
    TARBALL_NAME="gvmd-v${GVMD_VERSION}.tar.gz"
    SOURCE_FOLDER="gvmd-${GVMD_VERSION}"

    cd "$SOURCE_DIR"

    echo "1. Baixando gvmd versão ${GVMD_VERSION}..."
    wget "https://github.com/greenbone/gvmd/archive/refs/tags/v${GVMD_VERSION}.tar.gz" -O "$TARBALL_NAME"

    echo "2. Extraindo o arquivo..."
    rm -rf "$SOURCE_FOLDER"
    tar xzf "$TARBALL_NAME"
    cd "$SOURCE_FOLDER"

    echo "3. Criando o diretório de build e configurando com CMake..."
    mkdir -p build && cd build
    # CMake pode precisar de flags adicionais dependendo das outras dependências
    # Por exemplo, se gvm-libs não estiver em um caminho padrão, pode ser necessário:
    # -DVM_LIBS_DIR=/usr/local/lib
    # -DVM_LIBS_INCLUDE_DIR=/usr/local/include
    # Para agora, vamos tentar o padrão.
    cmake ..

    echo "4. Compilando com 'make' (usando todos os núcleos de CPU)..."
    make -j$(nproc)

    echo "5. Instalando com 'sudo make install'..."
    # Este comando funciona porque configuramos o sudoers para o usuário gvm
    sudo make install
EOF

# Verifica o status de saída do bloco de comandos acima
if [ $? -eq 0 ]; then
    echo ""
    echo "================================================="
    echo " gvmd versão ${GVMD_VERSION} instalado com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de compilação.    !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
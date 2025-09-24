#!/bin/bash

# ==================================================================
# Script para instalar o pacote gvm-tools
#
# Este script baixa e instala o pacote Python a partir do PyPI
# em um diretório temporário e depois o copia para os locais
# corretos do sistema para torná-lo disponível globalmente.
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Definição de Variáveis ---
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
# Define um diretório específico para este build
BUILD_DIR="$GVM_HOME/gvm-source/gvm-tools-build"

# Detecta a versão do Python e o nome do diretório de pacotes
PYTHON_VERSION_DIR=$(python3 -c 'import sys; print(f"python{sys.version_info.major}.{sys.version_info.minor}")')
PYTHON_PACKAGES_DIR_NAME=$(python3 -c "import sysconfig; print(sysconfig.get_path('platlib').split('/')[-1])")

if [ -z "$PYTHON_VERSION_DIR" ] || [ -z "$PYTHON_PACKAGES_DIR_NAME" ]; then
    echo "ERRO: Não foi possível determinar os caminhos de diretório do Python 3."
    exit 1
fi
echo "Versão do Python detectada: $PYTHON_VERSION_DIR"
echo "Diretório de pacotes detectado: $PYTHON_PACKAGES_DIR_NAME"

if ! id -u "$GVM_USER" &>/dev/null; then
    echo "ERRO: O usuário '$GVM_USER' não foi encontrado."
    exit 1
fi

# --- 2. Preparação do Ambiente ---
echo "--- Preparando o ambiente de instalação ---"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
echo "Diretório de build '$BUILD_DIR' está pronto."
echo ""

# --- 3. Instalação via Pip (como usuário GVM) ---
echo "--- Baixando e instalando o pacote com pip como usuário '$GVM_USER' ---"

sudo -Hiu "$GVM_USER" BUILD_DIR="$BUILD_DIR" bash << 'EOF'
    set -e # Para o script se qualquer comando falhar

    cd "$BUILD_DIR"

    echo "1. Instalando 'gvm-tools' no diretório de build local..."
    python3 -m pip install --root=. gvm-tools
EOF

# Captura o status de saída do bloco de build
BUILD_STATUS=$?

# --- 4. Instalação dos Arquivos no Sistema (como root) ---
if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "--- Instalação com Pip concluída. Copiando os arquivos para o sistema ---"

    # Define os caminhos de origem e destino
    SOURCE_EXEC_PATH="${BUILD_DIR}/usr/local/bin/"
    DEST_EXEC_PATH="/usr/local/bin/"

    SOURCE_LIB_PATH="${BUILD_DIR}/usr/local/lib/${PYTHON_VERSION_DIR}/${PYTHON_PACKAGES_DIR_NAME}/"
    DEST_LIB_PATH="/usr/local/lib/${PYTHON_VERSION_DIR}/${PYTHON_PACKAGES_DIR_NAME}/"

    echo "1. Copiando executáveis (gvm-cli, gvm-script, etc.) para $DEST_EXEC_PATH..."
    # Usa um wildcard (*) pois gvm-tools instala múltiplos executáveis
    cp "${SOURCE_EXEC_PATH}"* "${DEST_EXEC_PATH}"

    echo "2. Criando o diretório de bibliotecas de destino: $DEST_LIB_PATH..."
    mkdir -p "$DEST_LIB_PATH"

    echo "3. Copiando os arquivos da biblioteca Python..."
    cp -r "${SOURCE_LIB_PATH}." "${DEST_LIB_PATH}"

    echo ""
    echo "================================================="
    echo " gvm-tools instalado com sucesso!"
    echo "================================================="
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO durante o processo de instalação.    !!!"
    echo "!!! Verifique as mensagens de erro acima.     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

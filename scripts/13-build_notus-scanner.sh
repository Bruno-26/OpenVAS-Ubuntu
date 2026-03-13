#!/bin/bash

# ==================================================================
# Script: 13-build_notus-scanner.sh
#
# Propósito:
# 1. Baixa o código-fonte do Notus Scanner.
# 2. Prepara o ambiente de build Python.
# 3. Compila e instala o Notus Scanner, responsável pela detecção
#    de vulnerabilidades locais (LSC).
# ==================================================================

# --- Configurações de Segurança e Estilo ---
set -e
set -o pipefail
source "$(dirname "$0")/../style.sh"

# --- Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  print_error "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# Valida se a variável de ambiente NOTUS_SCANNER está definida
if [ -z "$NOTUS_SCANNER" ]; then
  print_error "A variável de ambiente NOTUS_SCANNER não está definida."
  print_info "Uso correto: sudo NOTUS_SCANNER=\"22.6.5\" $0"
  exit 1
fi

# --- Variáveis de Ambiente ---
NOTUS_VERSION="$NOTUS_SCANNER"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

# Detecta a versão do Python
PYTHON_VER=$(python3 -c 'import sys; print(f"python{sys.version_info.major}.{sys.version_info.minor}")')
print_info "Versão do Python detectada: $PYTHON_VER"

if ! id "$GVM_USER" &>/dev/null; then
  print_error "O usuário '$GVM_USER' não foi encontrado."
  exit 1
fi

# --- 1. Preparação do Ambiente ---
print_info "Preparando ambiente para build do notus-scanner v${NOTUS_VERSION}..."

mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
print_success "Diretório de fontes '$SOURCE_DIR' preparado."

# --- 2. Build do Pacote ---
print_info "Iniciando build do Python como usuário '$GVM_USER'..."

sudo -Hiu "$GVM_USER" NOTUS_VERSION="$NOTUS_VERSION" bash << 'EOF'
  set -e
  SOURCE_DIR="$HOME/gvm-source"
  TARBALL="notus-scanner-v${NOTUS_VERSION}.tar.gz"
  FOLDER="notus-scanner-${NOTUS_VERSION}"

  cd "$SOURCE_DIR"
  echo -e "\033[0;34mℹ   1. Baixando notus-scanner v${NOTUS_VERSION}...\033[0m"
  wget -q "https://github.com/greenbone/notus-scanner/archive/refs/tags/v${NOTUS_VERSION}.tar.gz" -O "$TARBALL"
  
  echo -e "\033[0;34mℹ   2. Extraindo arquivos...\033[0m"
  rm -rf "$FOLDER"
  tar xzf "$TARBALL"
  cd "$FOLDER"

  echo -e "\033[0;34mℹ   3. Preparando instalação local (pip --root)...\033[0m"
  rm -rf build && mkdir build
  python3 -m pip install --user --root=./build . > /dev/null
EOF

# --- 3. Instalação no Sistema ---
print_info "Instalando binários e bibliotecas no sistema..."

FOLDER="notus-scanner-${NOTUS_VERSION}"
BUILD_ROOT="${SOURCE_DIR}/${FOLDER}/build"

# Caminhos de origem e destino
SRC_BIN="${BUILD_ROOT}${GVM_HOME}/.local/bin/"
SRC_LIB="${BUILD_ROOT}${GVM_HOME}/.local/lib/${PYTHON_VER}/site-packages/"
DST_LIB="/usr/local/lib/${PYTHON_VER}/site-packages/"

cp "${SRC_BIN}"* "/usr/local/bin/"
mkdir -p "$DST_LIB"
cp -r "${SRC_LIB}." "${DST_LIB}"

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " notus-scanner v${NOTUS_VERSION} instalado com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - Download e build do pacote Python concluído."
echo "   - Binários instalados em /usr/local/bin."
echo "   - Bibliotecas instaladas em $DST_LIB."
print_warning "========================================================================"

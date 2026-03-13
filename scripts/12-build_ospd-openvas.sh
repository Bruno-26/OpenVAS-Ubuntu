#!/bin/bash

# ==================================================================
# Script: 12-build_ospd-openvas.sh
#
# Propósito:
# 1. Baixa o código-fonte do OSPD-OpenVAS (Open Scanner Protocol Daemon).
# 2. Prepara o ambiente de build Python.
# 3. Compila e instala o daemon OSPD que comunica o gvmd com o openvas-scanner.
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

# Valida se a variável de ambiente OSPD_OPENVAS está definida
if [ -z "$OSPD_OPENVAS" ]; then
  print_error "A variável de ambiente OSPD_OPENVAS não está definida."
  print_info "Uso correto: sudo OSPD_OPENVAS=\"22.8.0\" $0"
  exit 1
fi

# --- Variáveis de Ambiente ---
OSPD_VERSION="$OSPD_OPENVAS"
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
print_info "Preparando ambiente para build do ospd-openvas v${OSPD_VERSION}..."

mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
print_success "Diretório de fontes '$SOURCE_DIR' preparado."

# --- 2. Build do Pacote ---
print_info "Iniciando build do Python como usuário '$GVM_USER'..."

sudo -Hiu "$GVM_USER" OSPD_VERSION="$OSPD_VERSION" bash << 'EOF'
  set -e
  SOURCE_DIR="$HOME/gvm-source"
  TARBALL="ospd-openvas-v${OSPD_VERSION}.tar.gz"
  FOLDER="ospd-openvas-${OSPD_VERSION}"

  cd "$SOURCE_DIR"
  echo -e "\033[0;34mℹ   1. Baixando ospd-openvas v${OSPD_VERSION}...\033[0m"
  wget -q "https://github.com/greenbone/ospd-openvas/archive/refs/tags/v${OSPD_VERSION}.tar.gz" -O "$TARBALL"
  
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

FOLDER="ospd-openvas-${OSPD_VERSION}"
BUILD_ROOT="${SOURCE_DIR}/${FOLDER}/build"

# Caminhos de origem e destino
SRC_BIN="${BUILD_ROOT}${GVM_HOME}/.local/bin/ospd-openvas"
SRC_LIB="${BUILD_ROOT}${GVM_HOME}/.local/lib/${PYTHON_VER}/site-packages/"
DST_LIB="/usr/local/lib/${PYTHON_VER}/site-packages/"

cp "$SRC_BIN" "/usr/local/bin/"
mkdir -p "$DST_LIB"
cp -r "${SRC_LIB}." "${DST_LIB}"

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " ospd-openvas v${OSPD_VERSION} instalado com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - Download e build do pacote Python concluído."
echo "   - Binário instalado em /usr/local/bin."
echo "   - Bibliotecas instaladas em $DST_LIB."
print_warning "========================================================================"

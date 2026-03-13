#!/bin/bash

# ==================================================================
# Script: 15-install_gvm-tools.sh
#
# Propósito:
# 1. Instala a coleção gvm-tools (gvm-cli, gvm-script, etc.) via PyPI.
# 2. Garante que as ferramentas de linha de comando para interagir
#    com o gvmd estejam disponíveis globalmente.
# 3. Prepara o ambiente para automação de tarefas do GVM.
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

# --- Variáveis de Ambiente ---
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
BUILD_DIR="$GVM_HOME/gvm-source/gvm-tools-build"

# Detecta caminhos do Python
PYTHON_VER=$(python3 -c 'import sys; print(f"python{sys.version_info.major}.{sys.version_info.minor}")')
PYTHON_PKGS=$(python3 -c "import sysconfig; print(sysconfig.get_path('platlib').split('/')[-1])")

if ! id "$GVM_USER" &>/dev/null; then
  print_error "O usuário '$GVM_USER' não foi encontrado."
  exit 1
fi

# --- 1. Preparação do Ambiente ---
print_info "Preparando ambiente para instalação do gvm-tools..."

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
print_success "Diretório de build '$BUILD_DIR' preparado."

# --- 2. Instalação via Pip ---
print_info "Baixando e instalando gvm-tools com pip..."

sudo -Hiu "$GVM_USER" BUILD_DIR="$BUILD_DIR" bash << 'EOF'
  set -e
  cd "$BUILD_DIR"
  echo -e "\033[0;34mℹ   Instalando pacote no diretório local...\033[0m"
  python3 -m pip install --root=. gvm-tools > /dev/null
EOF

# --- 3. Instalação no Sistema ---
print_info "Copiando binários e bibliotecas para o sistema..."

SRC_BIN="${BUILD_DIR}/usr/local/bin/"
SRC_LIB="${BUILD_DIR}/usr/local/lib/${PYTHON_VER}/${PYTHON_PKGS}/"
DST_LIB="/usr/local/lib/${PYTHON_VER}/${PYTHON_PKGS}/"

cp "${SRC_BIN}"* "/usr/local/bin/"
mkdir -p "$DST_LIB"
cp -r "${SRC_LIB}." "${DST_LIB}"

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " gvm-tools instalados com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - gvm-cli, gvm-script e gvm-pmp instalados."
echo "   - Ferramentas disponíveis em /usr/local/bin."
echo "   - Bibliotecas integradas ao ambiente global."
print_warning "========================================================================"

#!/bin/bash

# ==================================================================
# Script: 06-build_gvm_libs.sh
#
# Propósito:
# 1. Baixa o código-fonte do gvm-libs na versão especificada.
# 2. Configura o ambiente de compilação com CMake.
# 3. Compila e instala as bibliotecas GVM no sistema.
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

# Valida se a variável de ambiente GVM_LIBS está definida
if [ -z "$GVM_LIBS" ]; then
  print_error "A variável de ambiente GVM_LIBS não está definida."
  print_info "Uso correto: sudo GVM_LIBS=\"22.7.0\" $0"
  exit 1
fi

# --- Variáveis de Ambiente ---
GVM_LIBS_VERSION="$GVM_LIBS"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

if ! id "$GVM_USER" &>/dev/null; then
  print_error "O usuário '$GVM_USER' não foi encontrado."
  exit 1
fi

# --- 1. Preparação do Ambiente ---
print_info "Preparando ambiente para compilação do gvm-libs v${GVM_LIBS_VERSION}..."

mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
print_success "Diretório de fontes '$SOURCE_DIR' preparado."

# --- 2. Compilação e Instalação ---
print_info "Iniciando processo de compilação como usuário '$GVM_USER'..."

# Executa o bloco de comandos como usuário gvm
sudo -Hiu "$GVM_USER" GVM_LIBS_VERSION="$GVM_LIBS_VERSION" bash << 'EOF'
  set -e
  source "$(dirname "$0")/../style.sh" 2>/dev/null || true

  SOURCE_DIR="$HOME/gvm-source"
  TARBALL_NAME="gvm-libs-v${GVM_LIBS_VERSION}.tar.gz"
  SOURCE_FOLDER="gvm-libs-${GVM_LIBS_VERSION}"

  cd "$SOURCE_DIR"

  echo -e "\033[0;34mℹ   1. Baixando gvm-libs v${GVM_LIBS_VERSION}...\033[0m"
  wget -q "https://github.com/greenbone/gvm-libs/archive/refs/tags/v${GVM_LIBS_VERSION}.tar.gz" -O "$TARBALL_NAME"

  echo -e "\033[0;34mℹ   2. Extraindo arquivos...\033[0m"
  rm -rf "$SOURCE_FOLDER"
  tar xzf "$TARBALL_NAME"
  cd "$SOURCE_FOLDER"

  echo -e "\033[0;34mℹ   3. Configurando com CMake...\033[0m"
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local > /dev/null

  echo -e "\033[0;34mℹ   4. Compilando (usando $(nproc) núcleos)...\033[0m"
  make -j$(nproc) > /dev/null

  echo -e "\033[0;34mℹ   5. Instalando bibliotecas...\033[0m"
  sudo make install > /dev/null
EOF

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " gvm-libs v${GVM_LIBS_VERSION} instalado com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - Download e extração do código-fonte."
echo "   - Configuração do CMake concluída."
echo "   - Compilação realizada com sucesso."
echo "   - Bibliotecas instaladas em /usr/local/lib."
print_warning "========================================================================"

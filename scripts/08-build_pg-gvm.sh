#!/bin/bash

# ==================================================================
# Script: 08-build_pg-gvm.sh
#
# Propósito:
# 1. Baixa o código-fonte da extensão pg-gvm.
# 2. Compila a extensão para integrar o PostgreSQL com o GVM.
# 3. Instala a biblioteca compartilhada no diretório de extensões
#    do PostgreSQL.
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

# Valida se a variável de ambiente PG_GVM está definida
if [ -z "$PG_GVM" ]; then
  print_error "A variável de ambiente PG_GVM não está definida."
  print_info "Uso correto: sudo PG_GVM=\"22.6.4\" $0"
  exit 1
fi

# --- Variáveis de Ambiente ---
PG_GVM_VERSION="$PG_GVM"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

if ! id "$GVM_USER" &>/dev/null; then
  print_error "O usuário '$GVM_USER' não foi encontrado."
  exit 1
fi

# --- 1. Preparação do Ambiente ---
print_info "Preparando ambiente para compilação do pg-gvm v${PG_GVM_VERSION}..."

mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
print_success "Diretório de fontes '$SOURCE_DIR' preparado."

# --- 2. Compilação e Instalação ---
print_info "Iniciando processo de compilação como usuário '$GVM_USER'..."

# Executa o bloco de comandos como usuário gvm
sudo -Hiu "$GVM_USER" PG_GVM_VERSION="$PG_GVM_VERSION" bash << 'EOF'
  set -e
  
  SOURCE_DIR="$HOME/gvm-source"
  TARBALL_NAME="pg-gvm-v${PG_GVM_VERSION}.tar.gz"
  SOURCE_FOLDER="pg-gvm-${PG_GVM_VERSION}"

  cd "$SOURCE_DIR"

  echo -e "\033[0;34mℹ   1. Baixando pg-gvm v${PG_GVM_VERSION}...\033[0m"
  wget -q "https://github.com/greenbone/pg-gvm/archive/refs/tags/v${PG_GVM_VERSION}.tar.gz" -O "$TARBALL_NAME"

  echo -e "\033[0;34mℹ   2. Extraindo arquivos...\033[0m"
  rm -rf "$SOURCE_FOLDER"
  tar xzf "$TARBALL_NAME"
  cd "$SOURCE_FOLDER"

  echo -e "\033[0;34mℹ   3. Configurando com CMake...\033[0m"
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local > /dev/null

  echo -e "\033[0;34mℹ   4. Compilando extensão...\033[0m"
  make -j$(nproc) > /dev/null

  echo -e "\033[0;34mℹ   5. Instalando no PostgreSQL...\033[0m"
  sudo make install > /dev/null
EOF

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Extensão pg-gvm v${PG_GVM_VERSION} instalada com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - Download da extensão do PostgreSQL para GVM."
echo "   - Compilação realizada com sucesso."
echo "   - Biblioteca instalada no diretório de extensões do PostgreSQL."
print_warning "========================================================================"

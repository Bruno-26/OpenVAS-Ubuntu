#!/bin/bash

# ==================================================================
# Script: 07-build_gvmd.sh
#
# Propósito:
# 1. Baixa o código-fonte do gvmd na versão especificada.
# 2. Configura o ambiente de compilação com CMake.
# 3. Compila e instala o Greenbone Vulnerability Manager Daemon (gvmd).
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

# Valida se a variável de ambiente GVMD está definida
if [ -z "$GVMD" ]; then
  print_error "A variável de ambiente GVMD não está definida."
  print_info "Uso correto: sudo GVMD=\"23.11.0\" $0"
  exit 1
fi

# --- Variáveis de Ambiente ---
GVMD_VERSION="$GVMD"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

if ! id "$GVM_USER" &>/dev/null; then
  print_error "O usuário '$GVM_USER' não foi encontrado."
  exit 1
fi

# --- 1. Preparação do Ambiente ---
print_info "Preparando ambiente para compilação do gvmd v${GVMD_VERSION}..."

mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
print_success "Diretório de fontes '$SOURCE_DIR' preparado."

# --- 2. Compilação e Instalação ---
print_info "Iniciando processo de compilação como usuário '$GVM_USER'..."

# Executa o bloco de comandos como usuário gvm
sudo -Hiu "$GVM_USER" GVMD_VERSION="$GVMD_VERSION" bash << 'EOF'
  set -e
  
  SOURCE_DIR="$HOME/gvm-source"
  TARBALL_NAME="gvmd-v${GVMD_VERSION}.tar.gz"
  SOURCE_FOLDER="gvmd-${GVMD_VERSION}"

  cd "$SOURCE_DIR"

  echo -e "\033[0;34mℹ   1. Baixando gvmd v${GVMD_VERSION}...\033[0m"
  wget -q "https://github.com/greenbone/gvmd/archive/refs/tags/v${GVMD_VERSION}.tar.gz" -O "$TARBALL_NAME"

  echo -e "\033[0;34mℹ   2. Extraindo arquivos...\033[0m"
  rm -rf "$SOURCE_FOLDER"
  tar xzf "$TARBALL_NAME"
  cd "$SOURCE_FOLDER"

  echo -e "\033[0;34mℹ   3. Configurando com CMake...\033[0m"
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local > /dev/null

  echo -e "\033[0;34mℹ   4. Compilando (usando $(nproc) núcleos)...\033[0m"
  make -j$(nproc) > /dev/null

  echo -e "\033[0;34mℹ   5. Instalando gvmd...\033[0m"
  sudo make install > /dev/null
EOF

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " gvmd v${GVMD_VERSION} instalado com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - Download e extração do código-fonte do daemon."
echo "   - Configuração do CMake concluída."
echo "   - Compilação realizada com sucesso."
echo "   - Binário gvmd instalado em /usr/local/sbin."
print_warning "========================================================================"

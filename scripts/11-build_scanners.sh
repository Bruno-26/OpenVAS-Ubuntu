#!/bin/bash

# ==================================================================
# Script: 11-build_scanners.sh
#
# Propósito:
# 1. Compila e instala o openvas-smb (suporte a SMB para o scanner).
# 2. Compila e instala o openvas-scanner (o motor principal de busca).
# 3. Garante que os scanners de vulnerabilidade estejam disponíveis.
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

# Valida as variáveis de ambiente
if [ -z "$OPENVAS_SMB" ] || [ -z "$OPENVAS_SCANNER" ]; then
  print_error "Variáveis de ambiente OPENVAS_SMB ou OPENVAS_SCANNER não definidas."
  print_info "Uso: sudo OPENVAS_SMB=\"22.5.7\" OPENVAS_SCANNER=\"23.15.3\" $0"
  exit 1
fi

# --- Variáveis de Ambiente ---
SMB_VER="$OPENVAS_SMB"
SCANNER_VER="$OPENVAS_SCANNER"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"

if ! id "$GVM_USER" &>/dev/null; then
  print_error "O usuário '$GVM_USER' não foi encontrado."
  exit 1
fi

# --- 1. Preparação do Ambiente ---
print_info "Preparando ambiente para compilação dos scanners..."

mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
print_success "Diretório de fontes '$SOURCE_DIR' preparado."

# --- 2. Compilação e Instalação ---
print_info "Iniciando compilação dos scanners como usuário '$GVM_USER'..."

sudo -Hiu "$GVM_USER" SMB_VER="$SMB_VER" SCANNER_VER="$SCANNER_VER" bash << 'EOF'
  set -e
  SOURCE_DIR="$HOME/gvm-source"
  cd "$SOURCE_DIR"

  # --- OpenVAS SMB ---
  echo -e "\033[0;34mℹ   Compilando openvas-smb v${SMB_VER}...\033[0m"
  SMB_TAR="openvas-smb-v${SMB_VER}.tar.gz"
  SMB_FOLDER="openvas-smb-${SMB_VER}"
  
  wget -q "https://github.com/greenbone/openvas-smb/archive/refs/tags/v${SMB_VER}.tar.gz" -O "$SMB_TAR"
  rm -rf "$SMB_FOLDER"
  tar xzf "$SMB_TAR"
  cd "$SMB_FOLDER"
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local > /dev/null
  make -j$(nproc) > /dev/null
  sudo make install > /dev/null
  cd "$SOURCE_DIR"

  # --- OpenVAS Scanner ---
  echo -e "\033[0;34mℹ   Compilando openvas-scanner v${SCANNER_VER}...\033[0m"
  SCAN_TAR="openvas-scanner-v${SCANNER_VER}.tar.gz"
  SCAN_FOLDER="openvas-scanner-${SCANNER_VER}"

  wget -q "https://github.com/greenbone/openvas-scanner/archive/refs/tags/v${SCANNER_VER}.tar.gz" -O "$SCAN_TAR"
  rm -rf "$SCAN_FOLDER"
  tar xzf "$SCAN_TAR"
  cd "$SCAN_FOLDER"
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local > /dev/null
  make -j$(nproc) > /dev/null
  sudo make install > /dev/null
EOF

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Scanners instalados com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - openvas-smb v${SMB_VER} compilado e instalado."
echo "   - openvas-scanner v${SCANNER_VER} compilado e instalado."
echo "   - Suporte a verificação de vulnerabilidades em rede pronto."
print_warning "========================================================================"

#!/bin/bash

# ==================================================================
# Script: 09-build_gsa.sh
#
# Propósito:
# 1. Baixa o código-fonte do Greenbone Security Assistant (GSA).
#    O GSA é a interface web (front-end) do GVM.
# 2. Instala as dependências do Node.js necessárias.
# 3. Compila o projeto (build) para gerar os arquivos estáticos.
# 4. Instala os arquivos compilados no diretório web do sistema.
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

# Valida se a variável de ambiente GSA está definida
if [ -z "$GSA" ]; then
  print_error "A variável de ambiente GSA não está definida."
  print_info "Uso correto: sudo GSA=\"24.2.0\" $0"
  exit 1
fi

# --- Variáveis de Ambiente ---
GSA_VERSION="$GSA"
GVM_USER="gvm"
GVM_HOME="/opt/gvm"
SOURCE_DIR="$GVM_HOME/gvm-source"
INSTALL_DIR="/usr/local/share/gvm/gsad/web"

if ! id "$GVM_USER" &>/dev/null; then
  print_error "O usuário '$GVM_USER' não foi encontrado."
  exit 1
fi

# --- 1. Preparação do Ambiente ---
print_info "Preparando ambiente para o build do GSA v${GSA_VERSION}..."

mkdir -p "$SOURCE_DIR"
chown -R "$GVM_USER:$GVM_USER" "$GVM_HOME"
print_success "Diretório de fontes '$SOURCE_DIR' preparado."

# --- 2. Build do Front-end ---
print_info "Iniciando build do Node.js como usuário '$GVM_USER' (isso pode demorar)..."

# Executa o bloco de comandos como usuário gvm
sudo -Hiu "$GVM_USER" GSA_VERSION="$GSA_VERSION" bash << 'EOF'
  set -e

  # Carrega o NVM e Node
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
  fi

  SOURCE_DIR="/opt/gvm/gvm-source"
  TARBALL_NAME="gsa-v${GSA_VERSION}.tar.gz"
  SOURCE_FOLDER="gsa-${GSA_VERSION}"

  cd "$SOURCE_DIR"

  echo -e "\033[0;34mℹ   1. Baixando GSA v${GSA_VERSION}...\033[0m"
  wget -q "https://github.com/greenbone/gsa/archive/refs/tags/v${GSA_VERSION}.tar.gz" -O "$TARBALL_NAME"

  echo -e "\033[0;34mℹ   2. Extraindo arquivos...\033[0m"
  rm -rf "$SOURCE_FOLDER"
  tar xzf "$TARBALL_NAME"
  cd "$SOURCE_FOLDER"

  echo -e "\033[0;34mℹ   3. Instalando dependências (npm install - isso pode demorar vários minutos)...\033[0m"
  npm install

  echo -e "\033[0;34mℹ   4. Gerando build de produção (npm run build - isso pode demorar vários minutos)...\033[0m"
  npm run build
EOF

# --- 3. Instalação ---
print_info "Instalando arquivos estáticos no diretório web..."

mkdir -p "$INSTALL_DIR"
# Limpeza segura do diretório antigo
rm -rf "${INSTALL_DIR:?}/"*

SOURCE_FOLDER="gsa-${GSA_VERSION}"
cp -r "$SOURCE_DIR/$SOURCE_FOLDER/build/"* "$INSTALL_DIR"
chown -R "$GVM_USER:$GVM_USER" "$INSTALL_DIR"

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Interface GSA v${GSA_VERSION} instalada com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - Download e extração do código-fonte front-end."
echo "   - Build do projeto Node.js concluído."
echo "   - Arquivos instalados em $INSTALL_DIR."
print_warning "========================================================================"

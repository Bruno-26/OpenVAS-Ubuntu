#!/bin/bash

# ==================================================================
# Script: 05-nodejs.sh
#
# Propósito:
# 1. Instala o NVM (Node Version Manager) para o usuário 'gvm'.
# 2. Instala a versão LTS mais recente do Node.js.
# 3. Garante que o ambiente do shell do usuário 'gvm' esteja
#    corretamente configurado para usar o Node.js e NPM.
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

if ! id "gvm" &>/dev/null; then
  print_error "O usuário 'gvm' não foi encontrado. Execute o script 04 primeiro."
  exit 1
fi

# --- 1. Preparação do Ambiente ---
print_info "Preparando o ambiente do usuário 'gvm'..."

GVM_HOME="/opt/gvm"

# Garante que os arquivos de perfil existam
for file in .bashrc .profile; do
  if [ ! -f "$GVM_HOME/$file" ]; then
    print_info "Criando $file para o usuário 'gvm'..."
    cp "/etc/skel/$file" "$GVM_HOME/$file"
    chown gvm:gvm "$GVM_HOME/$file"
  fi
done

# Instala curl se necessário
if ! command -v curl &> /dev/null; then
  print_info "Instalando 'curl' necessário para o NVM..."
  apt-get update > /dev/null
  apt-get install -y curl
fi

# --- 2. Instalação do NVM ---
print_info "Instalando NVM para o usuário 'gvm'..."
NVM_VERSION="v0.39.7"

# Executa como usuário gvm
sudo -Hiu gvm bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash"
print_success "Instalador do NVM executado."

# --- 3. Instalação do Node.js LTS ---
print_info "Instalando Node.js LTS (Long-Term Support)..."

# Carrega nvm e instala node lts
sudo -Hiu gvm bash -c '
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default "lts/*"
'
print_success "Node.js LTS instalado com sucesso."

# --- 4. Verificação ---
print_info "Verificando as versões instaladas..."

NODE_VER=$(sudo -Hiu gvm bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node -v')
NPM_VER=$(sudo -Hiu gvm bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm -v')

print_success "Node.js: $NODE_VER"
print_success "NPM: $NPM_VER"

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Instalação do NVM e Node.js concluída!"
echo ""
print_info " Resumo das Ações:"
echo "   - NVM ($NVM_VERSION) instalado para o usuário 'gvm'."
echo "   - Node.js LTS e NPM instalados e configurados como padrão."
echo "   - Ambiente de shell (.bashrc/.profile) preparado."
print_warning "========================================================================"

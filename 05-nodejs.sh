#!/bin/bash
# ==================================================================
# Script para instalar NVM e Node.js para o usuário 'gvm'
# ==================================================================
# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi
if ! id -u gvm &>/dev/null; then
    echo "ERRO: O usuário 'gvm' não foi encontrado."
    exit 1
fi
echo "Instalando 'curl' (se necessário)..."
apt-get update > /dev/null
apt-get install -y curl

# --- 1. Preparação do Ambiente do Usuário 'gvm'  ---
echo "--- Verificando e preparando o ambiente do usuário 'gvm' ---"
GVM_HOME="/opt/gvm"
# Se .bashrc não existir, copia do esqueleto
if [ ! -f "$GVM_HOME/.bashrc" ]; then
    echo "Arquivo .bashrc não encontrado. Criando a partir do esqueleto..."
    cp /etc/skel/.bashrc "$GVM_HOME/.bashrc"
    chown gvm:gvm "$GVM_HOME/.bashrc"
fi
# Se .profile não existir, copia do esqueleto
if [ ! -f "$GVM_HOME/.profile" ]; then
    echo "Arquivo .profile não encontrado. Criando a partir do esqueleto..."
    cp /etc/skel/.profile "$GVM_HOME/.profile"
    chown gvm:gvm "$GVM_HOME/.profile"
fi

# --- 2. Instalação do NVM ---
echo "--- Instalando o NVM para o usuário 'gvm' ---"
NVM_VERSION="v0.39.7"
sudo -Hiu gvm bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash"

# --- 3. Instalação do Node.js LTS ---
echo "--- Instalando Node.js LTS (Long-Term Support) ---"
sudo -Hiu gvm bash -i -c "nvm install --lts"
sudo -Hiu gvm bash -i -c "nvm alias default lts/*"

# --- 4. Verificação ---
echo "--- Verificando as versões instaladas (como 'gvm') ---"
sudo -Hiu gvm bash -i -c "echo -n 'Versão do Node.js: ' && node -v"
sudo -Hiu gvm bash -i -c "echo -n 'Versão do NPM: ' && npm -v"

echo ""
echo "====================================================================="
echo " Instalação do NVM e Node.js concluída!"
echo "====================================================================="
#!/bin/bash

# ==================================================================
# Script: 22-setup_feed_validation.sh
#
# Propósito:
# 1. Configura a chave GnuPG oficial da Greenbone Community.
# 2. Permite que o GVM valide a integridade e autenticidade dos
#    feeds de vulnerabilidade baixados.
# 3. Define o nível de confiança máximo para a chave de assinatura.
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

# --- 1. Variáveis ---
GVM_USER="gvm"
GPG_DIR="/etc/openvas/gnupg"
KEY_URL="https://www.greenbone.net/GBCommunitySigningKey.asc"
KEY_FILE="/tmp/GBCommunitySigningKey.asc"
FINGERPRINT="8AE4BE429B60A59B311C2E739823FAA60ED1E580"

# --- 2. Preparação e Importação ---
print_info "Configurando validação de feeds GPG..."

mkdir -p "$GPG_DIR"

print_info "Baixando chave oficial da Greenbone..."
if wget -q "$KEY_URL" -O "$KEY_FILE"; then
  print_success "Chave baixada com sucesso."
else
  print_error "Falha ao baixar a chave de $KEY_URL."
  exit 1
fi

print_info "Importando chave para o chaveiro do sistema..."
gpg --homedir="$GPG_DIR" --import "$KEY_FILE"
rm -f "$KEY_FILE"

# --- 3. Configuração de Confiança ---
print_info "Definindo nível de confiança (ownertrust) nível 6..."
echo "${FINGERPRINT}:6:" | gpg --homedir="$GPG_DIR" --import-ownertrust
print_success "Confiança da chave configurada."

# --- 4. Ajustes de Permissão ---
print_info "Ajustando permissões do diretório GPG..."
chown -R gvm:gvm "$GPG_DIR"
chmod 700 "$GPG_DIR"
print_success "Permissões aplicadas."

# --- 5. Verificação ---
print_info "Validando importação da chave..."
if sudo -Hiu gvm gpg --homedir="$GPG_DIR" --list-keys | grep -q "Greenbone Community"; then
  print_success "Chave Greenbone Community validada e pronta para uso."
else
  print_warning "Não foi possível confirmar a chave via 'list-keys'. Verifique manualmente."
fi

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Configuração da chave de validação concluída!"
echo ""
print_info " Resumo das Ações:"
echo "   - Chave de assinatura importada em $GPG_DIR."
echo "   - Nível de confiança total estabelecido."
echo "   - Integridade dos feeds agora pode ser verificada pelo scanner."
print_warning "========================================================================"

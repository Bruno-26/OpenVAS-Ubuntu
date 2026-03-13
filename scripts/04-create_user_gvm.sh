#!/bin/bash

# ==================================================================
# Script: 04-create_user_gvm.sh
#
# Propósito:
# 1. Cria o usuário de sistema 'gvm' com diretório home em /opt/gvm.
# 2. Configura as permissões iniciais do diretório /opt/gvm.
# 3. Configura privilégios de sudo específicos para o usuário 'gvm'
#    poder executar instalações e scripts Python sem senha.
# 4. Valida a configuração do sudoers para evitar erros de sistema.
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

# --- 1. Criação do Usuário ---
print_info "Configurando o usuário de sistema 'gvm'..."

if id "gvm" &>/dev/null; then
  print_info "Usuário 'gvm' já existe. Pulando a criação."
else
  print_info "Criando o usuário 'gvm' com home em /opt/gvm..."
  useradd -r -m -d /opt/gvm -c "GVM User" -s /bin/bash gvm
  print_success "Usuário 'gvm' criado com sucesso."
fi

# --- 2. Configuração do Diretório Home ---
print_info "Configurando o diretório home /opt/gvm..."

if [ ! -d "/opt/gvm" ]; then
  mkdir -p /opt/gvm
  print_info "Diretório /opt/gvm criado."
fi

chown -R gvm:gvm /opt/gvm
print_success "Propriedade de /opt/gvm definida para gvm:gvm."
echo ""

# --- 3. Configuração de Permissões Sudo ---
SUDOERS_FILE="/etc/sudoers.d/gvm"
print_info "Configurando permissões de sudo em $SUDOERS_FILE..."

# Cria o arquivo de configuração para o sudo
echo 'gvm ALL = NOPASSWD: /usr/bin/make install, /usr/bin/python3' > "$SUDOERS_FILE"

# Define as permissões de segurança recomendadas para arquivos sudoers
chmod 440 "$SUDOERS_FILE"
print_success "Arquivo de permissões sudo criado."

# --- 4. Validação do Arquivo Sudo ---
print_info "Validando a sintaxe do arquivo sudoers..."

if visudo -c -f "$SUDOERS_FILE"; then
  print_success "Sintaxe do arquivo sudoers está correta."
else
  print_error "Aviso Crítico: A sintaxe do arquivo sudoers está incorreta!"
  print_warning "Removendo o arquivo para evitar problemas de sistema."
  rm -f "$SUDOERS_FILE"
  exit 1
fi

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Configuração do usuário 'gvm' concluída com sucesso!"
echo ""
print_info " Resumo das Ações:"
echo "   - Usuário 'gvm' garantido no sistema."
echo "   - Diretório /opt/gvm configurado e com permissões corretas."
echo "   - Permissões de sudo (make install, python3) concedidas."
print_warning "========================================================================"

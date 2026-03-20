#!/bin/bash

# ==================================================================
# Script: 27-check_gvm_access.sh
#
# Propósito:
# 1. Verifica se o servidor web (gsad) está ativo e ouvindo.
# 2. Configura o firewall (UFW) para permitir tráfego HTTPS.
# 3. Exibe as URLs de acesso disponíveis para o administrador.
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

# --- 1. Verificação do Serviço ---
print_info "Verificando escuta do serviço GSAD na porta 443..."

if ss -lntp | grep -q ':443.*gsad'; then
  print_success "Servidor gsad detectado na porta HTTPS (443)."
else
  print_warning "Serviço gsad não detectado na porta 443. Verifique status do serviço."
fi

# --- 2. Configuração de Firewall ---
print_info "Configurando Firewall (UFW)..."

if command -v ufw &> /dev/null; then
  if ufw status | grep -q "Status: active"; then
    print_info "UFW está ativo. Garantindo porta 443/tcp liberada..."
    ufw allow 443/tcp > /dev/null
    print_success "Regra de firewall aplicada."
  else
    print_info "UFW inativo. Pulando configuração de rede local."
  fi
else
  print_info "UFW não instalado. Certifique-se de que a porta 443 esteja aberta."
fi

# --- 3. URLs de Acesso ---
print_info "Gerando URLs de acesso..."

IPS=$(hostname -I)

echo ""
print_warning "========================================================================"
print_success " Instalação do GVM Concluída com Sucesso!"
echo ""
print_info " Para acessar a interface web, use um dos endereços abaixo:"
for ip in $IPS; do
  echo "   - https://${ip}"
done
echo ""
print_info " Credenciais de Acesso:"
echo "   - Usuário: admin"
echo "   - Senha: (exibida ao final do script 25 - etapa de criação de usuários)"
echo ""
print_warning " IMPORTANTE: Se você não anotou a senha, use a ferramenta:"
echo "             sudo ./gvm_user_manager_tool.sh"
echo "             para alterar a senha do usuário admin."
echo ""
print_warning " Nota: O navegador exibirá um aviso de certificado autoassinado."
print_warning " Clique em 'Avançado' e 'Prosseguir' para acessar."
print_warning "========================================================================"

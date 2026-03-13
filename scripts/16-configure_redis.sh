#!/bin/bash

# ==================================================================
# Script: 16-configure_redis.sh
#
# Propósito:
# 1. Configura o Redis para atuar como base de dados temporária
#    para o OpenVAS Scanner.
# 2. Define as permissões de acesso ao socket Unix do Redis.
# 3. Vincula o usuário 'gvm' ao grupo 'redis' para permitir a
#    comunicação entre o scanner e o banco.
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

# Valida se a variável de ambiente OPENVAS_SCANNER está definida
if [ -z "$OPENVAS_SCANNER" ]; then
  print_error "A variável de ambiente OPENVAS_SCANNER não está definida."
  print_info "Uso correto: sudo OPENVAS_SCANNER=\"23.15.3\" $0"
  exit 1
fi

# --- Variáveis de Ambiente ---
SCANNER_VER="$OPENVAS_SCANNER"
SRC_REDIS="/opt/gvm/gvm-source/openvas-scanner-${SCANNER_VER}/config/redis-openvas.conf"
DST_REDIS="/etc/redis/redis-openvas.conf"
OPENVAS_CONF="/etc/openvas/openvas.conf"

# Verifica se o arquivo de origem existe
if [ ! -f "$SRC_REDIS" ]; then
  print_error "Configuração de origem não encontrada: $SRC_REDIS"
  exit 1
fi

# --- 1. Configuração do Sistema ---
print_info "Atualizando cache de bibliotecas (ldconfig)..."
ldconfig
print_success "Cache atualizado."

# --- 2. Configuração do Redis ---
print_info "Configurando o arquivo Redis para OpenVAS..."

cp "$SRC_REDIS" "$DST_REDIS"
chown redis:redis "$DST_REDIS"
chmod 644 "$DST_REDIS"
print_success "Arquivo $DST_REDIS configurado."

# --- 3. Configuração do OpenVAS ---
print_info "Vinculando o OpenVAS ao socket do Redis..."

# Detecta o caminho do socket no arquivo redis-openvas.conf
SOCKET_PATH=$(grep '^unixsocket ' "$DST_REDIS" | awk '{print $2}')

if [ -z "$SOCKET_PATH" ]; then
  print_error "Não foi possível encontrar o 'unixsocket' em $DST_REDIS."
  exit 1
fi

print_info "Socket detectado: $SOCKET_PATH"

mkdir -p /etc/openvas
echo "db_address = $SOCKET_PATH" > "$OPENVAS_CONF"
print_success "Arquivo $OPENVAS_CONF atualizado."

# --- 4. Gerenciamento de Usuários ---
print_info "Ajustando grupos de sistema..."

if id "gvm" &>/dev/null; then
  usermod -aG redis gvm
  print_success "Usuário 'gvm' adicionado ao grupo 'redis'."
else
  print_warning "Usuário 'gvm' não encontrado. Pulei o ajuste de grupo."
fi

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Configuração do Redis concluída!"
echo ""
print_info " Resumo das Ações:"
echo "   - Arquivo redis-openvas.conf instalado."
echo "   - Socket Unix configurado em $OPENVAS_CONF."
echo "   - Permissões de grupo aplicadas ao usuário 'gvm'."
print_warning "========================================================================"

#!/bin/bash

# ==================================================================
# Script: 03-postgresql.sh
#
# Propósito:
# 1. Adiciona o repositório oficial do PostgreSQL para obter a versão mais recente.
# 2. Instala o PostgreSQL e seus pacotes de desenvolvimento.
# 3. Detecta a versão instalada e configura os arquivos principais
#    (postgresql.conf e pg_hba.conf) para acesso do GVM.
# 4. Cria o usuário 'gvm' e o banco de dados 'gvmd' necessários.
# ==================================================================

# --- Configurações de Segurança e Estilo ---
set -e
set -o pipefail
source "$(dirname "$0")/style.sh"

# --- Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  print_error "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Instalação do PostgreSQL ---
print_info "Iniciando a instalação do PostgreSQL..."

print_info "Configurando o repositório oficial do PostgreSQL..."
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg

print_info "Atualizando a lista de pacotes após adicionar o novo repositório..."
apt-get update

print_info "Instalando PostgreSQL, contrib e pacotes de desenvolvimento..."
apt-get install -y postgresql postgresql-contrib postgresql-server-dev-all

print_success "PostgreSQL instalado com sucesso."
echo ""

# --- 2. Configuração dos Arquivos ---
print_info "Detectando a versão do PostgreSQL instalada..."
PG_VERSION=$(find /etc/postgresql/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort -V | tail -n 1)

if [ -z "$PG_VERSION" ]; then
    print_error "Nenhuma instalação do PostgreSQL foi encontrada em /etc/postgresql/."
    exit 1
fi

print_info "Configurando o PostgreSQL para a versão $PG_VERSION..."
CONF_DIR="/etc/postgresql/$PG_VERSION/main"
POSTGRESQL_CONF="$CONF_DIR/postgresql.conf"
PG_HBA_CONF="$CONF_DIR/pg_hba.conf"

if [ ! -f "$POSTGRESQL_CONF" ] || [ ! -f "$PG_HBA_CONF" ]; then
    print_error "Arquivos de configuração não encontrados no diretório esperado: $CONF_DIR"
    exit 1
fi

print_info "Fazendo backup e modificando 'postgresql.conf' para aceitar conexões..."
cp "$POSTGRESQL_CONF" "$POSTGRESQL_CONF.bak.$(date +%Y-%m-%d_%H-%M-%S)"
sed -i "s/^[#\s]*listen_addresses\s*=.*/listen_addresses = '*'/" "$POSTGRESQL_CONF"

print_info "Fazendo backup e sobrescrevendo 'pg_hba.conf' para autenticação do GVM..."
cp "$PG_HBA_CONF" "$PG_HBA_CONF.bak.$(date +%Y-%m-%d_%H-%M-%S)"
cat > "$PG_HBA_CONF" << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# Conexões locais via socket Unix para postgres e gvm
local   all             postgres                                peer
local   all             gvm                                     peer
# Conexões locais via socket para outros usuários
local   all             all                                     scram-sha-256
# Conexões locais IPv4
host    all             all             127.0.0.1/32            scram-sha-256
# Conexões locais IPv6
host    all             all             ::1/128                 scram-sha-256
# Conexões de replicação
local   replication     all                                     scram-sha-256
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
EOF

print_success "Arquivos de configuração atualizados."
echo ""

# --- 3. Preparação do Banco de Dados ---
print_info "Finalizando a configuração do banco de dados..."

print_info "Habilitando e reiniciando o serviço PostgreSQL..."
systemctl enable postgresql
systemctl restart postgresql

print_info "Aguardando 5 segundos para o serviço iniciar completamente..."
sleep 5

print_info "Definindo a senha do usuário 'postgres' como 'pgadmin'..."
if sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'pgadmin';" > /dev/null 2>&1; then
    print_success "Senha do superusuário 'postgres' alterada."
else
    print_warning "Não foi possível alterar a senha do usuário 'postgres'. Isso pode não ser um problema se já estiver definida."
fi

print_info "Criando usuário 'gvm' e banco de dados 'gvmd'..."
sudo -Hiu postgres createuser gvm
sudo -Hiu postgres createdb -O gvm gvmd
print_success "Usuário 'gvm' e banco de dados 'gvmd' criados."

print_info "Concedendo permissões de DBA ao usuário 'gvm'..."
sudo -Hiu postgres psql gvmd -c "CREATE ROLE dba WITH SUPERUSER NOINHERIT;"
sudo -Hiu postgres psql gvmd -c "GRANT dba TO gvm;"
print_success "Permissões de superusuário concedidas a 'gvm'."
echo ""

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Script concluído! O PostgreSQL foi instalado e preparado."
echo ""
print_info " Resumo das Ações:"
echo "   - PostgreSQL instalado (versão $PG_VERSION)."
echo "   - Configurado para aceitar conexões de qualquer IP."
echo "   - Serviço PostgreSQL habilitado para iniciar no boot."
echo "   - Serviço reiniciado."
echo "   - A senha do superusuário 'postgres' foi definida como 'pgadmin'."
echo "   - Usuário 'gvm' criado."
echo "   - Banco de dados 'gvmd' criado e associado ao usuário 'gvm'."
echo "   - Permissões de DBA concedidas ao 'gvm'."
print_warning "========================================================================"
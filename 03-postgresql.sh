#!/bin/bash

# ==================================================================
# Script para Instalar, Configurar e Preparar o PostgreSQL no Ubuntu/Debian
#
# O que ele faz:
# 1. Verifica se está sendo executado como root (sudo).
# 2. Adiciona o repositório oficial do PostgreSQL.
# 3. Instala a última versão do PostgreSQL.
# 4. Detecta automaticamente a versão instalada.
# 5. Configura 'listen_addresses = "*"' no postgresql.conf.
# 6. Substitui o conteúdo de pg_hba.conf para permitir conexões.
# 7. Habilita e reinicia o serviço do PostgreSQL.
# 8. Define a senha do usuário 'postgres' como 'pgadmin'.
# 9. Cria o usuário 'gvm' e o banco de dados 'gvmd' com as devidas permissões.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Instalação do PostgreSQL ---
echo "--- Iniciando a Instalação do PostgreSQL ---"

echo "1. Configurando o repositório do PostgreSQL..."
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

echo "2. Adicionando a chave de assinatura do repositório..."
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg

echo "3. Atualizando a lista de pacotes (apt update)..."
apt-get update

echo "4. Instalando PostgreSQL, contrib e pacotes de desenvolvimento..."
apt-get install postgresql postgresql-contrib postgresql-server-dev-all -y

if [ $? -ne 0 ]; then
    echo "ERRO: A instalação do PostgreSQL falhou. Abortando."
    exit 1
fi

echo "PostgreSQL instalado com sucesso."
echo ""


# --- 2. Configuração dos Arquivos ---

PG_VERSION=$(find /etc/postgresql/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort -V | tail -n 1)

if [ -z "$PG_VERSION" ]; then
    echo "ERRO: Nenhuma instalação do PostgreSQL foi encontrada em /etc/postgresql/."
    exit 1
fi

echo "--- Iniciando a Configuração para a Versão $PG_VERSION ---"

CONF_DIR="/etc/postgresql/$PG_VERSION/main"
POSTGRESQL_CONF="$CONF_DIR/postgresql.conf"
PG_HBA_CONF="$CONF_DIR/pg_hba.conf"

if [ ! -f "$POSTGRESQL_CONF" ] || [ ! -f "$PG_HBA_CONF" ]; then
    echo "ERRO: Arquivos de configuração não encontrados em $CONF_DIR"
    exit 1
fi

echo "Configurando $POSTGRESQL_CONF e $PG_HBA_CONF..."
cp "$POSTGRESQL_CONF" "$POSTGRESQL_CONF.bak.$(date +%Y-%m-%d_%H-%M-%S)"
sed -i "s/^[#\s]*listen_addresses\s*=.*/listen_addresses = '*'/" "$POSTGRESQL_CONF"

cp "$PG_HBA_CONF" "$PG_HBA_CONF.bak.$(date +%Y-%m-%d_%H-%M-%S)"
cat > "$PG_HBA_CONF" << EOF
# Database administrative login by Unix domain socket
local   all             postgres                                peer
local   all             gvm                                     peer
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     scram-sha-256
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     scram-sha-256
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
EOF

echo "Arquivos de configuração atualizados."
echo ""


# --- 3. Finalização e Preparação do Banco de Dados ---

echo "--- Finalizando a configuração ---"

echo "1. Habilitando o serviço PostgreSQL para iniciar com o sistema..."
systemctl enable postgresql

echo "2. Reiniciando o serviço PostgreSQL para aplicar as alterações..."
systemctl restart postgresql

echo "3. Aguardando 5 segundos para o serviço iniciar completamente..."
sleep 5

echo "4. Alterando a senha do usuário 'postgres' para 'pgadmin'..."
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'pgadmin';" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   - Senha do superusuário 'postgres' alterada com sucesso."
else
    echo "   - AVISO: Falha ao tentar alterar a senha do usuário 'postgres'."
fi

echo "5. Criando o usuário e o banco de dados para GVM..."
sudo -Hiu postgres createuser gvm
sudo -Hiu postgres createdb -O gvm gvmd
echo "   - Usuário 'gvm' e banco de dados 'gvmd' criados."

echo "6. Concedendo permissões de superusuário ao usuário 'gvm' no banco de dados 'gvmd'..."
sudo -Hiu postgres psql gvmd -c "CREATE ROLE dba WITH SUPERUSER NOINHERIT;"
sudo -Hiu postgres psql gvmd -c "GRANT dba TO gvm;"
echo "   - Permissões concedidas."


# --- Conclusão ---
echo ""
echo "========================================================================"
echo " Script concluído! O PostgreSQL foi instalado e preparado."
echo ""
echo " Resumo das Ações:"
echo "   - PostgreSQL instalado (versão $PG_VERSION)."
echo "   - Configurado para aceitar conexões de qualquer IP."
echo "   - Serviço PostgreSQL habilitado para iniciar no boot."
echo "   - Serviço reiniciado."
echo "   - A senha do superusuário 'postgres' foi definida como 'pgadmin'."
echo "   - Usuário 'gvm' criado."
echo "   - Banco de dados 'gvmd' criado e associado ao usuário 'gvm'."
echo "   - Permissões de DBA concedidas ao 'gvm'."
echo "========================================================================"
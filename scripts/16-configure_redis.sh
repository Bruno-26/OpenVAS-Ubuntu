#!/bin/bash

# ==================================================================
# Script para configurar o Redis para o OpenVAS Scanner.
#
# O que ele faz:
# 1. Atualiza o cache de bibliotecas compartilhadas.
# 2. Copia o arquivo de configuração do Redis para OpenVAS.
# 3. Define as permissões corretas para o arquivo.
# 4. Detecta automaticamente o caminho do socket Redis no arquivo.
# 5. Configura o openvas.conf com o caminho do socket detectado.
# 6. Adiciona o usuário 'gvm' ao grupo 'redis'.
#
# REQUISITO: A variável de ambiente OPENVAS_SCANNER deve estar definida.
#
# Exemplo de uso:
#   export OPENVAS_SCANNER="23.15.3"
#   sudo OPENVAS_SCANNER="$OPENVAS_SCANNER" ./configure_redis.sh
# ==================================================================

# --- 0. Verificações Iniciais ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

if [ -z "$OPENVAS_SCANNER" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! ERRO: A variável de ambiente OPENVAS_SCANNER não está definida.!!!"
    echo "!!!                                                          !!!"
    echo "!!! Execute o script da seguinte forma:                      !!!"
    echo "!!!   sudo OPENVAS_SCANNER=\"<versao>\" $0                     !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# Define variáveis
OPENVAS_SCANNER_VERSION="$OPENVAS_SCANNER"
SOURCE_REDIS_CONF="/opt/gvm/gvm-source/openvas-scanner-${OPENVAS_SCANNER_VERSION}/config/redis-openvas.conf"
DEST_REDIS_CONF="/etc/redis/redis-openvas.conf"
OPENVAS_CONF="/etc/openvas/openvas.conf"

# Verifica se o arquivo de configuração de origem existe
if [ ! -f "$SOURCE_REDIS_CONF" ]; then
    echo "ERRO: O arquivo de configuração de origem não foi encontrado em: $SOURCE_REDIS_CONF"
    echo "Verifique se a versão ${OPENVAS_SCANNER_VERSION} foi compilada e se a variável está correta."
    exit 1
fi

# --- 1. Configuração do Sistema ---
echo "--- Iniciando a configuração ---"
echo "1. Atualizando o cache de bibliotecas compartilhadas (ldconfig)..."
ldconfig
echo ""

# --- 2. Configuração do Redis ---
echo "--- Configurando o Redis ---"
echo "1. Copiando o arquivo de configuração '$DEST_REDIS_CONF'..."
cp "$SOURCE_REDIS_CONF" "$DEST_REDIS_CONF"

echo "2. Definindo a propriedade do arquivo para redis:redis..."
chown redis:redis "$DEST_REDIS_CONF"
echo ""

# --- 3. Configuração do OpenVAS ---
echo "--- Configurando o OpenVAS para usar o Redis ---"
echo "1. Detectando o caminho do socket no arquivo de configuração do Redis..."

# Extrai a linha que começa com "unixsocket " e pega a segunda coluna (o caminho)
REDIS_SOCKET_PATH=$(grep '^unixsocket ' "$DEST_REDIS_CONF" | awk '{print $2}')

# Verifica se a extração foi bem-sucedida
if [ -z "$REDIS_SOCKET_PATH" ]; then
    echo "ERRO: Não foi possível encontrar o caminho do 'unixsocket' em $DEST_REDIS_CONF."
    exit 1
fi

echo "   - Socket encontrado: $REDIS_SOCKET_PATH"

# Garante que o diretório de configuração do OpenVAS exista
mkdir -p /etc/openvas

echo "2. Escrevendo o caminho do socket no arquivo '$OPENVAS_CONF'..."
echo "db_address = $REDIS_SOCKET_PATH" | tee "$OPENVAS_CONF"
echo ""

# --- 4. Gerenciamento de Usuários ---
echo "--- Ajustando permissões de usuário ---"
echo "1. Adicionando o usuário 'gvm' ao grupo 'redis'..."
usermod -aG redis gvm
echo ""

# --- Conclusão ---
echo "================================================="
echo " Configuração do Redis para OpenVAS concluída!"
echo " O usuário 'gvm' agora pode acessar o socket do Redis."
echo "================================================="

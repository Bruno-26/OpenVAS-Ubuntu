#!/bin/bash

# ==================================================================
# Script para configurar o Mosquitto MQTT Broker para GVM.
#
# O que ele faz:
# 1. Configura o OpenVAS para usar o broker Mosquitto local.
# 2. Habilita e inicia o serviço mosquitto.
# 3. Verifica se o serviço foi iniciado corretamente e está
#    escutando na porta 1883.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Configuração do OpenVAS ---
echo "--- Configurando o OpenVAS para usar o Mosquitto MQTT Broker ---"
OPENVAS_CONF="/etc/openvas/openvas.conf"

# Garante que o diretório de configuração do OpenVAS exista
mkdir -p /etc/openvas

# Adiciona a configuração do servidor MQTT se não existir
if ! grep -q "^mqtt_server_uri" "$OPENVAS_CONF"; then
    echo "1. Adicionando 'mqtt_server_uri = localhost:1883' em $OPENVAS_CONF..."
    echo "mqtt_server_uri = localhost:1883" >> "$OPENVAS_CONF"
else
    echo "1. Configuração 'mqtt_server_uri' já existe."
fi

# Adiciona a configuração da abordagem de escaneamento se não existir
if ! grep -q "^table_driven_lsc" "$OPENVAS_CONF"; then
    echo "2. Adicionando 'table_driven_lsc = yes' em $OPENVAS_CONF..."
    echo "table_driven_lsc = yes" >> "$OPENVAS_CONF"
else
    echo "2. Configuração 'table_driven_lsc' já existe."
fi
echo ""

# --- 2. Gerenciamento do Serviço Mosquitto ---
echo "--- Gerenciando o serviço Mosquitto ---"
MOSQUITTO_SERVICE="mosquitto"

echo "1. Habilitando e iniciando o serviço '$MOSQUITTO_SERVICE'..."
systemctl enable --now "$MOSQUITTO_SERVICE"

# Aguarda um momento para o serviço estabilizar
sleep 2

echo "2. Verificando o status do serviço..."
if systemctl is-active --quiet "$MOSQUITTO_SERVICE"; then
    echo "   - SUCESSO: O serviço '$MOSQUITTO_SERVICE' está ativo e em execução."
else
    echo "   - ERRO: O serviço '$MOSQUITTO_SERVICE' falhou ao iniciar."
    echo "     Verifique o status com: systemctl status $MOSQUITTO_SERVICE"
    exit 1
fi

echo "3. Verificando se o serviço está escutando na porta 1883..."
# '-l' para listening, '-n' para numérico, '-t' para tcp, '-p' para processo
if ss -lntp | grep -q ":1883"; then
    echo "   - SUCESSO: O serviço está escutando na porta 1883."
    ss -lntp | grep ":1883"
else
    echo "   - AVISO: O serviço está ativo, mas não foi encontrado escutando na porta 1883."
fi
echo ""

# --- Conclusão ---
echo "================================================="
echo " Configuração do Mosquitto concluída!"
echo "================================================="

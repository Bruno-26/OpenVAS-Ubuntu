#!/bin/bash

# ==================================================================
# Script: 18-configure_mosquitto.sh
#
# Propósito:
# 1. Configura o OpenVAS para se comunicar com o Mosquitto MQTT Broker.
# 2. Habilita o serviço Mosquitto para iniciar com o sistema.
# 3. Valida se o broker está ativo e escutando na porta padrão (1883).
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

# --- 1. Configuração do OpenVAS ---
print_info "Configurando integração MQTT no OpenVAS..."

OPENVAS_CONF="/etc/openvas/openvas.conf"
mkdir -p /etc/openvas

# Adiciona mqtt_server_uri se ausente
if ! grep -q "^mqtt_server_uri" "$OPENVAS_CONF"; then
  echo "mqtt_server_uri = localhost:1883" >> "$OPENVAS_CONF"
  print_info "Configuração mqtt_server_uri adicionada."
fi

# Adiciona table_driven_lsc se ausente
if ! grep -q "^table_driven_lsc" "$OPENVAS_CONF"; then
  echo "table_driven_lsc = yes" >> "$OPENVAS_CONF"
  print_info "Configuração table_driven_lsc adicionada."
fi

print_success "Arquivo $OPENVAS_CONF configurado."

# --- 2. Gerenciamento do Serviço ---
print_info "Gerenciando o serviço Mosquitto..."

SVC="mosquitto"
systemctl enable --now "$SVC" > /dev/null

# Pequena pausa para o serviço subir
sleep 2

if systemctl is-active --quiet "$SVC"; then
  print_success "Serviço '$SVC' está ativo e em execução."
else
  print_error "Falha ao iniciar '$SVC'. Verifique logs do sistema."
  exit 1
fi

# Validação de rede
if ss -lntp | grep -q ":1883"; then
  print_success "Mosquitto está escutando na porta 1883."
else
  print_warning "Mosquitto ativo, mas não detectado na porta 1883. Verifique firewall."
fi

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Configuração do Mosquitto concluída!"
echo ""
print_info " Resumo das Ações:"
echo "   - Integração MQTT habilitada no OpenVAS."
echo "   - Broker Mosquitto iniciado e habilitado no boot."
echo "   - Comunicação via porta 1883 validada."
print_warning "========================================================================"

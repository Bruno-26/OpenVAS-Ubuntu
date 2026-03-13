#!/bin/bash

# ==================================================================
# Script: 17-optimize_redis_system.sh
#
# Propósito:
# 1. Otimiza parâmetros do Kernel para alto desempenho do Redis.
# 2. Desativa o Transparent Huge Pages (THP) para evitar latências
#    durante as varreduras de vulnerabilidade.
# 3. Inicia e habilita o serviço Redis dedicado ao OpenVAS.
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

# --- 1. Otimização do Kernel ---
print_info "Otimizando parâmetros do Kernel em /etc/sysctl.conf..."

SYSCTL_CONF="/etc/sysctl.conf"

# Adiciona somaxconn se ausente
if ! grep -q "^net.core.somaxconn" "$SYSCTL_CONF"; then
  echo "net.core.somaxconn = 1024" >> "$SYSCTL_CONF"
  print_info "Parâmetro net.core.somaxconn adicionado."
fi

# Adiciona overcommit_memory se ausente
if ! grep -q "^vm.overcommit_memory" "$SYSCTL_CONF"; then
  echo "vm.overcommit_memory = 1" >> "$SYSCTL_CONF"
  print_info "Parâmetro vm.overcommit_memory adicionado."
fi

print_info "Aplicando novas configurações do sysctl..."
sysctl -p > /dev/null
print_success "Kernel otimizado com sucesso."

# --- 2. Desativação do THP ---
print_info "Desativando Transparent Huge Pages (THP)..."

THP_SERVICE="/etc/systemd/system/disable_thp.service"

cat > "$THP_SERVICE" << 'EOF'
[Unit]
Description=Disable Kernel Support for Transparent Huge Pages (THP)
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now disable_thp > /dev/null
print_success "Serviço disable_thp configurado e iniciado."

# --- 3. Gerenciamento do Serviço Redis ---
print_info "Iniciando serviço Redis para OpenVAS..."

REDIS_SVC="redis-server@openvas"
systemctl enable --now "$REDIS_SVC" > /dev/null

# Pequena pausa para o serviço subir
sleep 2

if systemctl is-active --quiet "$REDIS_SVC"; then
  print_success "Serviço '$REDIS_SVC' está ativo e em execução."
else
  print_error "Falha ao iniciar '$REDIS_SVC'. Verifique logs do sistema."
  exit 1
fi

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Otimização do sistema e Redis concluída!"
echo ""
print_info " Resumo das Ações:"
echo "   - Parâmetros do Kernel (sysctl) aplicados."
echo "   - Transparent Huge Pages (THP) desativado."
echo "   - Instância Redis dedicada (openvas) em execução."
print_warning "========================================================================"

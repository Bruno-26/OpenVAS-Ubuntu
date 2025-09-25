#!/bin/bash

# ==================================================================
# Script para otimizar o Kernel e o Redis para GVM/OpenVAS.
#
# O que ele faz:
# 1. Ajusta os parâmetros do kernel 'net.core.somaxconn' e
#    'vm.overcommit_memory' para melhor desempenho do Redis.
# 2. Cria e habilita um serviço systemd para desativar
#    Transparent Huge Pages (THP), prevenindo latência.
# 3. Habilita e inicia o serviço Redis específico para OpenVAS.
# 4. Verifica se o serviço Redis foi iniciado com sucesso.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Otimização dos Parâmetros do Kernel ---
echo "--- Otimizando os parâmetros do Kernel via sysctl ---"
SYSCTL_CONF="/etc/sysctl.conf"

# Aumenta o somaxconn se não estiver definido
if ! grep -q "^net.core.somaxconn" "$SYSCTL_CONF"; then
    echo "1. Adicionando 'net.core.somaxconn = 1024' em $SYSCTL_CONF..."
    echo "net.core.somaxconn = 1024" >> "$SYSCTL_CONF"
else
    echo "1. Configuração 'net.core.somaxconn' já existe."
fi

# Habilita o overcommit_memory se não estiver definido
if ! grep -q "^vm.overcommit_memory" "$SYSCTL_CONF"; then
    echo "2. Adicionando 'vm.overcommit_memory = 1' em $SYSCTL_CONF..."
    echo 'vm.overcommit_memory = 1' >> "$SYSCTL_CONF"
else
    echo "2. Configuração 'vm.overcommit_memory' já existe."
fi

echo "3. Aplicando as novas configurações do sysctl..."
sysctl -p
echo ""

# --- 2. Desativação do Transparent Huge Pages (THP) ---
echo "--- Desativando o Transparent Huge Pages (THP) para prevenir latência ---"
THP_SERVICE_FILE="/etc/systemd/system/disable_thp.service"

echo "1. Criando o serviço systemd em '$THP_SERVICE_FILE'..."
tee "$THP_SERVICE_FILE" > /dev/null << 'EOL'
[Unit]
Description=Disable Kernel Support for Transparent Huge Pages (THP)
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOL

echo "2. Recarregando as configurações do systemd..."
systemctl daemon-reload

echo "3. Habilitando e iniciando o serviço 'disable_thp'..."
systemctl enable --now disable_thp
echo ""

# --- 3. Gerenciamento do Serviço Redis ---
echo "--- Gerenciando o serviço Redis para OpenVAS ---"
REDIS_SERVICE="redis-server@openvas"

echo "1. Habilitando e iniciando o serviço '$REDIS_SERVICE'..."
# O systemctl enable --now faz as duas coisas de uma vez
systemctl enable --now "$REDIS_SERVICE"

# Aguarda um momento para o serviço estabilizar
sleep 2

echo "2. Verificando o status do serviço..."
# '--quiet' previne a saída, apenas retorna o código de status
systemctl is-active --quiet "$REDIS_SERVICE"
if [ $? -eq 0 ]; then
    echo "   - SUCESSO: O serviço '$REDIS_SERVICE' está ativo e em execução."
else
    echo "   - AVISO: O serviço '$REDIS_SERVICE' falhou ao iniciar."
    echo "     Por favor, verifique o status com: systemctl status $REDIS_SERVICE"
    echo "     E os logs com: journalctl -u $REDIS_SERVICE"
fi
echo ""

# --- Conclusão ---
echo "================================================="
echo " Otimização do sistema e do Redis concluída!"
echo "================================================="

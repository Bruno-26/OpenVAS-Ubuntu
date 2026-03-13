#!/bin/bash

# ==================================================================
# Script: 23-setup_services.sh
#
# Propósito:
# 1. Cria e configura os arquivos de serviço systemd para os
#    quatro componentes principais do GVM.
# 2. Gera certificados TLS para comunicação interna segura.
# 3. Inicia e habilita os daemons na ordem correta de dependência.
# 4. Valida se todos os serviços estão operacionais.
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

# --- 1. Detecção do Ambiente ---
print_info "Detectando ambiente de serviços..."

PYTHON_VER=$(python3 -c 'import sys; print(f"python{sys.version_info.major}.{sys.version_info.minor}")')
PYTHON_LIB="/usr/local/lib/${PYTHON_VER}/site-packages/"
GSAD_BIN=$(which gsad || echo "/usr/local/sbin/gsad")

print_info "Python Lib: $PYTHON_LIB"
print_info "GSAD Bin: $GSAD_BIN"

# --- 2. Certificados TLS ---
print_info "Gerenciando certificados TLS..."

if [ -f /var/lib/gvm/CA/clientcert.pem ]; then
  print_info "Certificados existentes encontrados. Pulando geração."
else
  print_info "Gerando novos certificados (gvm-manage-certs)..."
  sudo -Hiu gvm gvm-manage-certs -a > /dev/null
  print_success "Certificados gerados com sucesso."
fi

# --- 3. Sudo para GSAD ---
print_info "Configurando sudo para o daemon web..."

SUDOERS_FILE="/etc/sudoers.d/gvm"
RULE="gvm ALL = NOPASSWD: $GSAD_BIN"

if ! grep -qF "$RULE" "$SUDOERS_FILE"; then
  echo "$RULE" >> "$SUDOERS_FILE"
  print_success "Regra de sudo para gsad adicionada."
fi

# --- 4. Arquivos de Serviço Systemd ---
print_info "Criando unidades de serviço em /etc/systemd/system/..."

# OSPD-OpenVAS
cat > /etc/systemd/system/ospd-openvas.service << EOL
[Unit]
Description=OSPd Wrapper for the OpenVAS Scanner (ospd-openvas)
After=network.target networking.service redis-server@openvas.service mosquitto.service
Wants=redis-server@openvas.service mosquitto.service

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=ospd
RuntimeDirectoryMode=2775
PIDFile=/run/ospd/ospd-openvas.pid
Environment="PYTHONPATH=${PYTHON_LIB}"
ExecStartPre=-rm -rf /run/ospd/ospd-openvas.pid /run/ospd/ospd-openvas.sock
ExecStart=/usr/local/bin/ospd-openvas --foreground --unix-socket /run/ospd/ospd-openvas.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas --socket-mode 0770 --mqtt-broker-address localhost --mqtt-broker-port 1883 --notus-feed-dir /var/lib/notus/advisories
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOL

# Notus Scanner
cat > /etc/systemd/system/notus-scanner.service << EOL
[Unit]
Description=Notus Scanner
After=mosquitto.service
Wants=mosquitto.service

[Service]
Type=exec
User=gvm
RuntimeDirectory=notus-scanner
RuntimeDirectoryMode=2775
PIDFile=/run/notus-scanner/notus-scanner.pid
Environment="PYTHONPATH=${PYTHON_LIB}"
ExecStart=/usr/local/bin/notus-scanner --foreground --products-directory /var/lib/notus/products --log-file /var/log/gvm/notus-scanner.log
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOL

# GVMD
cat > /usr/local/lib/systemd/system/gvmd.service << EOL
[Unit]
Description=Greenbone Vulnerability Manager daemon (gvmd)
After=network.target networking.service postgresql.service ospd-openvas.service
Wants=postgresql.service ospd-openvas.service
Documentation=man:gvmd(8)

[Service]
Type=exec
User=gvm
Group=gvm
PIDFile=/run/gvmd/gvmd.pid
RuntimeDirectory=gvmd
RuntimeDirectoryMode=2775
ExecStart=/usr/local/sbin/gvmd --foreground --osp-vt-update=/run/ospd/ospd-openvas.sock --listen-group=gvm
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOL

# GSAD
cat > /usr/local/lib/systemd/system/gsad.service << EOL
[Unit]
Description=Greenbone Security Assistant daemon (gsad)
Documentation=man:gsad(8) https://www.greenbone.net
After=network.target gvmd.service
Wants=gvmd.service

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=gsad
RuntimeDirectoryMode=2775
PIDFile=/run/gsad/gsad.pid
ExecStart=/usr/bin/sudo $GSAD_BIN --foreground -k /var/lib/gvm/private/CA/clientkey.pem -c /var/lib/gvm/CA/clientcert.pem
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
Alias=greenbone-security-assistant.service
EOL

print_success "Arquivos systemd preparados."

# --- 5. Ativação dos Serviços ---
print_info "Iniciando daemons do GVM..."

systemctl daemon-reload

start_svc() {
  local svc="$1"
  print_info "Iniciando $svc..."
  systemctl enable --now "$svc" > /dev/null
  sleep 2
  if systemctl is-active --quiet "$svc"; then
    print_success "Serviço '$svc' operacional."
  else
    print_error "Falha crítica no serviço '$svc'."
  fi
}

start_svc "ospd-openvas"
start_svc "notus-scanner"
start_svc "gvmd"
start_svc "gsad"

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Configuração de serviços GVM finalizada!"
echo ""
print_info " Resumo das Ações:"
echo "   - Certificados TLS garantidos."
echo "   - Quatro serviços systemd configurados e iniciados."
echo "   - O GVM agora está pronto para acesso via navegador."
print_warning "========================================================================"

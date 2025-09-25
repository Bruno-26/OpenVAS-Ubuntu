#!/bin/bash

# ==================================================================
# Script para criar, configurar e iniciar todos os serviços GVM.
#
# O que ele faz:
# 1. Detecta o caminho correto das bibliotecas Python.
# 2. Cria/Atualiza os arquivos de serviço para ospd-openvas,
#    notus-scanner, gvmd, e gsad.
# 3. Gera os certificados TLS para gvmd/gsad (apenas se necessário).
# 4. Configura as permissões de sudo para gsad.
# 5. Recarrega, habilita e inicia todos os serviços na ordem correta,
#    verificando o status de cada um.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Detecção do Ambiente e Pré-requisitos ---
echo "--- Detectando o ambiente e verificando pré-requisitos ---"
PYTHON_VERSION_DIR=$(python3 -c 'import sys; print(f"python{sys.version_info.major}.{sys.version_info.minor}")')
if [ -z "$PYTHON_VERSION_DIR" ]; then
    echo "ERRO: Não foi possível determinar a versão do Python 3."
    exit 1
fi

# Força o uso de 'site-packages', que é o padrão para instalações manuais em /usr/local
PYTHON_LIB_PATH="/usr/local/lib/${PYTHON_VERSION_DIR}/site-packages/"
echo "Caminho da biblioteca Python definido como: $PYTHON_LIB_PATH"

GSAD_PATH=$(which gsad)
if [ -z "$GSAD_PATH" ]; then
    echo "ERRO: O executável 'gsad' não foi encontrado no PATH. A instalação pode ter falhado."
    exit 1
fi
echo "Executável 'gsad' encontrado em: $GSAD_PATH"
echo ""

# --- 2. Geração de Certificados (apenas se necessário) ---
echo "--- Gerenciando os certificados TLS ---"
if [ -f /var/lib/gvm/CA/clientcert.pem ]; then
    echo "Certificados já encontrados. Pulando a geração."
else
    echo "Certificados não encontrados. Gerando novos certificados..."
    sudo -Hiu gvm gvm-manage-certs -a
fi
echo ""

# --- 3. Configuração de Permissões Sudo para GSAD ---
echo "--- Configurando permissões de sudo para o serviço 'gsad' ---"
SUDOERS_FILE="/etc/sudoers.d/gvm"
SUDO_RULE="gvm ALL = NOPASSWD: $GSAD_PATH"

if ! grep -qF "$SUDO_RULE" "$SUDOERS_FILE"; then
    echo "1. Adicionando a regra de sudo para gsad..."
    echo "$SUDO_RULE" >> "$SUDOERS_FILE"
    visudo -c -f "$SUDOERS_FILE"
    if [ $? -ne 0 ]; then
        echo "ERRO CRÍTICO: A sintaxe do arquivo sudoers está incorreta!"
        exit 1
    fi
else
    echo "1. A regra de sudo para 'gsad' já existe."
fi
echo ""

# --- 4. Criação dos Arquivos de Serviço ---
echo "--- Criando/Atualizando os arquivos de serviço systemd ---"

# --- OSPD-OpenVAS ---
tee /etc/systemd/system/ospd-openvas.service > /dev/null << EOL
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
Environment="PYTHONPATH=${PYTHON_LIB_PATH}"
ExecStartPre=-rm -rf /run/ospd/ospd-openvas.pid /run/ospd/ospd-openvas.sock
ExecStart=/usr/local/bin/ospd-openvas --foreground --unix-socket /run/ospd/ospd-openvas.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas --socket-mode 0770 --mqtt-broker-address localhost --mqtt-broker-port 1883 --notus-feed-dir /var/lib/notus/advisories
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60
[Install]
WantedBy=multi-user.target
EOL
echo "Arquivo de serviço 'ospd-openvas.service' criado."

# --- Notus Scanner ---
tee /etc/systemd/system/notus-scanner.service > /dev/null << EOL
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
Environment="PYTHONPATH=${PYTHON_LIB_PATH}"
ExecStart=/usr/local/bin/notus-scanner --foreground --products-directory /var/lib/notus/products --log-file /var/log/gvm/notus-scanner.log
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60
[Install]
WantedBy=multi-user.target
EOL
echo "Arquivo de serviço 'notus-scanner.service' criado."

# --- GVMD ---
GVMD_SERVICE_FILE="/usr/local/lib/systemd/system/gvmd.service"
if [ -f "$GVMD_SERVICE_FILE" ] && [ ! -f "${GVMD_SERVICE_FILE}.bak" ]; then
    cp "$GVMD_SERVICE_FILE" "${GVMD_SERVICE_FILE}.bak"
    echo "Backup de '$GVMD_SERVICE_FILE' criado."
fi
tee "$GVMD_SERVICE_FILE" > /dev/null << EOL
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
echo "Arquivo de serviço 'gvmd.service' atualizado."

# --- GSAD ---
GSAD_SERVICE_FILE="/usr/local/lib/systemd/system/gsad.service"
if [ -f "$GSAD_SERVICE_FILE" ] && [ ! -f "${GSAD_SERVICE_FILE}.bak" ]; then
    cp "$GSAD_SERVICE_FILE" "${GSAD_SERVICE_FILE}.bak"
    echo "Backup de '$GSAD_SERVICE_FILE' criado."
fi
tee "$GSAD_SERVICE_FILE" > /dev/null << EOL
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
ExecStart=/usr/bin/sudo /usr/local/sbin/gsad --foreground -k /var/lib/gvm/private/CA/clientkey.pem -c /var/lib/gvm/CA/clientcert.pem
Restart=always
TimeoutStopSec=10
[Install]
WantedBy=multi-user.target
Alias=greenbone-security-assistant.service
EOL
echo "Arquivo de serviço 'gsad.service' atualizado."
echo ""

# --- 5. Gerenciamento dos Serviços ---
echo "--- Habilitando e iniciando todos os serviços na ordem correta ---"
echo "1. Recarregando as configurações do systemd..."
systemctl daemon-reload

start_and_check_service() {
    local service_name="$1"
    echo ""
    echo "Habilitando e iniciando o serviço '$service_name'..."
    systemctl enable --now "$service_name"
    echo "Aguardando 2 segundos para o serviço estabilizar..."
    sleep 2
    if systemctl is-active --quiet "$service_name"; then
        echo "   - SUCESSO: O serviço '$service_name' está ativo e em execução."
    else
        echo "   - ERRO: O serviço '$service_name' falhou ao iniciar."
        echo "     Verifique o status com: systemctl status $service_name"
    fi
}

# Inicia os serviços na ordem de dependência
start_and_check_service "ospd-openvas"
start_and_check_service "notus-scanner"
start_and_check_service "gvmd"
start_and_check_service "gsad"
echo ""

# --- Conclusão ---
echo "======================================================================"
echo " Configuração de todos os serviços GVM concluída!"
echo " O sistema deve estar operacional. Acesse a interface web para verificar."
echo ""
echo " Comandos úteis para verificar os logs:"
echo "   sudo tail -f /var/log/gvm/ospd-openvas.log"
echo "   sudo tail -f /var/log/gvm/notus-scanner.log"
echo "   sudo tail -f /var/log/gvm/gvmd.log"
echo "   sudo tail -f /var/log/gvm/gsad.log"
echo "======================================================================"

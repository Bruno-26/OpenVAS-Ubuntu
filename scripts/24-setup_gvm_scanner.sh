#!/bin/bash

# ==================================================================
# Script: 24-setup_gvm_scanner.sh
#
# Propósito:
# 1. Registra o scanner OpenVAS personalizado no gvmd.
# 2. Vincula o scanner ao socket Unix do OSPD-OpenVAS.
# 3. Realiza a verificação de conectividade entre o manager e o scanner.
# 4. Garante que o motor de busca esteja pronto para varreduras.
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

# --- 1. Definições ---
SCAN_NAME="Scanner OpenVAS Principal"
SCAN_TYPE="OpenVAS"
SCAN_SOCKET="/run/ospd/ospd-openvas.sock"
GVMD_BIN="/usr/local/sbin/gvmd"

print_info "Verificando ambiente do gvmd..."

if [ ! -x "$GVMD_BIN" ]; then
  print_error "Executável gvmd não encontrado em $GVMD_BIN."
  exit 1
fi

# --- 2. Gestão do Scanner ---
print_info "Gerenciando scanner: '$SCAN_NAME'..."

# Tenta encontrar scanner existente
SCAN_LINE=$(sudo -Hiu gvm "$GVMD_BIN" --get-scanners | grep -w "$SCAN_NAME" || true)

if [ -n "$SCAN_LINE" ]; then
  SCAN_UUID=$(echo "$SCAN_LINE" | awk '{print $1}')
  print_info "Scanner já existe (UUID: $SCAN_UUID)."
else
  print_info "Criando novo scanner '$SCAN_NAME'..."
  sudo -Hiu gvm "$GVMD_BIN" --create-scanner="$SCAN_NAME" --scanner-type="$SCAN_TYPE" --scanner-host="$SCAN_SOCKET"
  print_success "Scanner criado."
  
  SCAN_UUID=$(sudo -Hiu gvm "$GVMD_BIN" --get-scanners | grep -w "$SCAN_NAME" | awk '{print $1}')
fi

# --- 3. Verificação ---
print_info "Iniciando verificação do scanner (UUID: $SCAN_UUID)..."

if sudo -Hiu gvm "$GVMD_BIN" --verify-scanner="$SCAN_UUID"; then
  print_success "Conectividade com o scanner validada."
else
  print_error "Falha ao verificar o scanner. Verifique os logs do ospd-openvas."
  exit 1
fi

# --- Conclusão ---
echo ""
print_warning "========================================================================"
print_success " Configuração do scanner concluída!"
echo ""
print_info " Resumo das Ações:"
echo "   - Scanner '$SCAN_NAME' registrado no sistema."
echo "   - Link estabelecido via socket $SCAN_SOCKET."
echo "   - Status de prontidão verificado com sucesso."
print_warning "========================================================================"

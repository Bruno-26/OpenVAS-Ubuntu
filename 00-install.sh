#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ultimo teste utilizado
# Ubuntu 24.04 - Setembro 2025
# export GVM_LIBS="22.28.1"
# export GVMD="26.3.0"
# export PG_GVM="22.6.11"
# export GSA="26.0.0"
# export GSAD="24.5.4"
# export OPENVAS_SMB="22.5.10"
# export OPENVAS_SCANNER="23.28.0"
# export OSPD_OPENVAS="22.9.0"
# export NOTUS_SCANNER="22.7.2"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}ERRO: Este script precisa ser executado com privilégios de root.${NC}"
  echo "Por favor, execute com 'sudo'."
  exit 1
fi

echo "Permissão de root verificada. Iniciando..."

echo "Obtendo as versões mais recentes dos componentes GVM do GitHub..."
# GVM_LIBS
# https://github.com/greenbone/gvm-libs/releases
export GVM_LIBS=$(curl -s https://api.github.com/repos/greenbone/gvm-libs/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

# GVMD
# https://github.com/greenbone/gvmd/releases
export GVMD=$(curl -s https://api.github.com/repos/greenbone/gvmd/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

# PG_GVM
# https://github.com/greenbone/pg-gvm/releases
export PG_GVM=$(curl -s https://api.github.com/repos/greenbone/pg-gvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

# GSA
# https://github.com/greenbone/gsa/releases
export GSA=$(curl -s https://api.github.com/repos/greenbone/gsa/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

# GSAD
# https://github.com/greenbone/gsad/releases
export GSAD=$(curl -s https://api.github.com/repos/greenbone/gsad/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

# OPENVAS_SMB
# https://github.com/greenbone/openvas-smb/releases
export OPENVAS_SMB=$(curl -s https://api.github.com/repos/greenbone/openvas-smb/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

# OPENVAS_SCANNER
# https://github.com/greenbone/openvas-scanner/releases
export OPENVAS_SCANNER=$(curl -s https://api.github.com/repos/greenbone/openvas-scanner/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

# OSPD_OPENVAS
# https://github.com/greenbone/ospd-openvas/releases
export OSPD_OPENVAS=$(curl -s https://api.github.com/repos/greenbone/ospd-openvas/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

# NOTUS_SCANNER
# https://github.com/greenbone/notus-scanner/releases
export NOTUS_SCANNER=$(curl -s https://api.github.com/repos/greenbone/notus-scanner/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')


# --- Verificação se todas as variáveis de versão foram preenchidas ---
declare -A components
components=(
    ["GVM_LIBS"]="$GVM_LIBS"
    ["GVMD"]="$GVMD"
    ["PG_GVM"]="$PG_GVM"
    ["GSA"]="$GSA"
    ["GSAD"]="$GSAD"
    ["OPENVAS_SMB"]="$OPENVAS_SMB"
    ["OPENVAS_SCANNER"]="$OPENVAS_SCANNER"
    ["OSPD_OPENVAS"]="$OSPD_OPENVAS"
    ["NOTUS_SCANNER"]="$NOTUS_SCANNER"
)

for name in "${!components[@]}"; do
    if [ -z "${components[$name]}" ]; then
        echo -e "\n${RED}ERRO: Não foi possível obter a versão para o componente: ${name}.${NC}"
        echo "Verifique sua conexão com a internet ou se o repositório no GitHub está acessível."
        echo "Você pode definir a versão manualmente no início do script."
        exit 1
    fi
done

echo -e "${GREEN}Sucesso! Todas as versões foram obtidas.${NC}"

# --- Dados e confirmação ---
echo ""
echo -e "${YELLOW}--------------------------------------------------${NC}"
echo -e "${YELLOW} As seguintes versões dos componentes serão usadas:${NC}"
echo -e "${YELLOW}--------------------------------------------------${NC}"
printf "%-20s: %s\n" "gvm-libs" "$GVM_LIBS"
printf "%-20s: %s\n" "gvmd" "$GVMD"
printf "%-20s: %s\n" "pg-gvm" "$PG_GVM"
printf "%-20s: %s\n" "gsa" "$GSA"
printf "%-20s: %s\n" "gsad" "$GSAD"
printf "%-20s: %s\n" "openvas-smb" "$OPENVAS_SMB"
printf "%-20s: %s\n" "openvas-scanner" "$OPENVAS_SCANNER"
printf "%-20s: %s\n" "ospd-openvas" "$OSPD_OPENVAS"
printf "%-20s: %s\n" "notus-scanner" "$NOTUS_SCANNER"
echo -e "${YELLOW}--------------------------------------------------${NC}"
echo ""

read -p "Você deseja continuar com a compilação usando estas versões? (s/N) " confirm

# Converte a resposta para minúsculas para a verificação
if [[ "${confirm,,}" != "s" ]]; then
    echo -e "${RED}Instalação cancelada pelo usuário.${NC}"
    exit 0
fi

echo "Instalando de configurando dependencias..."
sudo ./02-dependencias.sh || exit 1

echo "Instalando de configurando postgreSQL..."
sudo ./03-postgresql.sh || exit 1

echo "Configurando usuario GVM..."
sudo ./04-create-user-gvm.sh || exit 1

echo "Instalando de configurando NodeJS..."
sudo ./05-nodejs.sh || exit 1

echo "Compilando gvm-libs versão $GVM_LIBS..."
sudo GVM_LIBS="$GVM_LIBS" ./06-build_gvm_libs.sh || exit 1

echo "Compilando build_gvmd versão $GVMD..."
sudo GVMD="$GVMD" ./07-build_gvmd.sh || exit 1

echo "Compilando build_gvmd versão $PG_GVM..."
sudo PG_GVM="$PG_GVM" ./08-build_pg-gvm.sh || exit 1

echo "Compilando GSA versão $GSA..."
sudo GSA="$GSA" ./09-build_gsa.sh || exit 1

echo "Compilando GSAD versão $GSAD..."
sudo GSAD="$GSAD" ./10-build_gsad.sh || exit 1

echo "Compilando OPENVAS_SMB versão $OPENVAS_SMB..."
echo "Compilando OPENVAS_SCANNER versão $OPENVAS_SCANNER..."
sudo OPENVAS_SMB="$OPENVAS_SMB" OPENVAS_SCANNER="$OPENVAS_SCANNER" ./11-build_scanners.sh || exit 1

echo "Compilando OSPD_OPENVAS versão $OSPD_OPENVAS..."
sudo OSPD_OPENVAS="$OSPD_OPENVAS" ./12-build_ospd-openvas.sh || exit 1

echo "Compilando NOTUS_SCANNER versão $NOTUS_SCANNER..."
sudo NOTUS_SCANNER="$NOTUS_SCANNER" ./13-build_notus-scanner.sh || exit 1



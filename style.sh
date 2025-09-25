#!/bin/bash

# ==================================================================
# Biblioteca de Estilo e Funções Compartilhadas
#
# Propósito:
# Centralizar as definições de cores e as funções de impressão
#
# Como usar:
#   source "$(dirname "$0")/style.sh"
# ==================================================================

# --- Definições de Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Funções de Impressão ---
print_success() {
    echo -e "${GREEN}✔   $1${NC}"
}

print_error() {
    echo -e "${RED}✖   $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ   $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠   $1${NC}"
}
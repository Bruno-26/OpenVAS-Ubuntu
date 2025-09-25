#!/bin/bash

source "$(dirname "$0")/../style.sh"

# ==================================================================
# Script: 02-dependencias.sh
#
# Propósito:
# 1. Atualiza os pacotes do sistema.
# 2. Verifica se o sistema precisa ser reiniciado antes de continuar.
# 3. Instala todas as bibliotecas e ferramentas de desenvolvimento
#    necessárias para compilar o Greenbone Vulnerability Manager (GVM).
#
# ==================================================================

# --- Configurações de Segurança ---
# -e: Sai imediatamente se um comando falhar.
# -o pipefail: Garante que falhas em pipelines sejam capturadas.
set -e
set -o pipefail

if [ "$(id -u)" -ne 0 ]; then
  if command -v print_error &> /dev/null; then
    print_error "Este script precisa ser executado como root. Por favor, use 'sudo'."
  else
    echo "ERRO: Este script precisa ser executado como root. Por favor, use 'sudo'."
  fi
  exit 1
fi

# --- 1. Atualização do Sistema ---
print_info "Iniciando a atualização do sistema..."
print_info "Atualizando a lista de pacotes (apt update)..."
apt-get update

print_info "Atualizando os pacotes instalados (apt upgrade)..."
apt-get -y upgrade
print_success "Sistema atualizado com sucesso."
echo ""

# --- 2. Verificação de Reinicialização Necessária ---
print_info "Verificando se uma reinicialização do sistema é necessária..."
if [ -f /run/reboot-required ]; then
    print_warning "------------------------------------------------------------"
    print_warning "AVISO: Uma reinicialização do sistema é estritamente necessária."
    print_warning "Por favor, reinicie o servidor com 'sudo reboot' e execute"
    print_warning "o script de instalação principal novamente para continuar."
    print_warning "------------------------------------------------------------"
    exit 1
else
    print_success "Nenhuma reinicialização necessária. Continuando com a instalação."
    echo ""
fi

# --- 3. Instalação das Dependências ---
print_info "Instalando todas as dependências necessárias para a compilação..."

# O comando irá falhar e parar o script (devido ao 'set -e') se algum pacote não for encontrado.
apt-get install -y --no-install-recommends \
    bison \
    clang-format \
    cmake \
    curl \
    doxygen \
    flex \
    g++ \
    gcc \
    gcc-mingw-w64 \
    gettext \
    git \
    gnutls-bin \
    graphviz \
    heimdal-dev \
    krb5-multidev \
    libbsd-dev \
    libcjson-dev \
    libcurl4-gnutls-dev \
    libgcrypt20-dev \
    libglib2.0-dev \
    libgpgme-dev \
    libgnutls28-dev \
    libhiredis-dev \
    libical-dev \
    libjson-glib-dev \
    libksba-dev \
    libldap2-dev \
    libmicrohttpd-dev \
    libnet-dev \
    libpaho-mqtt-dev \
    libpcap-dev \
    libpopt-dev \
    libradcli-dev \
    libsnmp-dev \
    libssh-gcrypt-dev \
    libunistring-dev \
    libxml2-dev \
    make \
    mosquitto \
    nmap \
    perl-base \
    pkg-config \
    python3-cffi \
    python3-defusedxml \
    python3-dev \
    python3-gnupg \
    python3-lxml \
    python3-packaging \
    python3-paho-mqtt \
    python3-paramiko \
    python3-pip \
    python3-polib \
    python3-psutil \
    python3-redis \
    python3-setuptools \
    python3-wrapt \
    redis-server \
    rsync \
    texlive-fonts-recommended \
    texlive-latex-extra \
    uuid-dev \
    xml-twig-tools \
    xmltoman \
    xsltproc \
    zlib1g-dev


# --- Conclusão ---
echo ""
print_success "Instalação de dependências concluída com sucesso!"

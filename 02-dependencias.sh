#!/bin/bash

# ==================================================================
# Script para atualizar o sistema e instalar todas as dependências
# necessárias para a compilação do GVM.
#
# O que ele faz:
# 1. Verifica se está sendo executado como root.
# 2. Atualiza a lista de pacotes e os pacotes instalados.
# 3. Verifica se o sistema precisa ser reiniciado e, em caso
#    afirmativo, para a execução com uma instrução.
# 4. Instala a longa lista de bibliotecas e ferramentas de
#    desenvolvimento necessárias.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Atualização do Sistema ---
echo "--- Iniciando a atualização do sistema ---"
echo "1. Atualizando a lista de pacotes (apt update)..."
apt-get update

echo "2. Atualizando os pacotes instalados (apt upgrade)..."
apt-get upgrade -y
echo "Sistema atualizado."
echo ""

# --- 2. Verificação de Reinicialização Necessária (Modo Seguro) ---
echo "--- Verificando se uma reinicialização é necessária ---"
if [ -f /run/reboot-required ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! AVISO: Uma reinicialização do sistema é necessária.   !!!"
    echo "!!!                                                         !!!"
    echo "!!! Por favor, reinicie o servidor com 'sudo reboot' e      !!!"
    echo "!!! execute este script novamente após o reinício.          !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
else
    echo "Nenhuma reinicialização necessária. Continuando com a instalação."
    echo ""
fi

# --- 3. Instalação das Dependências ---
echo "--- Instalando todas as dependências necessárias ---"
# A lista de pacotes foi formatada para melhor legibilidade
apt-get install --no-install-recommends -y \
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

# Verifica se a instalação foi bem-sucedida
if [ $? -ne 0 ]; then
    echo ""
    echo "ERRO: A instalação de dependências falhou. Verifique os erros acima."
    exit 1
fi

# --- Conclusão ---
echo ""
echo "======================================================================"
echo " Instalação de dependências concluída com sucesso!"
echo " O sistema está pronto para as próximas etapas de compilação."
echo "======================================================================"
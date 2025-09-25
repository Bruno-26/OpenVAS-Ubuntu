#!/bin/bash

# ==================================================================
# Script final para verificar o acesso à interface web GVM (GSA)
# e configurar o firewall, se necessário.
#
# O que ele faz:
# 1. Verifica se o serviço gsad está escutando na porta 443.
# 2. Verifica se o firewall UFW está ativo.
# 3. Se o UFW estiver ativo, adiciona uma regra para permitir o
#    acesso na porta 443 (apenas se a regra não existir).
# 4. Detecta e exibe todos os endereços IP do servidor para
#    facilitar o acesso.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Verificação da Porta do GSAD ---
echo "--- Verificando se o serviço GSAD está escutando na porta 443 ---"
# '-l' for listening, '-n' for numeric, '-t' for tcp, '-p' for process
GSAD_PROCESS_INFO=$(ss -lntp | grep ':443')

if [ -n "$GSAD_PROCESS_INFO" ] && echo "$GSAD_PROCESS_INFO" | grep -q "gsad"; then
    echo "   - SUCESSO: O processo 'gsad' foi encontrado escutando na porta 443."
    echo "$GSAD_PROCESS_INFO"
else
    echo "   - AVISO: Não foi possível encontrar o processo 'gsad' escutando na porta 443."
    echo "     Verifique se o serviço 'gsad' está em execução com: systemctl status gsad"
fi
echo ""

# --- 2. Gerenciamento do Firewall (UFW) ---
echo "--- Verificando e configurando o firewall (UFW) ---"
# Verifica se o comando ufw existe
if command -v ufw &> /dev/null; then
    # Verifica se o UFW está ativo
    if ufw status | grep -q "Status: active"; then
        echo "1. Firewall UFW está ativo."
        # Verifica se a regra para a porta 443 já existe
        if ufw status | grep -q "443/tcp.*ALLOW"; then
            echo "2. A regra para permitir conexões na porta 443/tcp já existe."
        else
            echo "2. Adicionando regra para permitir conexões na porta 443/tcp..."
            ufw allow 443/tcp
            echo "   - Regra adicionada."
        fi
    else
        echo "1. Firewall UFW não está ativo. Nenhuma regra será adicionada."
    fi
else
    echo "1. O utilitário de firewall 'UFW' não foi encontrado. Pulando a configuração do firewall."
fi
echo ""

# --- 3. Exibição das URLs de Acesso ---
echo "--- URLs de Acesso à Interface Web do GVM ---"
# Obtém todos os endereços IP não-locais da máquina
IP_ADDRESSES=$(hostname -I | xargs)

if [ -n "$IP_ADDRESSES" ]; then
    echo "Para acessar a interface, use uma das seguintes URLs no seu navegador:"
    for ip in $IP_ADDRESSES; do
        echo "   - https://${ip}"
    done
else
    echo "Não foi possível detectar um endereço IP de rede. Tente acessar usando:"
    echo "   - https://localhost"
    echo "   - ou https://<hostname-do-servidor>"
fi
echo "Lembre-se de que, por padrão, o GVM usa um certificado autoassinado. Você precisará aceitar o aviso de segurança do seu navegador."
echo ""

# --- Conclusão ---
echo "================================================="
echo " Verificação final concluída!"
echo "================================================="

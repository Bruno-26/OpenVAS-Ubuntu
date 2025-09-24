#!/bin/bash

# ==================================================================
# Script para sincronizar os feeds GVMD_DATA, SCAP, e CERT.
#
# O que ele faz:
# 1. Cria uma função para sincronizar um tipo de feed, com uma
#    retentativa automática usando a flag '--rsync' em caso de falha.
# 2. Executa a sincronização para GVMD_DATA.
# 3. Executa a sincronização para SCAP.
# 4. Executa a sincronização para CERT (após SCAP).
# 5. Para a execução se qualquer sincronização falhar criticamente.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Pré-requisitos ---
if ! command -v greenbone-feed-sync &> /dev/null; then
    echo "ERRO: O comando 'greenbone-feed-sync' não foi encontrado."
    echo "Por favor, execute o script de instalação dessa ferramenta primeiro."
    exit 1
fi

# --- 2. Definição da Função de Sincronização ---

# Esta função sync_feed recebe um tipo de feed (ex: "SCAP") como argumento
# e lida com a lógica de sincronização e retentativa.
sync_feed() {
    local feed_type="$1"
    echo ""
    echo "--------------------------------------------------"
    echo "--- Sincronizando o Feed: ${feed_type}"
    echo "--------------------------------------------------"
    echo "Esta etapa pode levar algum tempo..."

    # Primeira tentativa, sem a flag --rsync
    if sudo -Hiu gvm greenbone-feed-sync --type "${feed_type}"; then
        echo "SUCESSO: O feed '${feed_type}' foi sincronizado com sucesso."
    else
        echo ""
        echo "AVISO: A sincronização inicial para '${feed_type}' falhou. Tentando novamente com a flag --rsync..."
        echo ""
        # Segunda tentativa (fallback), com a flag --rsync
        if ! sudo -Hiu gvm greenbone-feed-sync --type "${feed_type}" --rsync; then
            echo ""
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "!!! ERRO FATAL: Falha ao sincronizar o feed '${feed_type}'.  !!!"
            echo "!!! Verifique sua conexão com a internet e os logs.        !!!"
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            exit 1 # Para o script inteiro se a retentativa falhar
        fi
        echo "SUCESSO: O feed '${feed_type}' foi sincronizado com sucesso usando a flag --rsync."
    fi
}

# --- 3. Execução da Sincronização ---

# Chama a função para cada tipo de feed na ordem correta.
sync_feed "GVMD_DATA"
sync_feed "SCAP"
sync_feed "CERT" # CERT é executado por último, como recomendado.

# --- Conclusão ---
echo ""
echo "========================================================================"
echo " Todos os feeds de dados foram sincronizados com sucesso!"
echo ""
echo " Lembre-se de automatizar esta tarefa agendando-a com 'cron'."
echo " Exemplo de crontab para o usuário root (sudo crontab -e):"
echo "   # Sincroniza os feeds do GVM todos os dias às 03:00"
echo "   0 3 * * * /caminho/para/este/script.sh"
echo "========================================================================"

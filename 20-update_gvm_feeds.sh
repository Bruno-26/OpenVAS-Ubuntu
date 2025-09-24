#!/bin/bash

# ==================================================================
# Script para atualizar os Feeds de Vulnerabilidade (NVTs)
#
# O que ele faz:
# 1. Concede ao usuário 'gvm' permissão para executar 'openvas'
#    com sudo sem senha.
# 2. Executa 'greenbone-nvt-sync' como usuário 'gvm'.
# 3. Se a sincronização falhar, tenta novamente com a flag '--rsync'.
# 4. Após a sincronização, atualiza os plugins no Redis com 'openvas'.
# 5. Garante que as permissões do diretório de log estejam corretas.
# ==================================================================

# --- 0. Verificação de Privilégios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Por favor, use 'sudo'."
  exit 1
fi

# --- 1. Configuração de Permissões Sudo ---
echo "--- Configurando permissões de sudo para o comando 'openvas' ---"
SUDOERS_FILE="/etc/sudoers.d/gvm"

# Encontra o caminho completo para o executável openvas
OPENVAS_PATH=$(which openvas)
if [ -z "$OPENVAS_PATH" ]; then
    echo "ERRO: O executável 'openvas' não foi encontrado no PATH do sistema. A instalação pode ter falhado."
    exit 1
fi

# Define a regra a ser adicionada
SUDO_RULE="gvm ALL = NOPASSWD: $OPENVAS_PATH"

# Adiciona a regra apenas se ela ainda não existir
if ! grep -qF "$SUDO_RULE" "$SUDOERS_FILE"; then
    echo "1. Adicionando a seguinte regra ao arquivo '$SUDOERS_FILE':"
    echo "   '$SUDO_RULE'"
    echo "$SUDO_RULE" >> "$SUDOERS_FILE"

    # Valida a sintaxe do arquivo sudoers como medida de segurança
    visudo -c -f "$SUDOERS_FILE"
    if [ $? -ne 0 ]; then
        echo "ERRO CRÍTICO: A sintaxe do arquivo sudoers está incorreta! Removendo a regra para segurança."
        # Remove a última linha, que é a que acabamos de adicionar
        head -n -1 "$SUDOERS_FILE" > temp && mv temp "$SUDOERS_FILE"
        exit 1
    fi
else
    echo "1. A regra de sudo para 'openvas' já existe. Nenhuma alteração necessária."
fi
echo ""

# --- 2. Sincronização dos Feeds (NVTs) ---
echo "--- Sincronizando os Feeds de Vulnerabilidade (NVTs) ---"
echo "Esta etapa pode levar muito tempo. Por favor, seja paciente."

# Tenta o comando de sincronização padrão primeiro
if sudo -Hiu gvm greenbone-nvt-sync; then
    echo "Sincronização concluída com sucesso!"
else
    echo ""
    echo "AVISO: A sincronização inicial falhou. Tentando novamente com a flag --rsync..."
    echo ""
    # Se falhar, tenta novamente com a flag --rsync
    if ! sudo -Hiu gvm greenbone-nvt-sync --rsync; then
        echo ""
        echo "ERRO: A sincronização falhou mesmo com a flag --rsync."
        echo "Verifique sua conexão com a internet e os logs para mais detalhes."
        exit 1
    fi
    echo "Sincronização com a flag --rsync concluída com sucesso!"
fi
echo ""

# --- 3. Atualização do Banco de Dados Redis ---
echo "--- Atualizando os plugins de vulnerabilidade no banco de dados Redis ---"
# O usuário gvm usa o sudo que acabamos de configurar para executar 'openvas' como root
if sudo -Hiu gvm sudo "$OPENVAS_PATH" --update-vt-info; then
    echo "Atualização do banco de dados Redis concluída."
else
    echo "ERRO: Falha ao atualizar os plugins no Redis."
    exit 1
fi
echo ""

# --- 4. Ajuste Final de Permissões ---
echo "--- Verificando as permissões do diretório de log ---"
chown -R gvm:gvm /var/log/gvm
echo "Permissões do diretório '/var/log/gvm' ajustadas."
echo ""

# --- Conclusão ---
echo "================================================="
echo " Atualização dos Feeds concluída com sucesso!"
echo "================================================="

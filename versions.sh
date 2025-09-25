#!/bin/bash

# ==================================================================
# Script Utilitário: versions.sh
#
# Propósito:
# Verifica as versões mais recentes dos componentes GVM no GitHub
# e gera um bloco de código com as variáveis 'export' para ser
# colado no script de instalação principal.
#
# ==================================================================

# --- Importa a biblioteca de estilo se ela existir ---
if [ -f "$(dirname "$0")/style.sh" ]; then
    source "$(dirname "$0")/style.sh"
else
    print_info() { echo "INFO: $1"; }
    print_error() { echo "ERRO: $1"; }
fi

# --- Função para obter a versão mais recente do GitHub ---
get_latest_version() {
    local repo_url="https://api.github.com/repos/$1/releases/latest"
    local version=""

    if command -v jq &> /dev/null; then
        version=$(curl -s "$repo_url" | jq -r '.tag_name' | sed 's/^v//')
    else
        version=$(curl -s "$repo_url" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')
    fi
    echo "$version"
}

# --- Listas de Componentes ---
declare -a VAR_NAMES=(
    "GVM_LIBS" "GVMD" "PG_GVM" "GSA" "GSAD"
    "OPENVAS_SMB" "OPENVAS_SCANNER" "OSPD_OPENVAS" "NOTUS_SCANNER"
)
declare -a REPOS=(
    "greenbone/gvm-libs" "greenbone/gvmd" "greenbone/pg-gvm" "greenbone/gsa" "greenbone/gsad"
    "greenbone/openvas-smb" "greenbone/openvas-scanner" "greenbone/ospd-openvas" "greenbone/notus-scanner"
)

declare -a fetched_versions=()

print_info "Verificando as versões mais recentes no GitHub..."
print_info "Atenção: A API do GitHub tem um limite de requisições por hora."
echo ""
echo "# Para atualizar, execute ./versions.sh e cole o novo bloco de código aqui."

for repo in "${REPOS[@]}"; do
    printf "Buscando versão para %-28s... " "$repo"
    version=$(get_latest_version "$repo")

    if [ -z "$version" ]; then
        echo "FALHA"
        print_error "Não foi possível obter a versão para ${repo}. Verifique a conexão ou o limite da API." >&2
        fetched_versions+=("ERRO_NA_BUSCA")
    else
        echo "$version"
        fetched_versions+=("$version") # Adiciona ao array
    fi
done

echo ""
echo "# --- Bloco de Versões Gerado em: $(date) ---"

# Itera sobre os nomes das variáveis e as versões coletadas para imprimir o bloco
for i in "${!VAR_NAMES[@]}"; do
    var_name="${VAR_NAMES[$i]}"
    version="${fetched_versions[$i]}"

    # Só imprime a linha se a busca não tiver falhado
    if [ "$version" != "ERRO_NA_BUSCA" ]; then
        echo "export $var_name=\"$version\""
    fi
done

echo "# --- Fim do Bloco de Versões ---"
echo ""
print_info "Processo concluído. Copie o bloco de código acima."
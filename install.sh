#!/bin/bash

# --- Configurações Iniciais ---
# set -e: Sai imediatamente se um comando sair com um status diferente de zero.
# set -o pipefail: O status de retorno de um pipeline é o valor do último comando a sair com um status diferente de zero,
set -e
set -o pipefail

source "$(dirname "$0")/style.sh"

# --- Arquivo de Estado ---
STATE_FILE=".install_progress"
STEP_MODE=0

handle_error() {
    local exit_code=$?
    local line_number=$1
    local command=$2

    echo "" # Linha em branco para separar
    print_error "================================================================="
    print_error " ERRO: A instalação falhou!"
    print_error "================================================================="
    print_error "  - Causa:      O comando falhou na linha ${line_number}"
    print_error "  - Comando:    '${command}'"
    print_error "  - Código de Saída: ${exit_code}"
    echo ""
    print_info "  Por favor, verifique a saída de erro acima para diagnosticar o problema."
    print_info "  Quando o problema for resolvido, você pode executar o script novamente"
    print_info "  para continuar a instalação de onde parou."
    echo ""

    # Sai do script com o código de erro original
    exit $exit_code
}

trap 'handle_error $LINENO "$BASH_COMMAND"' ERR


# --- Função para obter a versão mais recente do GitHub ---
get_latest_version() {
    local repo_url="https://api.github.com/repos/$1/releases/latest"
    if command -v jq &> /dev/null; then
        curl -s "$repo_url" | jq -r '.tag_name' | sed 's/^v//'
    else
        curl -s "$repo_url" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/'
    fi
}

# --- Verificação de Root e Argumentos ---
if [ "$EUID" -ne 0 ]; then
  print_error "Este script precisa ser executado com privilégios de root."
  print_info "Por favor, execute com 'sudo'."
  exit 1
fi

# Argumento para reiniciar a instalação
for arg in "$@"; do
    case $arg in
        --reset)
            print_warning "O arquivo de progresso da instalação ($STATE_FILE) será removido."
            rm -f "$STATE_FILE"
            print_success "Progresso reiniciado. A instalação começará do zero."
            ;;
        --steps)
            STEP_MODE=1
            print_info "Modo passo a passo ATIVADO. O script irá pausar após cada etapa."
            ;;
    esac
done

touch "$STATE_FILE"

# --- Definição das Versões (Automático ou Manual) ---
print_info "Definindo as versões dos componentes..."

# Comente/descomente para usar versões fixas ou buscar as mais recentes
export GVM_LIBS="22.28.1"
export GVMD="26.3.0"
export PG_GVM="22.6.11"
export GSA="26.0.0"
export GSAD="24.5.4"
export OPENVAS_SMB="22.5.10"
export OPENVAS_SCANNER="23.28.0"
export OSPD_OPENVAS="22.9.0"
export NOTUS_SCANNER="22.7.2"

# --- Bloco para obter versões dinamicamente (descomente para usar) ---
# print_info "Obtendo as versões mais recentes dos componentes GVM do GitHub..."
# export GVM_LIBS=$(get_latest_version "greenbone/gvm-libs")
# export GVMD=$(get_latest_version "greenbone/gvmd")
# export PG_GVM=$(get_latest_version "greenbone/pg-gvm")
# export GSA=$(get_latest_version "greenbone/gsa")
# export GSAD=$(get_latest_version "greenbone/gsad")
# export OPENVAS_SMB=$(get_latest_version "greenbone/openvas-smb")
# export OPENVAS_SCANNER=$(get_latest_version "greenbone/openvas-scanner")
# export OSPD_OPENVAS=$(get_latest_version "greenbone/ospd-openvas")
# export NOTUS_SCANNER=$(get_latest_version "greenbone/notus-scanner")

# --- Verificação das Variáveis ---
declare -A components
components=(
    ["GVM_LIBS"]="$GVM_LIBS" ["GVMD"]="$GVMD" ["PG_GVM"]="$PG_GVM" ["GSA"]="$GSA"
    ["GSAD"]="$GSAD" ["OPENVAS_SMB"]="$OPENVAS_SMB" ["OPENVAS_SCANNER"]="$OPENVAS_SCANNER"
    ["OSPD_OPENVAS"]="$OSPD_OPENVAS" ["NOTUS_SCANNER"]="$NOTUS_SCANNER"
)

for name in "${!components[@]}"; do
    if [ -z "${components[$name]}" ]; then
        print_error "Não foi possível obter a versão para o componente: ${name}."
        print_info "Verifique sua conexão ou defina a versão manualmente no script."
        exit 1
    fi
done
print_success "Todas as versões foram definidas com sucesso."

# --- Confirmação do Usuário ---
echo ""
print_warning "--------------------------------------------------"
print_warning " As seguintes versões dos componentes serão usadas:"
print_warning "--------------------------------------------------"
printf "%-20s: %s\n" "gvm-libs" "$GVM_LIBS"
printf "%-20s: %s\n" "gvmd" "$GVMD"
printf "%-20s: %s\n" "pg-gvm" "$PG_GVM"
printf "%-20s: %s\n" "gsa" "$GSA"
printf "%-20s: %s\n" "gsad" "$GSAD"
printf "%-20s: %s\n" "openvas-smb" "$OPENVAS_SMB"
printf "%-20s: %s\n" "openvas-scanner" "$OPENVAS_SCANNER"
printf "%-20s: %s\n" "ospd-openvas" "$OSPD_OPENVAS"
printf "%-20s: %s\n" "notus-scanner" "$NOTUS_SCANNER"
print_warning "--------------------------------------------------"
echo ""

read -p "Você deseja continuar com a compilação usando estas versões? (s/N) " confirm
if [[ "${confirm,,}" != "s" ]]; then
    print_error "Instalação cancelada pelo usuário."
    exit 0
fi

# --- Lógica de Execução e Estado ---
# Define a lista de tarefas e os scripts correspondentes
declare -a TASKS=(
    "dependencias" "postgresql" "create_user_gvm" "nodejs"
    "build_gvm_libs" "build_gvmd" "build_pg-gvm" "build_gsa"
    "build_gsad" "build_scanners" "build_ospd-openvas" "build_notus-scanner"
    "install_feed-sync" "install_gvm-tools" "configure_redis" "optimize_redis_system"
    "configure_mosquitto" "set_gvm_permissions" "update_gvm_feeds" "update_data_feeds"
    "setup_feed_validation" "setup_services"
)
declare -a SCRIPTS=(
    "./02-dependencias.sh" "./03-postgresql.sh" "./04-create_user_gvm.sh" "./05-nodejs.sh"
    "./06-build_gvm_libs.sh" "./07-build_gvmd.sh" "./08-build_pg-gvm.sh" "./09-build_gsa.sh"
    "./10-build_gsad.sh" "./11-build_scanners.sh" "./12-build_ospd-openvas.sh" "./13-build_notus-scanner.sh"
    "./14-install_feed-sync.sh" "./15-install_gvm-tools.sh" "./16-configure_redis.sh" "./17-optimize_redis_system.sh"
    "./18-configure_mosquitto.sh" "./19-set_gvm_permissions.sh" "./20-update_gvm_feeds.sh" "./21-update_data_feeds.sh"
    "./22-setup_feed_validation.sh" "./23-setup_services.sh"
)

# Função para executar uma tarefa, verificando o estado antes
run_task() {
    local task_name=$1
    local script_path=$2
    local message=$3

    if grep -q "^${task_name}:ok$" "$STATE_FILE"; then
        print_success "Etapa '${task_name}' já concluída. Pulando."
        return 0
    fi

    echo ""
    print_info "-------------------------------------------"
    print_info "$message"
    print_info "-------------------------------------------"
    echo ""

    export GVM_LIBS GVMD PG_GVM GSA GSAD OPENVAS_SMB OPENVAS_SCANNER OSPD_OPENVAS NOTUS_SCANNER

    sudo -E bash "scripts/$script_path"

    echo "${task_name}:ok" >> "$STATE_FILE"
    echo ""
    print_success "-------------------------------------------"
    print_success "Etapa '${task_name}' concluída com sucesso."
    print_success "-------------------------------------------"
    echo ""

    if [ "$STEP_MODE" -eq 1 ]; then
        echo ""
        read -p "Pressione [Enter] para continuar para a próxima etapa..."
        echo ""
    fi

}

# Itera sobre todas as tarefas e as executa
for i in "${!TASKS[@]}"; do
    task="${TASKS[$i]}"
    script="${SCRIPTS[$i]}"
    message="Executando etapa: ${script}..."
    run_task "$script" "$script" "$message"
done

echo ""
print_success "-------------------------------------------"
print_success "---- Instalação concluída com sucesso! ----"
print_success "-------------------------------------------"
echo ""

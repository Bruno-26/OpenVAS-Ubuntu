# OpenVAS-Ubuntu

Script automatizado de instalação do **Greenbone Vulnerability Manager (GVM)** - anteriormente conhecido como OpenVAS - para sistemas Ubuntu/Debian.

## 📋 Descrição

Este projeto fornece uma solução completa e automatizada para compilação e instalação do GVM a partir do código-fonte, incluindo todos os componentes necessários para um sistema de gerenciamento de vulnerabilidades totalmente funcional.

## ✨ Características

- **Instalação Modular**: 26 scripts independentes organizados por funcionalidade
- **Recuperação de Falhas**: Sistema de checkpoint que permite retomar instalação após erros
- **Versionamento Automático**: Verificação automática das versões mais recentes no GitHub
- **Modo Passo a Passo**: Execução interativa com pausa entre etapas
- **Tratamento de Erros**: Captura detalhada de erros com linha, comando e código de saída
- **Interface Colorida**: Saída formatada com cores e ícones para melhor visualização

## 🎯 Componentes Instalados

O script instala e configura os seguintes componentes do GVM:

| Componente | Versão Atual | Descrição |
|------------|--------------|-----------|
| gvm-libs | 22.28.1 | Bibliotecas base do GVM |
| gvmd | 26.3.0 | Greenbone Vulnerability Manager Daemon |
| pg-gvm | 22.6.11 | Extensão PostgreSQL para GVM |
| gsa | 26.0.0 | Greenbone Security Assistant (Interface Web) |
| gsad | 24.5.4 | GSA Daemon |
| openvas-smb | 22.5.10 | Suporte SMB para OpenVAS |
| openvas-scanner | 23.28.0 | Scanner de vulnerabilidades |
| ospd-openvas | 22.9.0 | OSP Daemon para OpenVAS |
| notus-scanner | 22.7.2 | Notus Scanner |

## 📦 Pré-requisitos

- Sistema operacional: **Ubuntu 20.04+** ou **Debian 11+**
- Privilégios de **root** (sudo)
- Conexão com a internet
- Mínimo 4GB RAM recomendado
- 20GB de espaço em disco

## 🚀 Instalação

### Instalação Padrão

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/OpenVAS-Ubuntu.git
cd OpenVAS-Ubuntu

# Execute o instalador
sudo ./install.sh
```

### Instalação Passo a Passo

Para revisar cada etapa antes de continuar:

```bash
sudo ./install.sh --steps
```

### Reiniciar Instalação do Zero

Se precisar recomeçar a instalação:

```bash
sudo ./install.sh --reset
```

## 🔧 Uso Avançado

### Atualizar Versões dos Componentes

Para verificar as versões mais recentes disponíveis no GitHub:

```bash
./versions.sh
```

O script exibirá um bloco de código que pode ser copiado para o arquivo `install.sh` (linhas 66-76).

### Estrutura de Scripts

Os scripts são executados na seguinte ordem:

```
02-dependencias.sh          # Instala dependências do sistema
03-postgresql.sh            # Configura PostgreSQL
04-create_user_gvm.sh       # Cria usuário do sistema
05-nodejs.sh                # Instala Node.js via NVM
06-build_gvm_libs.sh        # Compila gvm-libs
07-build_gvmd.sh            # Compila gvmd
08-build_pg-gvm.sh          # Compila extensão PostgreSQL
09-build_gsa.sh             # Compila interface web
10-build_gsad.sh            # Compila GSA daemon
11-build_scanners.sh        # Compila scanners
12-build_ospd-openvas.sh    # Compila OSP daemon
13-build_notus-scanner.sh   # Compila Notus scanner
14-install_feed-sync.sh     # Instala sincronizador de feeds
15-install_gvm-tools.sh     # Instala ferramentas GVM
16-configure_redis.sh       # Configura Redis
17-optimize_redis_system.sh # Otimiza Redis no sistema
18-configure_mosquitto.sh   # Configura Mosquitto MQTT
19-set_gvm_permissions.sh   # Define permissões
20-update_gvm_feeds.sh      # Atualiza feeds de vulnerabilidades
21-update_data_feeds.sh     # Atualiza feeds de dados
22-setup_feed_validation.sh # Configura validação de feeds
23-setup_services.sh        # Configura serviços systemd
24-setup_gvm_scanner.sh     # Configura scanner
25-manage_gvm_users.sh      # Cria usuário admin automaticamente
26-set_feed_owner.sh        # Define proprietário dos feeds
27-check_gvm_access.sh      # Verifica acesso ao GVM
```

## 🔐 Credenciais Padrão

Após a instalação:

- **Usuário PostgreSQL**: `postgres`
- **Senha PostgreSQL**: `pgadmin`
- **Usuário GVM Admin**: `admin`
- **Senha GVM Admin**: Gerada automaticamente e exibida ao final da etapa 25

⚠️ **IMPORTANTE**:
- Anote a senha do usuário `admin` exibida durante a instalação!
- Altere as credenciais padrão em ambiente de produção!

## 🛠️ Gerenciamento de Usuários GVM

Para criar novos usuários ou alterar senhas após a instalação:

```bash
sudo ./gvm_user_manager_tool.sh
```

Este script oferece um menu interativo para:
- Listar todos os usuários cadastrados
- Criar novos usuários com senhas personalizadas
- Alterar senhas de usuários existentes
- Criar usuário 'admin' com senha aleatória (se ainda não existir)

⚠️ **IMPORTANTE**: Altere as credenciais padrão em ambiente de produção!

## 🌐 Acesso à Interface Web

Após instalação bem-sucedida:

```
URL: https://localhost:9392
ou
URL: https://IP_DO_SERVIDOR:9392
```

## 🐛 Solução de Problemas

### Erro de Sintaxe no PostgreSQL

Se encontrar erro `syntax error at or near`, certifique-se de usar a versão corrigida do script `03-postgresql.sh`.

### Erro no Node.js/NVM

O script `05-nodejs.sh` foi corrigido para usar heredocs. Certifique-se de ter a versão mais recente.

### Retomar Instalação

O progresso é salvo em `.install_progress`. Para continuar após correção de erro:

```bash
sudo ./install.sh
```

## 📝 Logs e Arquivos

- **Progresso**: `.install_progress`
- **Backups PostgreSQL**: `/etc/postgresql/*/main/*.bak.*`
- **Código Fonte**: `/opt/gvm/gvm-source/`
- **Instalação**: `/usr/local/`


## 🔗 Links Úteis

- [Greenbone Community Edition](https://www.greenbone.net/en/community-edition/)
- [Documentação Oficial GVM](https://docs.greenbone.net/)
- [GitHub Greenbone](https://github.com/greenbone)


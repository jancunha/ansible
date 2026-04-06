#!/bin/bash

# =============================================================================
# SCRIPT DE CONFIGURAÇÃO DE AMBIENTE DEVOPS
# Baseado no arquivo Ansible devops.yaml
# Ubuntu 24.04 (Noble Numbat)
# =============================================================================

# Configurações globais
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Internal Field Separator

# Variáveis de configuração
USUARIO_ALVO="sysadmin"
VERSAO="noble"
ARQUITETURA="amd64"
LOG_FILE="/tmp/devops_setup.log"
TEMP_DIR="/tmp/devops_temp"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

# Função para logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Função para verificar se o comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se é root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "Este script deve ser executado como root (sudo)"
        exit 1
    fi
}

# Função para verificar se é Ubuntu
check_ubuntu() {
    if ! command_exists lsb_release; then
        log "ERROR" "lsb_release não encontrado. Este script é para Ubuntu."
        exit 1
    fi
    
    local distro=$(lsb_release -si)
    local version=$(lsb_release -rs)
    
    if [[ "$distro" != "Ubuntu" ]]; then
        log "ERROR" "Este script é específico para Ubuntu. Distribuição detectada: $distro"
        exit 1
    fi
    
    log "INFO" "Sistema detectado: Ubuntu $version"
}

# Função para atualizar sistema
update_system() {
    log "INFO" "=== MÓDULO 0: ATUALIZAÇÃO DO SISTEMA OPERACIONAL ==="
    
    log "INFO" "Atualizando lista de pacotes..."
    apt update -y
    
    log "INFO" "Atualizando sistema..."
    apt upgrade -y
    
    log "SUCCESS" "Sistema atualizado com sucesso!"
}

# Função para instalar pacotes básicos
install_basic_packages() {
    log "INFO" "=== INSTALANDO PACOTES BÁSICOS ==="
    
    local packages=(
        "vim"
        "git"
        "curl"
        "unzip"
        "net-tools"
        "zsh"
        "python3"
        "python3-pip"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log "INFO" "Instalando $package..."
            apt install -y "$package"
        else
            log "INFO" "$package já está instalado"
        fi
    done
    
    log "SUCCESS" "Pacotes básicos instalados com sucesso!"
}

# Função para instalar ZSH e Oh My Zsh
install_zsh() {
    log "INFO" "=== MÓDULO 1: INSTALAÇÃO DO ZSH E OH MY ZSH ==="
    
    # Definir ZSH como shell padrão
    log "INFO" "Definindo ZSH como shell padrão para $USUARIO_ALVO..."
    chsh -s /bin/zsh "$USUARIO_ALVO"
    
    # Instalar Oh My Zsh
    if [[ ! -d "/home/$USUARIO_ALVO/.oh-my-zsh" ]]; then
        log "INFO" "Instalando Oh My Zsh..."
        sudo -u "$USUARIO_ALVO" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log "INFO" "Oh My Zsh já está instalado"
    fi
    
    # Instalar plugins
    local plugins_dir="/home/$USUARIO_ALVO/.oh-my-zsh/custom/plugins"
    mkdir -p "$plugins_dir"
    
    # zsh-syntax-highlighting
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        log "INFO" "Instalando plugin zsh-syntax-highlighting..."
        sudo -u "$USUARIO_ALVO" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
    fi
    
    # zsh-autosuggestions
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        log "INFO" "Instalando plugin zsh-autosuggestions..."
        sudo -u "$USUARIO_ALVO" git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions"
    fi
    
    # zsh-completions
    if [[ ! -d "$plugins_dir/zsh-completions" ]]; then
        log "INFO" "Instalando plugin zsh-completions..."
        sudo -u "$USUARIO_ALVO" git clone https://github.com/zsh-users/zsh-completions.git "$plugins_dir/zsh-completions"
    fi
    
    # Configurar .zshrc
    local zshrc="/home/$USUARIO_ALVO/.zshrc"
    if [[ -f "$zshrc" ]]; then
        log "INFO" "Configurando plugins no .zshrc..."
        
        # Atualizar plugins
        sudo -u "$USUARIO_ALVO" sed -i 's/^plugins=(.*)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' "$zshrc"
        
        # Adicionar configuração para zsh-completions
        if ! grep -q "autoload -U compinit" "$zshrc"; then
            sudo -u "$USUARIO_ALVO" sed -i '/^plugins=(/a autoload -U compinit && compinit' "$zshrc"
        fi
    fi
    
    log "SUCCESS" "ZSH e Oh My Zsh configurados com sucesso!"
}

# Função para instalar Docker
install_docker() {
    log "INFO" "=== MÓDULO 2: INSTALAÇÃO DO DOCKER ==="
    
    # Instalar dependências
    log "INFO" "Instalando dependências do Docker..."
    apt install -y ca-certificates curl
    
    # Baixar e instalar chave GPG do Docker
    log "INFO" "Baixando chave GPG do Docker..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.asc
    chmod 644 /etc/apt/keyrings/docker.asc
    
    # Adicionar repositório Docker
    log "INFO" "Adicionando repositório Docker..."
    echo "deb [arch=$ARQUITETURA signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $VERSAO stable" > /etc/apt/sources.list.d/docker.list
    
    # Atualizar cache
    apt update
    
    # Instalar Docker
    log "INFO" "Instalando Docker..."
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Habilitar e iniciar Docker
    log "INFO" "Habilitando e iniciando serviço Docker..."
    systemctl enable docker
    systemctl start docker
    
    # Adicionar usuário ao grupo docker
    log "INFO" "Adicionando $USUARIO_ALVO ao grupo docker..."
    usermod -aG docker "$USUARIO_ALVO"
    
    log "SUCCESS" "Docker instalado e configurado com sucesso!"
}

# Função para instalar Terraform
install_terraform() {
    log "INFO" "=== MÓDULO 3: INSTALAÇÃO DO TERRAFORM ==="
    
    # Instalar dependências
    log "INFO" "Instalando dependências do Terraform..."
    apt install -y gnupg software-properties-common curl wget
    
    # Baixar e instalar chave GPG do HashiCorp
    log "INFO" "Baixando chave GPG do HashiCorp..."
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    
    # Adicionar repositório HashiCorp
    log "INFO" "Adicionando repositório HashiCorp..."
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $VERSAO main" > /etc/apt/sources.list.d/hashicorp.list
    
    # Atualizar cache
    apt update
    
    # Instalar Terraform
    log "INFO" "Instalando Terraform..."
    apt install -y terraform
    
    log "SUCCESS" "Terraform instalado com sucesso!"
}

# Função para instalar Kubectl
install_kubectl() {
    log "INFO" "=== MÓDULO 4: INSTALAÇÃO DO KUBECTL ==="
    
    # Instalar dependências
    log "INFO" "Instalando dependências do Kubectl..."
    apt install -y apt-transport-https ca-certificates curl gnupg
    
    # Baixar e instalar chave GPG do Kubernetes
    log "INFO" "Baixando chave GPG do Kubernetes..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    
    # Adicionar repositório Kubernetes
    log "INFO" "Adicionando repositório Kubernetes..."
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
    
    # Atualizar cache
    apt update
    
    # Instalar Kubectl
    log "INFO" "Instalando Kubectl..."
    apt install -y kubectl
    
    log "SUCCESS" "Kubectl instalado com sucesso!"
}

# Função para instalar Helm
install_helm() {
    log "INFO" "=== MÓDULO 5: INSTALAÇÃO DO HELM ==="
    
    # Adicionar chave GPG do Helm
    log "INFO" "Baixando chave GPG do Helm..."
    curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor -o /usr/share/keyrings/helm.gpg
    
    # Instalar apt-transport-https
    apt install -y apt-transport-https
    
    # Adicionar repositório Helm
    log "INFO" "Adicionando repositório Helm..."
    echo "deb [arch=$ARQUITETURA signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" > /etc/apt/sources.list.d/helm-stable-debian.list
    
    # Atualizar cache
    apt update
    
    # Instalar Helm
    log "INFO" "Instalando Helm..."
    apt install -y helm
    
    log "SUCCESS" "Helm instalado com sucesso!"
}

# Função para instalar Ansible
install_ansible() {
    log "INFO" "=== MÓDULO 6: INSTALAÇÃO DO ANSIBLE ==="
    
    # Adicionar chave do repositório Ansible
    log "INFO" "Baixando chave GPG do Ansible..."
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367
    
    # Adicionar repositório Ansible
    log "INFO" "Adicionando repositório Ansible..."
    add-apt-repository "deb http://ppa.launchpad.net/ansible/ansible/ubuntu $VERSAO main" -y
    
    # Atualizar cache
    apt update
    
    # Instalar Ansible
    log "INFO" "Instalando Ansible..."
    apt install -y ansible
    
    log "SUCCESS" "Ansible instalado com sucesso!"
}

# Função para instalar AWS CLI
install_aws_cli() {
    log "INFO" "=== MÓDULO 7: INSTALAÇÃO DO AWS CLI ==="
    
    # Verificar se já está instalado
    if command_exists aws; then
        log "INFO" "AWS CLI já está instalado"
        return 0
    fi
    
    # Baixar AWS CLI
    log "INFO" "Baixando AWS CLI..."
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    
    # Instalar unzip se necessário
    apt install -y unzip
    
    # Extrair AWS CLI
    log "INFO" "Extraindo AWS CLI..."
    unzip -q /tmp/awscliv2.zip -d /tmp/
    
    # Instalar AWS CLI
    log "INFO" "Instalando AWS CLI..."
    /tmp/aws/install
    
    # Limpar arquivos temporários
    log "INFO" "Limpando arquivos temporários..."
    rm -f /tmp/awscliv2.zip
    rm -rf /tmp/aws
    
    log "SUCCESS" "AWS CLI instalado com sucesso!"
}

# Função para verificar instalações
verify_installations() {
    log "INFO" "=== VERIFICANDO INSTALAÇÕES ==="
    
    local tools=(
        "docker"
        "terraform"
        "kubectl"
        "helm"
        "ansible"
        "aws"
    )
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            local version=$($tool --version 2>/dev/null | head -n1 || echo "versão não disponível")
            log "SUCCESS" "$tool: $version"
        else
            log "WARNING" "$tool: NÃO INSTALADO"
        fi
    done
}

# Função para limpeza
cleanup() {
    log "INFO" "=== LIMPEZA ==="
    
    # Limpar cache do apt
    apt autoremove -y
    apt autoclean
    
    # Limpar diretório temporário
    rm -rf "$TEMP_DIR"
    
    log "SUCCESS" "Limpeza concluída!"
}

# Função principal
main() {
    log "INFO" "Iniciando configuração do ambiente DevOps..."
    log "INFO" "Log será salvo em: $LOG_FILE"
    
    # Verificações iniciais
    check_root
    check_ubuntu
    
    # Criar diretório temporário
    mkdir -p "$TEMP_DIR"
    
    # Executar módulos
    update_system
    install_basic_packages
    install_zsh
    install_docker
    install_terraform
    install_kubectl
    install_helm
    install_ansible
    install_aws_cli
    
    # Verificar instalações
    verify_installations
    
    # Limpeza
    cleanup
    
    log "SUCCESS" "=== CONFIGURAÇÃO CONCLUÍDA COM SUCESSO! ==="
    log "INFO" "Para aplicar as mudanças do Docker, faça logout e login novamente"
    log "INFO" "Ou execute: newgrp docker"
}

# Tratamento de erros
trap 'log "ERROR" "Script interrompido. Verifique o log: $LOG_FILE"' INT TERM

# Executar função principal
main "$@" 
# Script de Configuração DevOps - Ubuntu 24.04

## Visão Geral

Este script automatiza a instalação e configuração de um ambiente DevOps completo no Ubuntu 24.04 (Noble Numbat), baseado no arquivo Ansible `devops.yaml`.

## Características

- ✅ **Tratamento de erros robusto**
- ✅ **Logging detalhado**
- ✅ **Verificações de segurança**
- ✅ **Modular e organizado**
- ✅ **Compatível com Ubuntu 24.04**

## Módulos Instalados

### Módulo 0: Atualização do Sistema
- Atualiza lista de pacotes
- Atualiza sistema operacional

### Módulo 1: ZSH e Oh My Zsh
- Instala ZSH como shell padrão
- Instala Oh My Zsh
- Configura plugins:
  - zsh-syntax-highlighting
  - zsh-autosuggestions
  - zsh-completions
- Configura `.zshrc` automaticamente

### Módulo 2: Docker
- Instala Docker CE
- Configura repositório oficial
- Habilita e inicia serviço
- Adiciona usuário ao grupo docker

### Módulo 3: Terraform
- Instala Terraform via repositório HashiCorp
- Configura chaves GPG oficiais

### Módulo 4: Kubectl
- Instala kubectl via repositório oficial Kubernetes
- Configura para versão estável v1.32

### Módulo 5: Helm
- Instala Helm via repositório oficial
- Configura para versão estável

### Módulo 6: Ansible
- Instala Ansible via PPA oficial
- Configura repositório Launchpad

### Módulo 7: AWS CLI
- Baixa e instala AWS CLI v2
- Instalação via binário oficial

## Como Usar

### Pré-requisitos
- Ubuntu 24.04 (Noble Numbat)
- Acesso root (sudo)
- Conexão com internet

### Execução

```bash
# Dar permissão de execução
chmod +x devops_setup.sh

# Executar como root
sudo ./devops_setup.sh
```

### Logs

O script gera logs detalhados em `/tmp/devops_setup.log`

## Variáveis de Configuração

Edite as variáveis no início do script conforme necessário:

```bash
USUARIO_ALVO="sysadmin"    # Usuário alvo para configuração
VERSAO="noble"             # Versão do Ubuntu
ARQUITETURA="amd64"        # Arquitetura do sistema
```

## Boas Práticas Implementadas

### 1. **Segurança**
- Verificação de privilégios root
- Verificação de distribuição Linux
- Uso de chaves GPG oficiais

### 2. **Tratamento de Erros**
- `set -euo pipefail` para falha rápida
- Trap para interrupções
- Verificação de comandos existentes

### 3. **Logging**
- Logs coloridos e estruturados
- Timestamp em todas as entradas
- Arquivo de log persistente

### 4. **Modularidade**
- Funções separadas por módulo
- Código reutilizável
- Fácil manutenção

### 5. **Idempotência**
- Verificação de instalações existentes
- Não reinstala pacotes já instalados
- Limpeza de arquivos temporários

## Pós-Instalação

### Docker
Após a instalação, faça logout e login novamente ou execute:
```bash
newgrp docker
```

### ZSH
O ZSH será o shell padrão. Para usar imediatamente:
```bash
zsh
```

## Verificação de Instalação

O script verifica automaticamente todas as instalações ao final. Você pode verificar manualmente:

```bash
# Verificar versões
docker --version
terraform --version
kubectl version --client
helm version
ansible --version
aws --version
```

## Troubleshooting

### Problemas Comuns

1. **Erro de permissão**
   ```bash
   sudo chmod +x devops_setup.sh
   ```

2. **Erro de conexão**
   - Verifique conectividade com internet
   - Verifique configurações de proxy

3. **Erro de repositório**
   - Verifique se está usando Ubuntu 24.04
   - Verifique se os repositórios estão acessíveis

### Logs Detalhados

Para análise de problemas, consulte:
```bash
tail -f /tmp/devops_setup.log
```

## Diferenças do Ansible

### Vantagens do Script Shell
- ✅ Não requer Ansible instalado
- ✅ Execução mais rápida
- ✅ Menos dependências
- ✅ Mais portável

### Vantagens do Ansible
- ✅ Idempotência nativa
- ✅ Gerenciamento de estado
- ✅ Suporte a múltiplos hosts
- ✅ Mais declarativo

## Contribuição

Para melhorar o script:
1. Mantenha a estrutura modular
2. Adicione logs detalhados
3. Implemente verificações de erro
4. Teste em ambiente limpo

## Licença

Este script é fornecido "como está" para fins educacionais e de desenvolvimento. 
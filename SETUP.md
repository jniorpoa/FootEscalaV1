# 🚀 FootEscala V1 - Guia de Instalação

> Instalação completa do FootEscala V1 em servidor Ubuntu/AWS EC2

## 📋 Pré-requisitos

### Servidor
- **OS**: Ubuntu 22.04 LTS
- **RAM**: Mínimo 2GB (recomendado 4GB)
- **Storage**: 20GB
- **Processador**: 2 vCPUs

### AWS EC2
- **Instance Type**: t3.small (recomendado) ou t2.micro (free tier)
- **Security Groups**: Portas 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Elastic IP**: Recomendado para IP fixo
- **Região**: sa-east-1 (São Paulo) ou mais próxima

---

## 🔧 Passo 1: Configurar Instância EC2

### 1.1 Criar Instância

1. Acesse o **AWS Console** → **EC2** → **Launch Instance**
2. Configure:
   ```
   Nome: FootEscala-V1
   AMI: Ubuntu Server 22.04 LTS (64-bit x86)
   Instance Type: t3.small
   Key Pair: Criar ou usar existente (.pem)
   Storage: 20 GB gp3
   ```

### 1.2 Security Group

Criar ou editar Security Group com as regras:

| Type | Protocol | Port | Source | Description |
|------|----------|------|---------|------------|
| SSH | TCP | 22 | Seu IP | Acesso SSH |
| HTTP | TCP | 80 | 0.0.0.0/0 | Web HTTP |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Web HTTPS |

### 1.3 Elastic IP (Opcional)

1. EC2 → Elastic IPs → Allocate Elastic IP
2. Actions → Associate → Selecione sua instância

---

## 💻 Passo 2: Conectar ao Servidor

```bash
# Ajustar permissões da chave
chmod 400 sua-chave.pem

# Conectar via SSH
ssh -i sua-chave.pem ubuntu@SEU_IP_EC2

# Ou se configurou Elastic IP
ssh -i sua-chave.pem ubuntu@elastic-ip
```

---

## 📦 Passo 3: Instalação Automatizada

### 3.1 Script de Instalação Completa

```bash
# Criar o script de instalação
cat > install-footescala.sh << 'SCRIPT_END'
#!/bin/bash

# FootEscala V1 - Instalador Automático
set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}⚽ Iniciando instalação do FootEscala V1...${NC}"

# Variáveis
PROJECT_DIR="/var/www/footescala/v1"
DOMAIN="footescala.jniorpoa.com"

# 1. Atualizar sistema
echo -e "${GREEN}Atualizando sistema...${NC}"
sudo apt update && sudo apt upgrade -y

# 2. Instalar Node.js 18
echo -e "${GREEN}Instalando Node.js 18...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Instalar Nginx
echo -e "${GREEN}Instalando Nginx...${NC}"
sudo apt-get install -y nginx

# 4. Instalar Git
echo -e "${GREEN}Instalando Git...${NC}"
sudo apt-get install -y git

# 5. Criar estrutura de diretórios
echo -e "${GREEN}Criando estrutura de diretórios...${NC}"
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER /var/www/footescala

# 6. Clonar repositório
echo -e "${GREEN}Clonando repositório...${NC}"
cd /var/www/footescala
git clone https://github.com/jniorpoa/FootEscalaV1.git v1
cd v1

# 7. Instalar dependências
echo -e "${GREEN}Instalando dependências...${NC}"
npm install

# 8. Build da aplicação
echo -e "${GREEN}Fazendo build...${NC}"
npm run build

echo -e "${BLUE}✅ Instalação base concluída!${NC}"
SCRIPT_END

# Executar o script
chmod +x install-footescala.sh
./install-footescala.sh
```

---

## 🌐 Passo 4: Configurar Nginx

### 4.1 Configuração para Subpath /v1

```bash
# Criar configuração do Nginx
sudo nano /etc/nginx/sites-available/footescala
```

Adicione o seguinte conteúdo:

```nginx
server {
    listen 80;
    server_name footescala.jniorpoa.com;
    
    # Logs
    access_log /var/log/nginx/footescala_access.log;
    error_log /var/log/nginx/footescala_error.log;
    
    # Configuração para /v1
    location /v1 {
        alias /var/www/footescala/v1/dist;
        try_files $uri $uri/ /v1/index.html;
        
        # Cache de assets
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Redirect root para v1
    location = / {
        return 301 /v1;
    }
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
    
    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

### 4.2 Ativar Configuração

```bash
# Ativar site
sudo ln -sf /etc/nginx/sites-available/footescala /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

---

## 🔐 Passo 5: Configurar SSL/HTTPS

### 5.1 Instalar Certbot

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obter certificado SSL
sudo certbot --nginx -d footescala.jniorpoa.com

# Seguir as instruções:
# - Email para notificações
# - Aceitar termos
# - Escolher redirect HTTP → HTTPS (opção 2)
```

### 5.2 Auto-renovação

```bash
# Testar renovação
sudo certbot renew --dry-run

# Verificar timer de renovação
sudo systemctl status certbot.timer
```

---

## 🔥 Passo 6: Configurar Firewall

```bash
# Configurar UFW
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Verificar status
sudo ufw status
```

---

## 📂 Passo 7: Estrutura de Versionamento

### 7.1 Preparar para múltiplas versões

```bash
# Estrutura de diretórios
/var/www/footescala/
├── v1/          # Versão 1 (atual)
├── v2/          # Versão 2 (futura)
└── v3/          # Versão 3 (futura)
```

### 7.2 Nginx para múltiplas versões

Adicione no arquivo de configuração do Nginx:

```nginx
# Para V2
location /v2 {
    alias /var/www/footescala/v2/dist;
    try_files $uri $uri/ /v2/index.html;
}

# Para V3
location /v3 {
    alias /var/www/footescala/v3/dist;
    try_files $uri $uri/ /v3/index.html;
}
```

---

## 🛠 Passo 8: Scripts de Manutenção

### 8.1 Script de Deploy

```bash
# Criar script de deploy
cat > /var/www/footescala/deploy.sh << 'EOF'
#!/bin/bash
VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Uso: ./deploy.sh v1|v2|v3"
    exit 1
fi

cd /var/www/footescala/$VERSION
git pull origin main
npm install
npm run build
sudo systemctl restart nginx
echo "✅ Deploy de $VERSION concluído!"
EOF

chmod +x /var/www/footescala/deploy.sh
```

### 8.2 Script de Backup

```bash
# Criar script de backup
cat > ~/backup-footescala.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)

# Backup de todas as versões
tar -czf $BACKUP_DIR/footescala_$DATE.tar.gz \
    /var/www/footescala \
    /etc/nginx/sites-available/footescala \
    --exclude='node_modules' \
    --exclude='dist'

echo "✅ Backup criado: footescala_$DATE.tar.gz"

# Manter apenas últimos 7 backups
ls -t $BACKUP_DIR/*.tar.gz | tail -n +8 | xargs rm -f
EOF

chmod +x ~/backup-footescala.sh

# Agendar backup diário
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backup-footescala.sh") | crontab -
```

---

## 🔍 Passo 9: Monitoramento

### 9.1 Logs

```bash
# Logs do Nginx
sudo tail -f /var/log/nginx/footescala_access.log
sudo tail -f /var/log/nginx/footescala_error.log

# Logs do sistema
sudo journalctl -xe
```

### 9.2 Monitoramento de recursos

```bash
# Instalar htop
sudo apt install htop -y

# Monitorar
htop

# Espaço em disco
df -h

# Memória
free -h
```

---

## ✅ Passo 10: Verificação Final

### 10.1 Testar acesso

```bash
# Testar localmente
curl -I http://localhost/v1

# Testar HTTPS
curl -I https://footescala.jniorpoa.com/v1
```

### 10.2 Checklist

- [ ] EC2 rodando
- [ ] Node.js 18 instalado
- [ ] Nginx configurado
- [ ] Aplicação buildada
- [ ] SSL/HTTPS funcionando
- [ ] Firewall configurado
- [ ] Backup agendado
- [ ] DNS apontando corretamente

---

## 🚨 Troubleshooting

### Erro 502 Bad Gateway

```bash
# Verificar permissões
sudo chown -R www-data:www-data /var/www/footescala/v1/dist
sudo chmod -R 755 /var/www/footescala/v1/dist

# Reiniciar Nginx
sudo systemctl restart nginx
```

### Build falha

```bash
cd /var/www/footescala/v1
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
npm run build
```

### SSL não funciona

```bash
# Verificar DNS
nslookup footescala.jniorpoa.com

# Renovar certificado
sudo certbot renew --force-renewal
```

### Nginx não inicia

```bash
# Testar configuração
sudo nginx -t

# Ver erro detalhado
sudo journalctl -xe | grep nginx
```

---

## 📊 Performance

### Otimizações recomendadas

1. **Swap para instâncias pequenas**:
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

2. **Nginx cache headers** (já configurado)
3. **Gzip compression** (já configurado)
4. **CDN CloudFlare** (opcional)

---

## 🎯 Comandos Úteis

```bash
# Deploy nova versão
cd /var/www/footescala && ./deploy.sh v1

# Reiniciar serviços
sudo systemctl restart nginx

# Ver status
sudo systemctl status nginx

# Backup manual
~/backup-footescala.sh

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Monitorar logs em tempo real
tail -f /var/log/nginx/footescala_*.log
```

---

## 📞 Suporte

**Issues**: [GitHub Issues](https://github.com/jniorpoa/FootEscalaV1/issues)

**Email**: footescala@jniorpoa.com

---

<div align="center">

**[Voltar ao README](README.md)**

</div>

#!/bin/bash

# Fix FootEscala V1 Deployment
set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}⚽ Corrigindo instalação do FootEscala V1...${NC}"

# 1. Remover instalação quebrada
echo -e "${YELLOW}Limpando instalação anterior...${NC}"
sudo rm -rf /var/www/footescala/v1

# 2. Criar estrutura correta
echo -e "${GREEN}Criando nova estrutura...${NC}"
sudo mkdir -p /var/www/footescala/v1
sudo chown -R $USER:$USER /var/www/footescala
cd /var/www/footescala/v1

# 3. Inicializar projeto com Vite
echo -e "${GREEN}Criando projeto com Vite...${NC}"
npm create vite@latest . -- --template react-ts

# 4. Instalar dependências
echo -e "${GREEN}Instalando dependências...${NC}"
npm install
npm install recharts papaparse lodash lucide-react
npm install -D @types/lodash @types/papaparse tailwindcss postcss autoprefixer

# 5. Configurar Tailwind
echo -e "${GREEN}Configurando Tailwind CSS...${NC}"
npx tailwindcss init -p

cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# 6. Configurar Vite para build em /dist
cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/v1/',
  build: {
    outDir: 'dist'
  }
})
EOF

# 7. Criar estrutura de arquivos base
echo -e "${GREEN}Criando arquivos base...${NC}"

# index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>FootEscala V1</title>
</head>
<body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
</body>
</html>
EOF

# src/index.css
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
EOF

# src/main.tsx
cat > src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

# src/App.tsx
cat > src/App.tsx << 'EOF'
import FootEscalaV1 from './FootEscalaV1'

function App() {
  return <FootEscalaV1 />
}

export default App
EOF

# 8. Criar componente placeholder
echo -e "${GREEN}Criando componente FootEscalaV1...${NC}"
cat > src/FootEscalaV1.tsx << 'EOF'
import React from 'react';
import { Clock, Upload } from 'lucide-react';

const FootEscalaV1 = () => {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Clock className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h1 className="text-2xl font-semibold text-gray-900">FootEscala V1</h1>
              <p className="text-sm text-gray-500">Sistema de gestão e análise de escalas de trabalho</p>
            </div>
          </div>
        </div>
      </header>
      
      <div className="max-w-7xl mx-auto px-6 py-12">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12">
          <div className="flex flex-col items-center justify-center">
            <Upload className="w-16 h-16 text-gray-400 mb-4" />
            <h2 className="text-2xl font-bold text-gray-900 mb-2">⚽ Sistema Instalado com Sucesso!</h2>
            <p className="text-gray-600 mb-8 text-center max-w-md">
              Para ativar o dashboard completo, substitua este arquivo pelo componente real.
            </p>
            <div className="bg-gray-100 rounded-lg p-4">
              <code className="text-sm text-gray-700">
                /var/www/footescala/v1/src/FootEscalaV1.tsx
              </code>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FootEscalaV1;
EOF

# 9. Build do projeto
echo -e "${GREEN}Fazendo build...${NC}"
npm run build

# 10. Configurar Nginx corretamente
echo -e "${GREEN}Configurando Nginx...${NC}"
sudo tee /etc/nginx/sites-available/footescala > /dev/null << 'EOF'
server {
    listen 80;
    server_name footescala.jniorpoa.com localhost;
    
    # Logs
    access_log /var/log/nginx/footescala_access.log;
    error_log /var/log/nginx/footescala_error.log;
    
    # Root redirect to /v1
    location = / {
        return 301 /v1/;
    }
    
    # V1 Application
    location /v1 {
        alias /var/www/footescala/v1/dist;
        try_files $uri $uri/ /v1/index.html;
        
        # Headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
    }
    
    # Static assets with cache
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
}
EOF

# 11. Reativar site
echo -e "${GREEN}Ativando site no Nginx...${NC}"
sudo ln -sf /etc/nginx/sites-available/footescala /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 12. Testar e reiniciar Nginx
echo -e "${GREEN}Reiniciando Nginx...${NC}"
sudo nginx -t
sudo systemctl restart nginx

# 13. Criar scripts úteis
echo -e "${GREEN}Criando scripts auxiliares...${NC}"

# Script de rebuild
cat > /var/www/footescala/v1/rebuild.sh << 'EOF'
#!/bin/bash
echo "🔨 Rebuilding FootEscala V1..."
npm run build
sudo systemctl restart nginx
echo "✅ Build concluído!"
EOF
chmod +x /var/www/footescala/v1/rebuild.sh

# Script para adicionar componente real
cat > /var/www/footescala/v1/add-component.sh << 'EOF'
#!/bin/bash
echo "📝 Para adicionar o componente real:"
echo "1. Edite: nano /var/www/footescala/v1/src/FootEscalaV1.tsx"
echo "2. Cole o código do dashboard completo"
echo "3. Execute: ./rebuild.sh"
EOF
chmod +x /var/www/footescala/v1/add-component.sh

# 14. Obter IP público
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)

# 15. Informações finais
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}     ✅ FootEscala V1 Corrigido!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}📋 STATUS:${NC}"
echo ""

# Verificar se Nginx está rodando
if systemctl is-active --quiet nginx; then
    echo -e "Nginx: ${GREEN}✓ Ativo${NC}"
else
    echo -e "Nginx: ${RED}✗ Inativo${NC}"
fi

# Verificar se o build existe
if [ -d "/var/www/footescala/v1/dist" ]; then
    echo -e "Build: ${GREEN}✓ Criado${NC}"
else
    echo -e "Build: ${RED}✗ Não encontrado${NC}"
fi

# Verificar se o site responde
if curl -s -o /dev/null -w "%{http_code}" http://localhost/v1 | grep -q "200\|301\|304"; then
    echo -e "Site Local: ${GREEN}✓ Respondendo${NC}"
else
    echo -e "Site Local: ${YELLOW}⚠ Verificar${NC}"
fi

echo ""
echo -e "${BLUE}🌐 ACESSO:${NC}"
echo ""
echo -e "Local: ${GREEN}http://localhost/v1${NC}"
echo -e "IP Público: ${GREEN}http://$PUBLIC_IP/v1${NC}"
echo -e "Domínio: ${GREEN}http://footescala.jniorpoa.com/v1${NC}"
echo ""
echo -e "${BLUE}📝 PRÓXIMOS PASSOS:${NC}"
echo ""
echo "1. Para adicionar o dashboard completo:"
echo -e "   ${YELLOW}nano /var/www/footescala/v1/src/FootEscalaV1.tsx${NC}"
echo ""
echo "2. Cole o código do componente (do artifact)"
echo ""
echo "3. Rebuild a aplicação:"
echo -e "   ${YELLOW}cd /var/www/footescala/v1 && ./rebuild.sh${NC}"
echo ""
echo "4. Configurar DNS (se ainda não estiver):"
echo "   - Aponte footescala.jniorpoa.com para $PUBLIC_IP"
echo ""
echo "5. Configurar HTTPS (após DNS funcionar):"
echo -e "   ${YELLOW}sudo certbot --nginx -d footescala.jniorpoa.com${NC}"
echo ""
echo -e "${GREEN}================================================${NC}"

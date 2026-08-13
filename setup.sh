#!/usr/bin/env bash

# ====================================================================
# Автоматический скрипт установки и настройки Gemini Cloud Browser + Nginx
# ====================================================================

set -e

echo "🚀 Начинаем полную авто-установку Gemini Cloud Browser..."

# 1. Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Ошибка: запустите скрипт с правами root (sudo ./setup.sh)"
  exit 1
fi

# 2. Обновление пакетов и установка зависимостей
echo "📦 Проверяем пакеты и зависимости..."
apt-get update -y
apt-get install -y curl wget git nginx certbot python3-certbot-nginx

# 3. Проверка и установка Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Устанавливаем Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh
else
    echo "✅ Docker уже установлен."
fi

# 4. Установка современного Docker Compose v2 (замена старого Python 1.29.2)
echo "🛠 Обновляем Docker Compose до версии v2..."
mkdir -p /usr/libexec/docker/cli-plugins /usr/local/bin
curl -sSL "https://github.com/docker/compose/releases/download/v2.29.1/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
cp -f /usr/local/bin/docker-compose /usr/libexec/docker/cli-plugins/docker-compose 2>/dev/null || true

# 5. Полная очистка старых контейнеров и несовместимых кешей
echo "🧹 Очищаем старые версии контейнеров..."
docker rm -f gemini-browser 2>/dev/null || true
docker ps -a --filter "name=gemini" -q | xargs -r docker rm -f 2>/dev/null || true

# 6. Генерация надежного пароля, если пароль еще не меняли
if grep -q "ChangeMeSecurePassword123!" docker-compose.yml; then
    GEN_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
    sed -i "s/ChangeMeSecurePassword123!/$GEN_PASSWORD/g" docker-compose.yml
else
    GEN_PASSWORD=$(grep "PASSWORD=" docker-compose.yml | cut -d'=' -f2 | tr -d ' ')
fi

# 7. Создание директории для хранения профиля браузера
mkdir -p browser-profile
chmod -R 777 browser-profile

# 8. Запуск контейнера через новый Docker Compose v2
echo "🏎 Запускаем Docker-контейнер Chromium..."
/usr/local/bin/docker-compose up -d

# 9. Автоматическая настройка Nginx
echo "🌐 Настраиваем веб-сервер Nginx..."
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
cp -f nginx.conf /etc/nginx/sites-available/gemini
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/gemini /etc/nginx/sites-enabled/gemini

# Проверка конфига Nginx и запуск
nginx -t
systemctl restart nginx
systemctl enable nginx

# Определение внешнего IP-адреса сервера
SERVER_IP=$(curl -s ifconfig.me || curl -s api.ipify.org || echo "78.17.155.213")

echo ""
echo "======================================================================"
echo "🎉 ВСЁ ГОТОВО! ОБЛАЧНЫЙ БРАУЗЕР УСПЕШНО НАСТРОЕН И ЗАПУЩЕН!"
echo "======================================================================"
echo "🌐 Ссылка для входа в браузер:"
echo "   http://$SERVER_IP"
echo ""
echo "🔑 Данные авторизации (KasmVNC):"
echo "   Логин:  admin"
echo "   Пароль: $GEN_PASSWORD"
echo "======================================================================"

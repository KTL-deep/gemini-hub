#!/usr/bin/env bash

# ====================================================================
# Автоматический скрипт установки Облачного Браузера Gemini (KasmVNC)
# Запускать на VPS сервере в Польше (Ubuntu / Debian)
# ====================================================================

set -e

echo "🚀 Начинаем установку Gemini Cloud Browser..."

# 1. Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Ошибка: запустите скрипт с правами root (sudo ./setup.sh)"
  exit 1
fi

# 2. Обновление пакетов и установка зависимостей
echo "📦 Обновляем системные пакеты..."
apt-get update -y
apt-get install -y curl wget git nginx certbot python3-certbot-nginx

# 3. Проверка и установка Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Устанавливаем Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
else
    echo "✅ Docker уже установлен."
fi

# 4. Проверка и установка Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "🛠 Устанавливаем Docker Compose..."
    apt-get install -y docker-compose-plugin docker-compose
fi

# 5. Генерация надежного пароля, если пользователь не менял его
GEN_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
sed -i "s/ChangeMeSecurePassword123!/$GEN_PASSWORD/g" docker-compose.yml

# 6. Создание директории для хранения профиля браузера
mkdir -p browser-profile
chmod -R 777 browser-profile

# 7. Запуск контейнера
echo "🏎 Запускаем Docker-контейнер Chromium..."
docker compose up -d || docker-compose up -d

echo ""
echo "======================================================================"
echo "🎉 ОБЛАЧНЫЙ БРАУЗЕР УСПЕШНО ЗАПУЩЕН!"
echo "======================================================================"
echo "Логин пользователя: admin"
echo "Ваш сгенерированный пароль: $GEN_PASSWORD"
echo ""
echo "Локальный адрес браузера: http://127.0.0.1:3000"
echo ""
echo "📌 СЛЕДУЮЩИЕ ШАГИ:"
echo "1. Скопируйте файл nginx.conf в /etc/nginx/sites-available/gemini"
echo "2. Укажите там ваш домен вместо YOUR_DOMAIN.COM"
echo "3. Активируйте симлинк и перезапустите Nginx:"
echo "   ln -s /etc/nginx/sites-available/gemini /etc/nginx/sites-enabled/"
echo "   systemctl reload nginx"
echo "4. Выпустите бесплатный SSL-сертификат:"
echo "   certbot --nginx -d ваш_домен.com"
echo "======================================================================"

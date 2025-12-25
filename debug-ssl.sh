#!/bin/bash

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Использование: ./debug-ssl.sh <DOMAIN>"
    exit 1
fi

echo "--- ЗАПУСК ДИАГНОСТИКИ ---"

# 1. Применяем HTTP конфиг
echo "1. Применяем HTTP конфигурацию..."
sed "s/YOUR_DOMAIN/$DOMAIN/g" nginx.conf.http > nginx.conf

# 2. Перезапускаем Nginx
echo "2. Перезапускаем Nginx..."
docker-compose up -d --force-recreate nginx
sleep 3

# 3. Создаем тестовый файл проверки
echo "3. Создаем тестовый файл..."
mkdir -p certbot/www/.well-known/acme-challenge
echo "success" > certbot/www/.well-known/acme-challenge/test-file
chmod -R 755 certbot/www

# 4. Проверяем доступность файла через curl (локально)
echo "4. Проверка доступа через curl (localhost)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/.well-known/acme-challenge/test-file)
echo "Код ответа: $HTTP_CODE"

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Файл успешно доступен локально!"
else
    echo "❌ Ошибка доступа к файлу!"
fi

# 5. Вывод логов Nginx
echo "5. Логи Nginx (последние 20 строк):"
docker-compose logs --tail=20 nginx

echo "--- КОНЕЦ ДИАГНОСТИКИ ---"
echo "Попробуйте также открыть в браузере: http://$DOMAIN/.well-known/acme-challenge/test-file"

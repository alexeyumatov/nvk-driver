#!/bin/bash

# Скрипт для автоматической настройки SSL (Let's Encrypt)
# Запускать на сервере!

if [ "$#" -ne 2 ]; then
    echo "Использование: ./setup-ssl.sh <DOMAIN> <EMAIL>"
    echo "Пример: ./setup-ssl.sh nvk-driver.ru admin@nvk-driver.ru"
    exit 1
fi

DOMAIN=$1
EMAIL=$2

echo "--- Настройка SSL для домена: $DOMAIN ---"

# 1. Подготовка конфигурации для HTTP (чтобы пройти проверку Certbot)
echo "1. Создание конфигурации Nginx для HTTP..."
sed "s/YOUR_DOMAIN/$DOMAIN/g" nginx.conf.http > nginx.conf

# 2. Запуск Nginx
echo "2. Запуск Nginx..."
docker-compose up -d nginx

echo "Ожидание запуска Nginx..."
sleep 5

# 3. Запрос сертификата
echo "3. Запрос сертификата у Let's Encrypt..."
docker-compose run --rm --entrypoint certbot certbot certonly --webroot --webroot-path /var/www/certbot -d $DOMAIN --email $EMAIL --agree-tos --no-eff-email

if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось получить сертификат. Проверьте логи и настройки DNS."
    echo "Убедитесь, что домен $DOMAIN направлен на этот сервер."
    exit 1
fi

# 4. Применение конфигурации HTTPS
echo "4. Сертификат получен! Применение HTTPS конфигурации..."
sed "s/YOUR_DOMAIN/$DOMAIN/g" nginx.conf.ssl > nginx.conf

# 5. Перезагрузка Nginx
echo "5. Перезагрузка Nginx..."
docker-compose restart nginx

echo "--- Готово! Сайт должен быть доступен по https://$DOMAIN ---"

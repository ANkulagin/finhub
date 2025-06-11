FROM node:20-alpine

# Установка необходимых пакетов
RUN apk add --no-cache \
    git \
    bash

# Создание рабочей директории
WORKDIR /app

# Установка pnpm глобально (более быстрый пакетный менеджер)
RUN npm install -g pnpm

# Порт для dev сервера
EXPOSE 3000

# Порт для Vite HMR
EXPOSE 5173

# Команда по умолчанию
CMD ["sh", "-c", "pnpm install && pnpm dev"]

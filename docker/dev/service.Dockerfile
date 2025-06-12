FROM golang:1.24-alpine

# Установка необходимых пакетов
RUN apk add --no-cache \
    git \
    make \
    bash \
    curl \
    postgresql-client \
    redis

# Установка инструментов для разработки
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.64.0 && \
    go install github.com/air-verse/air@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install golang.org/x/tools/gopls@latest && \
    go install github.com/swaggo/swag/cmd/swag@latest && \
    go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Создание рабочей директории
WORKDIR /app


COPY go.mod ./

# Создаем go.sum внутри контейнера и скачиваем зависимости
# Эта команда сработает, даже если go.sum изначально отсутствовал.
# Она создаст его на основе go.mod.
RUN go mod download



# Установка переменных окружения
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

# Порт для приложения
EXPOSE 8080

# Порт для дебаггера Delve
EXPOSE 2345

# Команда по умолчанию - запуск через air для hot reload
CMD ["air"]

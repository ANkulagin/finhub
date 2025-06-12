# Build stage
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /build

# Копируем go mod файлы
COPY go.mod go.sum ./
RUN go mod download

# Копируем исходный код
COPY . .

# Сборка приложения
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o app ./cmd/main.go

# Runtime stage
FROM scratch

# Копируем сертификаты
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Копируем бинарник
COPY --from=builder /build/app /app

# Копируем конфигурации если нужны
# COPY --from=builder /build/configs /configs

EXPOSE 8080

ENTRYPOINT ["/app"]

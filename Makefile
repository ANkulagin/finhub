.PHONY: help up down logs ps restart clean test lint deps build

# Цвета для вывода
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

# Переменные
DOCKER_COMPOSE = docker compose
SERVICE ?=

help: ## Показать справку
	@echo ''
	@echo 'Использование:'
	@echo ' ${YELLOW}make${RESET} ${GREEN}<команда>${RESET}'
	@echo ''
	@echo 'Команды:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf " ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf " ${CYAN}%s${RESET}\n", substr($$1,4)} \
	}' $(MAKEFILE_LIST)

## Docker команды

up: ## Запуск всех сервисов
	@echo "${GREEN}Запускаем Docker Compose...${RESET}"
	$(DOCKER_COMPOSE) up -d


down: ## Остановка всех сервисов
	@echo "${YELLOW}Останавливаем Docker Compose...${RESET}"
	$(DOCKER_COMPOSE) down

logs: ## Просмотр логов (SERVICE=имя_сервиса для конкретного)
ifdef SERVICE
	$(DOCKER_COMPOSE) logs -f $(SERVICE)
else
	$(DOCKER_COMPOSE) logs -f
endif

ps: ## Статус контейнеров
	$(DOCKER_COMPOSE) ps

restart: ## Перезапуск сервисов
ifdef SERVICE
	@echo "${YELLOW}Перезапускаем $(SERVICE)...${RESET}"
	$(DOCKER_COMPOSE) restart $(SERVICE)
else
	@echo "${YELLOW}Перезапускаем все сервисы...${RESET}"
	$(DOCKER_COMPOSE) restart
endif

clean: ## Остановка и удаление volumes
	@echo "${YELLOW}Останавливаем и удаляем все данные...${RESET}"
	$(DOCKER_COMPOSE) down -v

shell: ## Войти в dev-shell контейнер
	@echo "${GREEN}Входим в dev-shell...${RESET}"
	$(DOCKER_COMPOSE) exec dev-shell /bin/bash

## Утилиты для проверки подключений

check-postgres: ## Проверить подключение к PostgreSQL
	$(DOCKER_COMPOSE) exec postgres pg_isready -U ${POSTGRES_USER}

check-redis: ## Проверить подключение к Redis
	$(DOCKER_COMPOSE) exec redis redis-cli -a ${REDIS_PASSWORD} ping

check-kafka: ## Проверить Kafka
	$(DOCKER_COMPOSE) exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092

## Go команды

build: ## Сборка приложения
	go build -o bin/app cmd/main.go

## Инициализация

init: ## Первоначальная настройка проекта
	@echo "${GREEN}Инициализация проекта...${RESET}"
	cp local.env.example .env
	@echo "${YELLOW}Создаем необходимые директории...${RESET}"
	mkdir -p configs/{prometheus,grafana/provisioning/{dashboards,datasources},loki}
	mkdir -p docker/dev
	@echo "${GREEN}Готово! Теперь выполните 'make up'${RESET}"

# Backend команды
backend-shell: ## Войти в backend контейнер
	docker compose exec backend /bin/sh

backend-logs: ## Логи backend
	docker compose logs -f backend

# Команды для разработки
dev: ## Запустить backend в режиме разработки
	docker compose up backend

dev-all: ## Запустить все сервисы включая backend
	docker compose up -d
	@echo "${GREEN}Готово!"

dev-frontend: ## Запустить с frontend
	docker compose --profile frontend up

# Команды выполняемые в backend контейнере
test: ## Запуск тестов
	docker compose exec backend go test -v -race -cover ./...

lint: ## Запуск линтера
	docker compose exec backend golangci-lint run

deps: ## Обновить зависимости
	docker compose exec backend go mod tidy
	docker compose exec backend go mod verify

swagger: ## Генерация Swagger документации
	docker compose exec backend swag init -g cmd/main.go

migrate-create: ## Создать новую миграцию (NAME=migration_name)
	docker compose exec backend migrate create -ext sql -dir ./migrations -seq $(NAME)

migrate-up: ## Применить миграции
	docker compose exec backend migrate -path ./migrations -database "postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@postgres:5432/$(POSTGRES_DB)?sslmode=disable" up

migrate-down: ## Откатить миграции
	docker compose exec backend migrate -path ./migrations -database "postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@postgres:5432/$(POSTGRES_DB)?sslmode=disable" down

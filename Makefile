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
	@echo '  ${YELLOW}make${RESET} ${GREEN}<команда>${RESET} [${CYAN}SERVICE=<имя_сервиса>${RESET}]'
	@echo ''
	@echo 'Примеры:'
	@echo '  ${YELLOW}make up${RESET}'
	@echo '  ${YELLOW}make logs SERVICE=gateway-svc${RESET}'
	@echo '  ${YELLOW}make test SERVICE=auth-svc${RESET}'
	@echo ''
	@echo 'Команды:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf " ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf " ${CYAN}%s${RESET}\n", substr($$1,4)} \
	}' $(MAKEFILE_LIST)

## ------------------ Docker команды ------------------
up: ## Запустить все сервисы в фоновом режиме
	@echo "${GREEN}Запускаем Docker Compose...${RESET}"
	$(DOCKER_COMPOSE) up -d

down: ## Остановить все запущенные сервисы
	@echo "${YELLOW}Останавливаем Docker Compose...${RESET}"
	$(DOCKER_COMPOSE) down

logs: ## Показать логи (SERVICE=имя_сервиса для конкретного)
	@if [ -z "$(SERVICE)" ]; then \
		$(DOCKER_COMPOSE) logs -f; \
	else \
		$(DOCKER_COMPOSE) logs -f $(SERVICE); \
	fi

ps: ## Показать статус всех контейнеров
	$(DOCKER_COMPOSE) ps

restart: ## Перезапустить сервисы (SERVICE=имя_сервиса для конкретного)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${YELLOW}Перезапускаем все сервисы...${RESET}"; \
		$(DOCKER_COMPOSE) restart; \
	else \
		echo "${YELLOW}Перезапускаем $(SERVICE)...${RESET}"; \
		$(DOCKER_COMPOSE) restart $(SERVICE); \
	fi

clean: ## Остановить сервисы и удалить все данные (volumes)
	@echo "${YELLOW}Останавливаем и удаляем все данные...${RESET}"
	$(DOCKER_COMPOSE) down -v

## ------------------ Команды для разработки ------------------
shell: ## Войти в командную строку контейнера (требуется SERVICE)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${YELLOW}Пожалуйста, укажите сервис, например: make shell SERVICE=gateway-svc${RESET}"; \
		exit 1; \
	fi
	@echo "${GREEN}Входим в контейнер $(SERVICE)...${RESET}"
	$(DOCKER_COMPOSE) exec $(SERVICE) /bin/bash

test: ## Запустить тесты для сервиса (требуется SERVICE)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${YELLOW}Пожалуйста, укажите сервис, например: make test SERVICE=auth-svc${RESET}"; \
		exit 1; \
	fi
	@echo "${GREEN}Запускаем тесты для $(SERVICE)...${RESET}"
	$(DOCKER_COMPOSE) exec $(SERVICE) go test -v -race -cover ./...

lint: ## Запустить линтер для сервиса (требуется SERVICE)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${YELLOW}Пожалуйста, укажите сервис, например: make lint SERVICE=auth-svc${RESET}"; \
		exit 1; \
	fi
	@echo "${GREEN}Запускаем линтер для $(SERVICE)...${RESET}"
	$(DOCKER_COMPOSE) exec $(SERVICE) golangci-lint run

deps: ## Обновить зависимости для сервиса (требуется SERVICE)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${YELLOW}Пожалуйста, укажите сервис, например: make deps SERVICE=auth-svc${RESET}"; \
		exit 1; \
	fi
	@echo "${GREEN}Обновляем зависимости для $(SERVICE)...${RESET}"
	$(DOCKER_COMPOSE) exec $(SERVICE) go mod tidy
	$(DOCKER_COMPOSE) exec $(SERVICE) go mod verify

swagger: ## Сгенерировать Swagger документацию (требуется SERVICE)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${YELLOW}Пожалуйста, укажите сервис, например: make swagger SERVICE=gateway-svc${RESET}"; \
		exit 1; \
	fi
	@echo "${GREEN}Генерируем Swagger для $(SERVICE)...${RESET}"
	$(DOCKER_COMPOSE) exec $(SERVICE) swag init -g cmd/main.go

## ------------------ Миграции БД (выполняются из gateway-svc) ------------------
migrate-create: ## Создать новую миграцию (NAME=migration_name)
	@echo "${GREEN}Создаем миграцию $(NAME)...${RESET}"
	$(DOCKER_COMPOSE) exec gateway-svc migrate create -ext sql -dir ./migrations -seq $(NAME)

migrate-up: ## Применить все миграции
	@echo "${GREEN}Применяем миграции...${RESET}"
	$(DOCKER_COMPOSE) exec gateway-svc migrate -path ./migrations -database "postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@postgres:5432/$(POSTGRES_DB)?sslmode=disable" up

migrate-down: ## Откатить последнюю миграцию
	@echo "${YELLOW}Откатываем миграцию...${RESET}"
	$(DOCKER_COMPOSE) exec gateway-svc migrate -path ./migrations -database "postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@postgres:5432/$(POSTGRES_DB)?sslmode=disable" down

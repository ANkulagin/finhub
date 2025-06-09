  
.PHONY: up deps lint test  
up: ## Запуск dev-стека  
	docker compose up -d  
deps: ## Установка зависимостей  
	go mod tidy  
lint: ## Линтер  
	golangci-lint run  
test: ## Тесты  
	go test ./...  


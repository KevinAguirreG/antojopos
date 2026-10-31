.PHONY: up down seed contracts test lint logs e2e
SVC ?=

up:        ## brings up everything with Docker Compose
	docker compose up -d --build --wait
down:      ## stops it, keeps volumes
	docker compose down
seed:      ## demo tenant with menu and users
	docker compose exec identity php artisan db:seed --class=DemoTenantSeeder
contracts: ## regenerates types from contracts/events/*.json
	./scripts/gen-contracts.sh
test:      ## make test | make test SVC=orders
	./scripts/run.sh test $(SVC)
lint:
	./scripts/run.sh lint $(SVC)
logs:
	docker compose logs -f $(SVC)
e2e:       ## Playwright against the running Compose stack
	pnpm --dir tests/e2e test

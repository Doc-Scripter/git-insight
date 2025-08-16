# Makefile for GitInsight
VERSION := $(shell git tag || echo "untagged")

.PHONY: all build run test clean help health-check-api health-check-backend monitor-metrics monitor-logs update-tag

help:
	@echo "Usage: make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  all                     Builds all services"
	@echo "  build                   Builds GitInsight services"
	@echo "  run                     Runs GitInsight services"
	@echo "  test                    Runs tests"
	@echo "  clean                   Cleans build artifacts"
	@echo "  health-check-api        Performs API Gateway health check"
	@echo "  health-check-backend    Performs Backend Service health check"
	@echo "  monitor-metrics         Simulates metrics monitoring"
	@echo "  monitor-logs            Simulates logs monitoring"
	@echo "  help                    Displays this help message"
	@echo "  release                 Creates a release archive"
	@echo "  update-tag 	         Updates the Changelog.txt file"

all: build

build:
	@echo "Building GitInsight services..."
	# Add commands to build your services (e.g., go build, npm install, docker build)
	# Example: docker-compose build

update-tag:
	@echo "Updating tag"
	# git tag -d $(VERSION)
	# git push origin --delete $(VERSION)
	git tag -a $(VERSION) -m "Release version $(VERSION)"
	git push origin $(VERSION)
run:
	@echo "Running GitInsight services..."
	# Add commands to run your services (e.g., go run, npm start, docker-compose up)
	# Example: docker-compose up -d

test:
	@echo "Running tests..."
	# Add commands to run your tests
	# Example: go test ./...

clean:
	@echo "Cleaning build artifacts..."
	# Add commands to clean up build artifacts
	# Example: docker-compose down --volumes --remove-orphans

health-check-api:
	@echo "Performing API Gateway health check..."
	# Example: curl -f http://localhost:8080/health || (echo "API Gateway health check failed!" && exit 1)

health-check-backend:
	@echo "Performing Backend Service health check..."
	# Example: curl -f http://localhost:8081/health || (echo "Backend service health check failed!" && exit 1)

monitor-metrics:
	@echo "Simulating metrics monitoring..."
	# This would typically involve checking Prometheus/Grafana dashboards or querying metrics directly.
	# Example: curl http://localhost:9090/api/v1/query?query=up

monitor-logs:
	@echo "Simulating logs monitoring..."
	# This would typically involve checking Kibana/Grafana Loki dashboards or querying logs directly.
	# Example: docker-compose logs -f

release:
	@echo "Creating release archive..."
	$(eval RELEASE_DIR := release-$(shell git describe --tags | sed 's/-dirty//g' || echo "untagged"))
	mkdir -p $(RELEASE_DIR) && \
	cp Changelog.txt $(RELEASE_DIR)/Changelog.txt && \
	tar -czvf $(RELEASE_DIR).tar.gz $(RELEASE_DIR) && \
	rm -rf $(RELEASE_DIR) && \
	echo "Release archive created: $(RELEASE_DIR).tar.gz"
projectDir := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
os := $(shell uname)
VERSION ?= $(shell git rev-parse --short HEAD)
registry = nzacharia/ref-service
stabletag= v1
canarytag= v2
# P2P tasks

.PHONY: local
local: build local-stubbed-functional local-stubbed-nft

.PHONY: build
build:
	docker compose run --rm gradle_build sh -c 'gradle service:build'

.PHONY: local-stubbed-functional
local-stubbed-functional:
	docker compose build service downstream database --no-cache
	docker compose up -d service downstream database waitForHealthyPods
	docker compose run --rm gradle_build sh -c 'gradle functional:clean functional:test'
	docker compose down
	sudo rm -rf db-data

.PHONY: local-stubbed-nft
local-stubbed-nft:
	docker compose build service downstream database --no-cache
	docker compose up -d database downstream service waitForHealthyPods
	docker compose run --rm k6 run ./nft/ramp-up/test.js
	docker compose down

.PHONY: stubbed-functional
stubbed-functional:
	docker compose run --rm gradle_build sh -c 'gradle functional:clean functional:test'

.PHONY: stubbed-nft
stubbed-nft:
	docker compose run --rm k6 run ./nft/ramp-up/test.js

.PHONY: extended-stubbed-nft
extended-stubbed-nft:
	@echo "Not implemented!"

.PHONY: integrated
integrated:
	@echo "Not implemented!"

# Custom tasks
.PHONY: run-local
run-local:
	docker compose build service downstream --no-cache
	docker compose up -d downstream database
	docker compose run --service-ports --rm service


# Minikube local tasks

.PHONY: enable-ingress
enable-ingress:
	minikube addons enable ingress
	minikube tunnel &


.PHONY: enable-proxy
enable-proxy:
	toxiproxy-cli -h localhost:8474/toxiproxy create -l 0.0.0.0:8686 -u database.reference-service-showcase:5432 db-proxy


.PHONY: deploy-manifests
deploy-manifests:
	kubectl apply -f service/k8s-manifests/namespace.yml
	kubectl apply -f service/k8s-manifests/deployment.yml
	kubectl apply -f service/k8s-manifests/postgres-config.yml
	kubectl apply -f service/k8s-manifests/postgres-deployment.yml
	kubectl apply -f service/k8s-manifests/toxiproxy.yml
	kubectl apply -f service/k8s-manifests/postgres-pvc-pv.yml
	kubectl apply -f service/k8s-manifests/deployment.yml
	kubectl apply -f service/k8s-manifests/postgres-service.yml	
	kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
	kubectl apply -f service/k8s-manifests/expose.yml
	sleep 10


.PHONY: check-resources
check-resources:
	sleep 40
	kubectl get po -n reference-service-showcase
	kubectl get ingress -n reference-service-showcase
	kubectl get svc -A


.PHONY: docker-build
docker-build:
	docker build --file Dockerfile.service --tag $(registry) .

.PHONY: docker-push
docker-push:
	docker push $(registry)

.PHONY: docker-build-minikube-stable
docker-build-minikube-stable:
	docker build --file Dockerfile.service --tag $(registry):$(stabletag) .

.PHONY: docker-build-minikube-canary
docker-build-minikube-canary:
	docker build --file Dockerfile.service --tag $(registry):$(canarytag) .
init-mac:
	brew install fop
	brew install openssl
	brew install openjdk
	brew install unixodbc
	brew install --build-from-source wxmac

init-asdf:
	asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
	asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
	asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
	asdf install

generate-translations:
	@echo "⌛️ generating translations"
	mix gettext.extract
	mix gettext.merge priv/gettext --locale fr

reset-test-db:
	MIX_ENV=test mix ecto.drop
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate

test: reset-test-db
	MIX_ENV=test mix test

coverage: reset-test-db
	MIX_ENV=test mix coveralls.lcov 

build-and-push-docker-image:
	export COMMIT=$$(git rev-parse HEAD) && \
	docker build --build-arg COMMIT="$$COMMIT" --no-cache -t wecraft-web . && \
	docker tag wecraft-web:latest laibulle/wecraft-web:latest && \
	docker push laibulle/wecraft-web:latest && \
	docker rmi wecraft-web:latest

deploy-to-prod:
	cd ../infra && make update-wecraft-prod

download-mcp-proxy:
	@echo "⌛️ Downloading MCP proxy..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		curl -sL https://github.com/tidewave-ai/mcp_proxy_rust/releases/latest/download/mcp-proxy-aarch64-apple-darwin.tar.gz | tar xv; \
	else \
		curl -sL https://github.com/tidewave-ai/mcp_proxy_rust/releases/latest/download/mcp-proxy-x86_64-unknown-linux-musl.tar.gz | tar zxv; \
	fi

remote-build-and-push:
	@echo "🚀 Building and pushing Docker image from remote server..."
	@ssh guillaume@192.168.1.2 "cd sources/wecraft && git pull origin main && make build-and-push-docker-image"

remote-build-and-push-and-deploy: remote-build-and-push deploy-to-prod

.PHONY: generate-translations test coverage build-and-push-docker-image remote-build-and-push remote-build-and-push-and-deploy deploy-to-prod
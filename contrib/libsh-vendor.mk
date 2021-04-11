vendor-libsh: ## Vendors updated version of libsh
	@echo "--- $@"
	curl --proto '=https' --tlsv1.2 -sSf \
		https://fnichol.github.io/libsh/install.sh \
		| sh -s -- --mode=vendor --release=latest
.PHONY: vendor-libsh

# Loaded alongside the source tree's Makefile, including refs that predate golden.
# Use the image ID directly: a ref with different dependencies must never retag
# the working tree's image or inherit a stale stamp from another checkout.
.PHONY: golden-render
golden-render:
	@set -e; image=$$(docker build -q --build-arg RUBY_VERSION=$(RUBY_VERSION) \
		--build-arg BUNDLER_VERSION=$(BUNDLER_VERSION) .); \
		echo "Golden source: $(PWD) -> $(MOUNT)" >&2; \
		docker run --rm $(DOCKER_RUN_OPTS) -e JEKYLL_ENV=production \
			-v "$(PWD):$(MOUNT):ro" -w "$(MOUNT)" \
			$(if $(filter 1,$(STANDARD_SITE)),-v "$(GOLDEN_CACHE)/_data:$(MOUNT)/_data:ro") \
			-v "$(GOLDEN_CACHE):$(MOUNT)/.jekyll-cache" "$$image" \
			bundle exec jekyll build --config _config.yml,.jekyll-cache/golden.yml \
			--destination .jekyll-cache/site > "$(GOLDEN_CACHE)/build.log" 2>&1 || \
			{ cat "$(GOLDEN_CACHE)/build.log" >&2; exit 1; }

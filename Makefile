# Makefile (No changes needed from your last version)
IMAGE := jekyll-image-agude
MOUNT := /workspace

.PHONY: all clean serve drafts debug image refresh

all: serve

image: Dockerfile Gemfile # Gemfile.lock is generated inside image, not needed as dependency here
	@echo "Building Docker image $(IMAGE) using '.' as context..."
	@if [ ! -f .dockerignore ]; then \
		echo "Warning: .dockerignore file not found. Build context might be large or include unwanted files."; \
	fi
	@docker build . -f Dockerfile -t $(IMAGE)

refresh: Dockerfile Gemfile
	@echo "Rebuilding Docker image $(IMAGE) with --no-cache..."
	@if [ ! -f .dockerignore ]; then \
		echo "Warning: .dockerignore file not found. Build context might be large or include unwanted files."; \
	fi
	@docker build . -f Dockerfile -t $(IMAGE) --no-cache

clean: image
	@echo "Cleaning Jekyll build artifacts..."
	@docker run --rm -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll clean

serve: image clean
	@echo "Serving site at http://localhost:4000 (or http://<docker_ip>:4000)..."
	@docker run --rm -p 4000:4000 -p 35729:35729 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll serve --host 0.0.0.0 --watch --incremental --livereload

drafts: image clean
	@echo "Serving site with drafts at http://localhost:4000 (or http://<docker_ip>:4000)..."
	@docker run --rm -p 4000:4000 -p 35729:35729 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll serve --host 0.0.0.0 --drafts --future --watch --incremental --livereload

debug: image
	@echo "Starting interactive debug session in container..."
	@docker run -it --rm -p 4000:4000 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) /bin/bash

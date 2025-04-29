# Makefile
IMAGE := jekyll-image-agude
MOUNT := /workspace
# Define Ruby and Bundler versions, ideally matching Dockerfile FROM and ARG lines
# Extract Ruby version automatically (adjust grep/cut if FROM line changes format)
RUBY_VERSION := $(shell grep '^FROM ruby:' Dockerfile | cut -d: -f2)
# Use the Bundler version specified as ARG in Dockerfile/Makefile
BUNDLER_VERSION := 2.6.7 # <-- Keep this updated
BASE_RUBY_IMAGE := ruby:$(RUBY_VERSION)

.PHONY: all clean serve drafts debug image refresh lock # <-- Added lock

all: serve

# --- NEW TARGET ---
# Manual target to update Gemfile.lock using the base Docker image.
# Run this after changing Gemfile, then commit the updated Gemfile.lock.
lock:
	@echo "Updating Gemfile.lock using Docker ($(BASE_RUBY_IMAGE) with Bundler $(BUNDLER_VERSION))..."
	@# Run a temporary container using the base Ruby image
	@# Mount the current directory to /workspace
	@# Set working directory to /workspace
	@# Inside the container: install the correct bundler version, then run bundle install
	@docker run --rm \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(BASE_RUBY_IMAGE) \
		/bin/bash -c "echo 'Installing Bundler ${BUNDLER_VERSION}...' && \
		              gem install bundler -v $(BUNDLER_VERSION) --no-document && \
		              echo 'Running bundle install...' && \
		              bundle install"
	@# Check the exit status of the docker command
	@if [ $$? -ne 0 ]; then \
		echo "Error: bundle install failed inside Docker." && exit 1; \
	fi
	@echo "Gemfile.lock updated successfully. Please commit Gemfile and Gemfile.lock."
# --- END NEW TARGET ---

# Build the Docker image using '.' as build context.
# Depends on Gemfile.lock existing (created/updated via 'make lock').
# Dockerfile uses 'bundle config set deployment' based on the copied Gemfile.lock.
image: Dockerfile Gemfile Gemfile.lock # <-- Depends on Gemfile.lock
	@echo "Building Docker image $(IMAGE) using '.' as context..."
	@if [ ! -f .dockerignore ]; then \
		echo "Warning: .dockerignore file not found. Build context might be large or include unwanted files."; \
	fi
	@# Pass bundler version as build argument
	@docker build --build-arg BUNDLER_VERSION=$(BUNDLER_VERSION) . -f Dockerfile -t $(IMAGE)

# Rebuild the Docker image without cache.
refresh: Dockerfile Gemfile Gemfile.lock # <-- Depends on Gemfile.lock
	@echo "Rebuilding Docker image $(IMAGE) with --no-cache..."
	@if [ ! -f .dockerignore ]; then \
		echo "Warning: .dockerignore file not found. Build context might be large or include unwanted files."; \
	fi
	@# Pass bundler version as build argument
	@docker build --build-arg BUNDLER_VERSION=$(BUNDLER_VERSION) --no-cache . -f Dockerfile -t $(IMAGE)

# Clean out _site and other caches. Requires the image to exist.
clean: image
	@echo "Cleaning Jekyll build artifacts..."
	@docker run --rm -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll clean

# Serve the site. Depends on image and clean.
serve: image clean
	@echo "Serving site at http://localhost:4000 (or http://<docker_ip>:4000)..."
	@docker run --rm -p 4000:4000 -p 35729:35729 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll serve --host 0.0.0.0 --watch --incremental --livereload

# Serve the site with drafts. Depends on image and clean.
drafts: image clean
	@echo "Serving site with drafts at http://localhost:4000 (or http://<docker_ip>:4000)..."
	@docker run --rm -p 4000:4000 -p 35729:35729 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll serve --host 0.0.0.0 --drafts --future --watch --incremental --livereload

# Interactive session within the image. Depends on image existing.
debug: image
	@echo "Starting interactive debug session in container..."
	@docker run -it --rm -p 4000:4000 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) /bin/bash

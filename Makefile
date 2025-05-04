# Makefile
IMAGE := jekyll-image-agude
MOUNT := /workspace

# Define Ruby version by reading .ruby-version file, ignoring comments/whitespace
RUBY_VERSION := $(shell grep -v '^\#' .ruby-version)

# Define Bundler version directly in the Makefile
BUNDLER_VERSION := 2.6.8

# Define base image using the determined Ruby version
BASE_RUBY_IMAGE := ruby:$(RUBY_VERSION)

# Use find to locate all test_*.rb files within the _tests/plugins/ directory
TEST_FILES := $(shell find _tests/plugins/ -type f -name 'test_*.rb')

.PHONY: all clean serve drafts debug image refresh lock test

all: serve

# Manual target to update Gemfile.lock using the correct base Docker image and Bundler version.
# Uses 'bundle lock --update --normalize-platforms' to regenerate the lockfile.
lock: .ruby-version # Dependency on .ruby-version
	@echo "Updating and normalizing Gemfile.lock using Docker ($(BASE_RUBY_IMAGE) with Bundler $(BUNDLER_VERSION))..."
	@echo "Running 'bundle lock --update --normalize-platforms' inside container..." # Updated echo
	@docker run --rm \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(BASE_RUBY_IMAGE) \
		/bin/bash -c "echo 'Installing Bundler $(BUNDLER_VERSION)...' && \
		              gem install bundler -v $(BUNDLER_VERSION) --no-document && \
		              echo 'Running bundle lock --update --normalize-platforms...' && \
		              bundle lock --update --normalize-platforms" # <-- CORRECTED COMMAND
	@if [ $$? -ne 0 ]; then \
		echo "Error: bundle lock failed inside Docker." && exit 1; \
	fi
	@echo "Gemfile.lock updated and normalized successfully. Please commit Gemfile, Gemfile.lock, and .ruby-version."

# Build the Docker image using '.' as build context.
# Pass the Ruby and Bundler versions as build arguments.
image: Dockerfile Gemfile Gemfile.lock .ruby-version # Removed .bundler-version dependency
	@echo "Building Docker image $(IMAGE) using Ruby $(RUBY_VERSION) and Bundler $(BUNDLER_VERSION)..."
	@if [ ! -f .dockerignore ]; then \
		echo "Warning: .dockerignore file not found. Build context might be large or include unwanted files."; \
	fi
	@docker build \
	    --build-arg RUBY_VERSION=$(RUBY_VERSION) \
	    --build-arg BUNDLER_VERSION=$(BUNDLER_VERSION) \
	    . -f Dockerfile -t $(IMAGE)

# Rebuild the Docker image without cache.
refresh: Dockerfile Gemfile Gemfile.lock .ruby-version # Removed .bundler-version dependency
	@echo "Rebuilding Docker image $(IMAGE) with --no-cache using Ruby $(RUBY_VERSION) and Bundler $(BUNDLER_VERSION)..."
	@if [ ! -f .dockerignore ]; then \
		echo "Warning: .dockerignore file not found. Build context might be large or include unwanted files."; \
	fi
	@docker build \
	    --build-arg RUBY_VERSION=$(RUBY_VERSION) \
	    --build-arg BUNDLER_VERSION=$(BUNDLER_VERSION) \
	    --no-cache . -f Dockerfile -t $(IMAGE)

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

# Run Minitest tests located in _tests/ inside the Docker container.
test: image # Depends on the Docker image being built/up-to-date
	@echo "Running tests inside Docker container..."
	@# Check if any test files were found
	@if [ -z "$(TEST_FILES)" ]; then \
		echo "Warning: No test files found matching '_tests/**/test_*.rb'."; \
		exit 0; \
	fi
	@echo "Found test files: $(TEST_FILES)"
	@# Run ruby directly, adding _plugins and _tests to the load path (-I)
	@# Pass the list of found test files to the ruby command
	@docker run --rm \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec ruby -I _plugins $(TEST_FILES)
	@if [ $$? -ne 0 ]; then \
		echo "Error: Tests failed." && exit 1; \
	fi
	@echo "Tests finished successfully."

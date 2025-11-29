# Makefile
IMAGE := jekyll-image-agude
MOUNT := /workspace

# Define Ruby version by reading .ruby-version file, ignoring comments/whitespace
RUBY_VERSION := $(shell grep -v '^\#' .ruby-version)

# Define Bundler version directly in the Makefile
BUNDLER_VERSION := 2.6.8

# Define base image using the determined Ruby version
BASE_RUBY_IMAGE := ruby:$(RUBY_VERSION)

# Get the current user's UID and GID to run Docker commands as the host user.
# This prevents Docker from creating files (e.g., _site, coverage) as root.
# We also set HOME=/tmp to give the user a writable home directory inside the
# container, which prevents certain permission errors with Jekyll and Bundler.
USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)
DOCKER_RUN_OPTS := --user $(USER_ID):$(GROUP_ID) -e HOME=/tmp

# Allow overriding the test file/pattern via command line.
# Defaults to finding all 'test_*.rb' files in the '_tests' directory,
# excluding 'test_helper.rb' itself.
# Example usage:
#   make test
#   make test TEST=_tests/plugins/test_link_cache_generator.rb
#   make test TEST=$$(find _tests/plugins/utils -name 'test_*.rb')
TEST ?= $(shell find _tests -type f -name 'test_*.rb' -not -name 'test_helper.rb')

.PHONY: all build check check-strict clean clean-coverage coverage coverage-summary debug drafts format-all image install-hook lint lock profile refresh serve test

all: serve

# Manual target to update Gemfile.lock using the correct base Docker image and Bundler version.
# Uses 'bundle lock --update --normalize-platforms' to regenerate the lockfile.
lock: .ruby-version # Dependency on .ruby-version
	@echo "Updating and normalizing Gemfile.lock using Docker ($(BASE_RUBY_IMAGE) with Bundler $(BUNDLER_VERSION))..."
	@echo "Running 'bundle lock --update --normalize-platforms' inside container..." # Updated echo
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
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
clean: image clean-coverage
	@echo "Cleaning Jekyll build artifacts..."
	@docker run --rm $(DOCKER_RUN_OPTS) -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll clean

# Clean the coverage report directory.
clean-coverage:
	@echo "Cleaning coverage report..."
	@rm -rf coverage

# Build the site for production. Depends on image and clean.
build: image clean
	@echo "Building site for production..."
	@docker run --rm $(DOCKER_RUN_OPTS) -v $(PWD):$(MOUNT) -w $(MOUNT) -e JEKYLL_ENV=production $(IMAGE) bundle exec jekyll build

# Profile the site build. Depends on image and clean.
profile: image clean
	@echo "Profiling Jekyll build..."
	@echo "Output will be in '_site' and Liquid profiles in '_profile/'."
	@docker run --rm $(DOCKER_RUN_OPTS) -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll build --profile

# Serves the site for local development, with live reloading.
# This target contains the solution to the '0.0.0.0' URL issue in browsers.
serve: image clean
	@echo "Serving site at http://localhost:4000..."
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-p 4000:4000 \
		-p 35729:35729 \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		-e JEKYLL_ENV=docker \
		$(IMAGE) \
		bundle exec jekyll serve --config _config.yml,_config_docker.yml --watch --incremental --livereload
#
# WHY THIS COMMAND IS STRUCTURED THIS WAY:
#
# We DO NOT set `--host 0.0.0.0` here on the command line. The reason is
# critical: the `--host` flag has the highest precedence and forces Jekyll to
# automatically set `site.url` to "http://0.0.0.0:4000", which completely
# ignores any `url` setting from our config files. Modern browsers block
# 0.0.0.0 for security, and so this would prevent local builds from rendering
# correctly.
#
# Instead, we delegate all configuration to the files loaded via `--config`.
# The `_config_docker.yml` file is responsible for two things:
#   1. `host: 0.0.0.0`: Makes the server accessible to Docker.
#   2. `url: ""`:       Generates browser-friendly relative links.
#
# The `-e JEKYLL_ENV=docker` flag helps ensure this file-based configuration is
# properly loaded and respected by the Jekyll `serve` command.

# Serve the site with drafts. Depends on image and clean.
# Uses same logic to avoid 0.0.0.0 bug as serve
drafts: image clean
	@echo "Serving site with drafts at http://localhost:4000..."
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-p 4000:4000 \
		-p 35729:35729 \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		-e JEKYLL_ENV=docker \
		$(IMAGE) \
		bundle exec jekyll serve --config _config.yml,_config_docker.yml --drafts --future --watch --incremental --livereload

# Interactive session within the image. Depends on image existing.
debug: image
	@echo "Starting interactive debug session in container..."
	@docker run -it --rm $(DOCKER_RUN_OPTS) -p 4000:4000 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) /bin/bash

# Run Minitest tests located in _tests/ inside the Docker container.
test: image # Depends on the Docker image being built/up-to-date
	@echo "Running tests..."
	@# Check if the TEST variable is empty.
	@if [ -z "$(TEST)" ]; then \
		echo "Warning: No test files found. Check the TEST variable or your file structure."; \
		exit 0; \
	fi
	@echo "Found test files:"
	@echo "$(TEST)" | tr ' ' '\n'
	@echo "---"
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec ruby -I _plugins -I _tests \
		  -e "require 'test_helper'; ARGV.each { |f| load f }" \
		  $(TEST)
	@if [ $$? -ne 0 ]; then \
		echo "Error: Tests failed." && exit 1; \
	fi
	@echo "Tests finished successfully."

# Run tests and generate a code coverage report.
coverage: image clean-coverage
	@echo "Running tests and generating coverage report..."
	@# The test command is the same as 'test', but SimpleCov (enabled in test_helper)
	@# will automatically generate the report in the 'coverage/' directory.
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec ruby -I _plugins -I _tests \
		  -e "require 'test_helper'; ARGV.each { |f| load f }" \
		  $(TEST)
	@echo "---"
	@echo "Coverage report generated in 'coverage/index.html'."
	@echo "To view on macOS, run: open coverage/index.html"
	@echo "To view on Linux, run: xdg-open coverage/index.html"

# Run coverage and generate a machine-readable summary for LLM agents.
coverage-summary: image clean-coverage coverage
	@echo "Running tests and generating coverage report..."
	@# First, run the tests with coverage enabled to generate coverage/coverage.json.
	@# We pipe stdout to /dev/null to hide the minitest output and keep the summary clean.
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec ruby -I _plugins -I _tests \
		  -e "require 'test_helper'; ARGV.each { |f| load f }" \
		  $(TEST) > /dev/null
	@echo "---"
	@echo "Generating machine-readable coverage summary..."
	@# Then, run the Rake task to parse the JSON and create the summary file.
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec rake coverage:summary
	@echo "---"
	@echo "Displaying summary from coverage/coverage_summary.txt:"
	@cat coverage/coverage_summary.txt

# Run RuboCop linter.
lint: image
	@echo "Running linter..."
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec rubocop

# Build the site and check for broken links/HTML issues.
check: build
	@echo "Checking generated site for broken links and HTML issues..."
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec ruby _bin/check_links.rb

# Check all documents for strict Liquid compliance.
check-strict: image
	@echo "Checking all documents for strict Liquid compliance..."
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec ruby _bin/check_strict.rb

# Install the custom pre-commit hook that runs RuboCop inside Docker.
# This target must be run on the HOST machine.
install-hook: image _bin/pre-commit.sh
	@echo "Installing custom Docker-based pre-commit hook..."
	@mkdir -p .git/hooks
	@cp _bin/pre-commit.sh .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed at .git/hooks/pre-commit."
	@echo "It will run 'rubocop --autocorrect' on staged Ruby files inside the Docker image."

# Run RuboCop --autocorrect on all Ruby files to establish a clean formatting baseline.
# This target modifies files on the host via the volume mount.
format-all: image
	@echo "Running RuboCop --autocorrect on ALL Ruby files to establish a clean baseline..."
	@# Run RuboCop, ignore its non-zero exit code (1 or 123) with '|| true' to prevent 'make' from failing.
	@docker run --rm \
		$(DOCKER_RUN_OPTS) \
		-v $(PWD):$(MOUNT) \
		-w $(MOUNT) \
		$(IMAGE) \
		bundle exec rubocop --autocorrect --format quiet > /dev/null 2>&1 || true
	@echo "All Ruby files have been safely auto-corrected. Please review and commit changes."

# Dockerfile

# Define build argument for Ruby version, default matches .ruby-version
ARG RUBY_VERSION=3.2
# Use the specific version provided by the build argument
FROM ruby:${RUBY_VERSION}

# Avoid prompt for time zone info.
ENV DEBIAN_FRONTEND=noninteractive

# Watch out for locale encoding weirdness due to no time zone.
ARG US_UTF=en_US.UTF-8
ENV LC_ALL=C.UTF-8
ENV LANG=$US_UTF
ENV LANGUAGE=$US_UTF

# Install required bundler version for consistency
# BUNDLER is passed in, this is just the default
ARG BUNDLER_VERSION=2.6.8
RUN gem install bundler -v ${BUNDLER_VERSION} --no-document

# Copy .ruby-version into the image (good practice)
COPY .ruby-version .ruby-version

# Set working directory
WORKDIR /workspace

# Copy Gemfile and the committed Gemfile.lock first.
COPY Gemfile Gemfile.lock ./

# Configure Bundler to respect the lockfile strictly (frozen)
# We use --global so settings persist and paths aren't masked by the volume mount.
RUN bundle config set --global frozen 1

# Install gems based *strictly* on the committed Gemfile.lock
# These will now go to the system path (e.g. /usr/local/bundle)
RUN bundle install --jobs 4

# No COPY . . command.
# We do not copy source files. We mount them via Makefile at runtime.
# This prevents rebuilding the image layer every time you change a test or post.

# No CMD needed, will be provided by docker run

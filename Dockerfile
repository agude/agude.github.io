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

# Configure Bundler for deployment mode (replaces --deployment flag)
RUN bundle config set --local deployment 'true'

# Install gems based *strictly* on the committed Gemfile.lock
RUN bundle install --jobs 4

# Now copy the rest of the application code.
COPY . .

# No CMD needed, will be provided by docker run

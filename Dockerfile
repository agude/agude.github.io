# Dockerfile
FROM ruby:3

# Avoid prompt for time zone info.
ENV DEBIAN_FRONTEND=noninteractive

# Watch out for locale encoding weirdness due to no time zone.
ARG US_UTF=en_US.UTF-8
ENV LC_ALL=C.UTF-8
ENV LANG=$US_UTF
ENV LANGUAGE=$US_UTF

# Install required bundler version for consistency
ARG BUNDLER_VERSION=2.6.8
RUN gem install bundler -v ${BUNDLER_VERSION} --no-document # <-- Uses ARG

# Set working directory
WORKDIR /workspace

# Copy Gemfile and the committed Gemfile.lock first.
COPY Gemfile Gemfile.lock ./

# Configure Bundler for deployment mode (replaces --deployment flag)
# This ensures gems are installed based strictly on Gemfile.lock
RUN bundle config set --local deployment 'true'

# Install gems based *strictly* on the committed Gemfile.lock because
# deployment mode is configured above.
# Installs gems globally in the image's default gem path.
# This will FAIL the build if Gemfile.lock is inconsistent with Gemfile.
RUN bundle install --jobs 4

# Now copy the rest of the application code.
# Files listed in .dockerignore will be excluded.
COPY . .

# No CMD needed, will be provided by docker run

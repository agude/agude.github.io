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
RUN gem install bundler -v 2.4.22 --no-document

# Set working directory
WORKDIR /workspace

# Copy *only* the Gemfile first to leverage Docker cache
# Gemfile.lock from the host should be excluded via .dockerignore
# so the build always reflects the Gemfile.
COPY Gemfile Gemfile

# REMOVED: Configure Bundler local path - we want global gems now
# RUN bundle config set --local path 'vendor/bundle'

# Install gems based on Gemfile.
# This will install gems globally in the image's default gem path
# and generate Gemfile.lock inside the image build context (/workspace/Gemfile.lock).
RUN bundle install --jobs 4

# Now copy the rest of the application code.
# This includes _config.yml, posts, includes, layouts, assets, etc.
# Files listed in .dockerignore will be excluded.
COPY . .

# No CMD needed, will be provided by docker run

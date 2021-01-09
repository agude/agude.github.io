FROM ubuntu:20.04

# Avoid prompt for time zone info.
ENV DEBIAN_FRONTEND=noninteractive

# Watch out for locale encoding weirdness due to no time zone.
ARG US_UTF=en_US.UTF-8
ENV LC_ALL=C.UTF-8
ENV LANG=$US_UTF
ENV LANGUAGE=$US_UTF

# Install requirements for bundle
RUN apt-get -y update \
    && apt-get install -y \
        build-essential \
        git \
        ruby \
        ruby-dev \
        zlib1g-dev

# Install required gems via bundle
ADD Gemfile .
RUN gem install bundler \
    && gem update --system \
    && bundle install \
    && bundle update

CMD ["/bin/bash"]

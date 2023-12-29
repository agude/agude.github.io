FROM ruby:2

# Avoid prompt for time zone info.
ENV DEBIAN_FRONTEND=noninteractive

# Watch out for locale encoding weirdness due to no time zone.
ARG US_UTF=en_US.UTF-8
ENV LC_ALL=C.UTF-8
ENV LANG=$US_UTF
ENV LANGUAGE=$US_UTF

# Install required gems via bundle
RUN gem install bundler -v 2.4.22

ENV BUNDLE_GEMFILE=/tmp/Gemfile
COPY Gemfile $BUNDLE_GEMFILE

RUN bundle install -j 4

CMD ["/bin/bash"]

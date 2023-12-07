# syntax=docker/dockerfile:1

# ---- build -----------------------------------------------------------------
# Compiles native gem extensions and precompiles assets. None of the build
# toolchain survives into the runtime image.
ARG RUBY_VERSION=3.2.8
FROM ruby:${RUBY_VERSION}-slim AS build

ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_ENV=production

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# SECRET_KEY_BASE_DUMMY lets the asset pipeline boot without the real key,
# which is supplied at run time.
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# ---- runtime ---------------------------------------------------------------
FROM ruby:${RUBY_VERSION}-slim

ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    PORT=3000

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libpq5 postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run as an unprivileged user; only the directories Rails writes to are owned
# by it.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp/pids && \
    chown -R rails:rails log tmp
USER rails:rails

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl --fail --silent http://localhost:${PORT}/up || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

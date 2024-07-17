FROM ghcr.io/flavorjones/truffleruby:latest-slim

RUN apt update && apt -y install build-essential git bash musl musl-dev gcc
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN git clone --recurse-submodules https://github.com/spaced-out-thoughts-dev-foundation/bean-stock.git

COPY subdir_setup.sh /app/subdir_setup.sh
RUN chmod +x /app/subdir_setup.sh

WORKDIR /usr/src/app/bean-stock/frontend
RUN /app/subdir_setup.sh $(pwd)

WORKDIR /usr/src/app/bean-stock/backend
RUN /app/subdir_setup.sh $(pwd)

WORKDIR /usr/src/app

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]

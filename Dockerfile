FROM ruby:3.2-alpine

RUN apk add --no-cache build-base git bash musl musl-dev gcc
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN git clone --recurse-submodules https://github.com/spaced-out-thoughts-dev-foundation/bean-stock.git

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]

FROM ruby:2.3

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app

RUN gem install bundler

RUN bundle install


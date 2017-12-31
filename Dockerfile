FROM ruby:2.5.0

WORKDIR /tmp
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN gem install bundler
RUN bundle install -j4

ADD . /usr/src/app
WORKDIR /usr/src/app
RUN mkdir ./tmp

CMD bundle exec sidekiq -t 45 -q photos -q api -c 12 -r ./mm_crawler.rb

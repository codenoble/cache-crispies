FROM ruby:3.4
WORKDIR /srv/cache_crispies/
COPY . /srv/cache_crispies/
RUN gem install bundler
RUN bundle install
RUN bundle exec appraisal install

CMD ["bundle", "exec", "appraisal", "rspec"]

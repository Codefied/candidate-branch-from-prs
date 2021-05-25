FROM ruby:2.7-alpine

COPY Gemfile Gemfile.lock select_prs.rb /
RUN bundle install

ENTRYPOINT ["ruby", "/select_prs.rb"]

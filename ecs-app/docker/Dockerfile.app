FROM ruby:2.3.0
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev && \
    apt-get install -y nginx && \
    mkdir -p /myapp/tmp/pids /myapp/logs
WORKDIR /myapp
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock
RUN bundle install
ADD . /myapp
RUN chmod 755 run-app.sh && mkdir log && mkdir -p tmp/pids
#
CMD ["sh", "run-app.sh"]

* Installation
- Ruby 2.5, gem 2.7
- gem ruby-kafka

ruby --version
ruby 2.5.0p0 (2017-12-25 revision 61468) [x86_64-linux-gnu]

gem --version
2.7.3

- Reference:
  + install Ruby at https://gorails.com/setup/ubuntu/16.04
  + install gem ruby-kafka at https://github.com/zendesk/ruby-kafka 

* Configuration
The directory containing content yml file at SanityApp\src\resources\demo.yml

Run:
- unset http_proxy
- unset https_proxy
- unset HTTP_PROXY
- unset HTTPS_PROXY

~/RubymineProjects/SanityApp/src/main$ ruby sanityapp.rb


** docker start or stop fnms container syncope, opentsdb, mariadb ...
~/RubymineProjects/SanityApp/src/main$ ruby queryFailureLogs.rb  => check failure logs in ES


** More
DateTime.now - time
time = (1.0) #1day
time = (1.0/24) #1hour
time = (1.0/(24*60)) #1minute
time = (1.0/(24*60*60)) #1second

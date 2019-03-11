source 'https://rubygems.org'
ruby '2.3.3'

gem 'rack'
gem 'rakeup'
gem 'puma'
gem 'rack-cors'

gem 'grape'
gem 'grape_logging'
gem 'grape-entity'
gem 'grape-swagger', '<0.26' # FIXME wait for ruby 2.2
gem 'grape-swagger-entity'

gem 'i18n'
gem 'rack-contrib'
gem 'rest-client'
gem 'addressable'
gem 'border_patrol'
gem 'activesupport', '<5' # Wait for Ruby version >= 2.2.2

group :test do
  gem 'rack-test'
  gem 'minitest'
  gem 'minitest-focus'
  gem 'minitest-reporters'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'byebug'
end

gem 'dotenv'
gem 'polylines'

group :production do
  gem 'redis', '< 4' # Waiting Ruby 2.2 (dependency from resque)
  gem 'redis-store', '~> 1.4.1' # Ensure redis-store dependency is at least 1.4.1 for CVE-2017-1000248 correction
  gem 'redis-activesupport'
end

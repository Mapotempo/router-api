source 'https://rubygems.org'
ruby '~> 2.5'

gem 'rack'
gem 'rake'
gem 'puma'
gem 'rack-cors'
gem 'rack-server-pages', '~> 0.1.0'

gem 'grape'
gem 'grape_logging'
gem 'grape-entity'
gem 'grape-swagger'
gem 'grape-swagger-entity'

gem 'i18n'
gem 'rack-contrib'
gem 'rest-client'
gem 'addressable'
gem 'border_patrol'
gem 'activesupport'
gem 'actionpack'

group :test do
  gem 'fakeredis'
  gem 'minitest'
  gem 'minitest-focus'
  gem 'minitest-reporters'
  gem 'rack-test'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'byebug'
end

gem 'dotenv'
gem 'polylines'

group :production do
  gem 'redis'
  gem 'redis-store', '~> 1.4.1' # Ensure redis-store dependency is at least 1.4.1 for CVE-2017-1000248 correction
  gem 'redis-activesupport'
end

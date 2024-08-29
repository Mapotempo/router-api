source 'https://rubygems.org'
ruby '>= 3'

gem 'rack'
gem 'rake'
gem 'puma'
gem 'rack-cors'
gem 'rack-server-pages'

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
  gem 'mapotempo_rubocop', :git => 'https://github.com/Mapotempo/mapotempo_rubocop.git'
end

gem 'dotenv'
gem 'flexible_polyline'
gem 'polylines'

group :development, :production do
  gem 'redis', '< 5' # redis-store is buggy with redis 5 https://github.com/redis-store/redis-store/issues/358
end

group :production do
  gem 'redis-store'
  gem 'redis-activesupport'
end

# Copyright © Mapotempo, 2015
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
ENV['APP_ENV'] ||= 'development'
Bundler.require
require File.expand_path('../config/environments/' + ENV['APP_ENV'], __FILE__)
Dir[File.dirname(__FILE__) + '/config/initializers/*.rb'].each {|file| require file }
require './router_wrapper'
require './api/root'
require 'rack/cors'
require 'rack/contrib/locale'
require 'rack/contrib/try_static'
require 'action_dispatch/middleware/remote_ip.rb'

use Rack::ServerPages do |config|
  config.view_path = 'public'
end

run Rack::ServerPages::NotFound

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :any
  end
end

use Rack::Locale
#\ -p 4899
run Api::Root

# Serve files from the public directory
use Rack::TryStatic,
  root: 'public',
  urls: %w[/],
  try: ['.html', 'route.html', '/route.html', 'isoline.html', '/isoline.html']

use ActionDispatch::RemoteIp

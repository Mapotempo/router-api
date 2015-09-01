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
require 'grape'
require 'grape-swagger'
require 'grape-entity'
require 'grape_logging'

require './api/v01/v01'

module Api
  class Root < Grape::API
    format :json
    content_type :json, 'application/json; charset=UTF-8'

    default_format :json

    mount V01::V01

    documentation_class = add_swagger_documentation base_path: (lambda do |request| "#{request.scheme}://#{request.host}:#{request.port}" end), hide_documentation_path: true, info: {
      title: ::RouterWrapper::config[:product_title],
      description: 'API access require an api_key.',
      contact: ::RouterWrapper::config[:product_contact]
    }

    logger.formatter = GrapeLogging::Formatters::Default.new
    use GrapeLogging::Middleware::RequestLogger, { logger: logger }

    desc 'Ping hook. Responds by "pong".'
    get '/ping' do
      'pong'
    end
  end
end

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
require 'polylines'

require './api/geojson_formatter'
require './api/v01/entities/route_result'
require './wrappers/wrapper'
require './router_wrapper'

module Api
  module V01
    class Route < Grape::API
      content_type :json, 'application/json; charset=UTF-8'
      content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
      formatter :geojson, GeoJsonFormatter
      # content_type :gpx, 'application/gpx+xml; charset=UTF-8'
      # formatter :gpx, GpxFormatter
      default_format :json
      version '0.1', using: :path

      rescue_from :all do |error|
        message = {error: error.class.name, detail: error.message}
        if ['development'].include?(ENV['APP_ENV'])
          message[:trace] = error.backtrace
          STDERR.puts error.message
          STDERR.puts error.backtrace
        end
        error!(message, 500)
      end

      resource :route do
        desc 'Route via two points or more', {
          nickname: 'route',
          entity: RouteResult
        }
        params {
          optional :mode, type: String, values: RouterWrapper.config[:services][:route].keys.collect(&:to_s), default: RouterWrapper.config[:services][:route_default], desc: 'Transportation mode.'
          optional :geometry, type: Boolean, default: true, desc: 'Return the route trace geometry.'
          optional :departure, type: Date, desc: 'Departure date time.'
          optional :arrival, type: Date, desc: 'Arrival date time.'
          optional :lang, type: String, default: :en
          requires :loc, type: String, desc: 'List of Latitudes and longitudes separated with comma, e.g. lat1,lng1,lat2,lng2...'
        }
        get do
          params[:loc] = params[:loc].split(',').collect{ |f| Float(f) }.each_slice(2).to_a
          params[:loc].size >= 2 || error!('At least two couples of lat/lng are needed.', 400)
          params[:loc][-1].size == 2 || error!('Couples of lat/lng are needed.', 400)

          begin
            results = RouterWrapper::wrapper_route(params)
            results[:router][:version] = 'draft'
            results[:features].each{ |feature|
              if @env['rack.routing_args'][:format] == 'geojson'
                if feature[:geometry][:polylines]
                  feature[:geometry][:coordinates] = Polylines::Decoder.decode_polyline(feature[:geometry][:polylines], 1e6)
                  feature[:geometry].delete(:polylines)
                end
              elsif @env['rack.routing_args'][:format] == 'json'
                if feature[:geometry][:coordinates]
                  feature[:geometry][:polylines] = Polylines::Encoder.encode_points(feature[:geometry][:coordinates].collect(&:reverse), 1e6)
                  feature[:geometry].delete(:coordinates)
                end
              end
            }
            present results, with: RouteResult
          rescue RouterWrapper::OutOfSupportedAreaError => e
            error!(e.message, 400)
          rescue Wrappers::UnreachablePointError => e
            error!(e.message, 400)
          end
        end
      end
    end
  end
end

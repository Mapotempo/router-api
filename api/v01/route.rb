# Copyright © Mapotempo, 2015-2016
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
require 'polylines'

require './api/v01/api_base'
require './api/geojson_formatter'
require './api/v01/entities/route_result'
require './api/v01/entities/routes_result'
require './api/v01/entities/status'
require './wrappers/wrapper'
require './router_wrapper'

module Api
  module V01
    class Route < APIBase
      content_type :json, 'application/json; charset=UTF-8'
      content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
      content_type :xml, 'application/xml'
      formatter :geojson, GeoJsonFormatter
      # content_type :gpx, 'application/gpx+xml; charset=UTF-8'
      # formatter :gpx, GpxFormatter
      default_format :json
      version '0.1', using: :path

      resource :route do
        desc 'Route via two points or more', {
          detail: 'Find the route between two or more points depending of transportation mode, dimension, etc... Area/speed_multiplicator_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time, see capability operation for informations).',
          nickname: 'route',
          success: RouteResult,
          failures: [
            {code: 400, model: Status}
          ],
          produces: [
            'application/json; charset=UTF-8',
            'application/vnd.geo+json; charset=UTF-8',
            'application/xml',
          ]
        }
        params {
          optional :mode, type: Symbol, desc: 'Transportation mode (see capability operation for available modes).'
          optional :dimension, type: Symbol, values: [:time, :distance], default: :time, desc: 'Compute fastest or shortest (default on time.)'
          optional :geometry, type: Boolean, default: true, desc: 'Return the route trace geometry.'
          optional :departure, type: Date, desc: 'Departure date time (currently not used).'
          optional :arrival, type: Date, desc: 'Arrival date time (currently not used).'
          optional :speed_multiplicator, type: Float, desc: 'Speed multiplicator (default: 1), not available on all transport modes.'
          optional :area, type: Array, coerce_with: ->(c) { c.split(';').collect{ |b| b.split(',').collect{ |f| Float(f) }}}, desc: 'List of latitudes and longitudes separated with commas. Areas separated with semicolons (only available for truck mode at this time).'
          optional :speed_multiplicator_area, type: Array, coerce_with: ->(c) { c.split(';').collect{ |f| Float(f) }}, desc: 'Speed multiplicator per area, 0 avoid area. Areas separated with semicolons (only available for truck mode at this time).'
          optional :lang, type: String, default: :en
          requires :loc, type: Array, coerce_with: ->(c) { c.split(',').collect{ |f| Float(f) }.each_slice(2).to_a }, desc: 'List of latitudes and longitudes separated with commas, e.g. lat1,lng1,lat2,lng2...'
        }
        get do
          params[:locs] = [params[:loc]]
          present compute_routes(params)[0], with: RouteResult
        end
      end

      params {
        optional :mode, type: Symbol, desc: 'Transportation mode (see capability operation for available modes).'
        optional :dimension, type: Symbol, values: [:time, :distance], default: :time, desc: 'Compute fastest or shortest (default on time.)'
        optional :geometry, type: Boolean, default: true, desc: 'Return the route trace geometry.'
        optional :departure, type: Date, desc: 'Departure date time.'
        optional :arrival, type: Date, desc: 'Arrival date time.'
        optional :speed_multiplicator, type: Float, desc: 'Speed multiplicator (default: 1), not available on all transport modes.'
        optional :area, type: Array, coerce_with: ->(c) { c.split(';').collect{ |b| b.split(',').collect{ |f| Float(f) }}}, desc: 'List of latitudes and longitudes separated with commas. Areas separated with semicolons (only available for truck mode at this time, see capability operation for informations).'
        optional :speed_multiplicator_area, type: Array, coerce_with: ->(c) { c.split(';').collect{ |f| Float(f) }}, desc: 'Speed multiplicator per area, 0 avoid area. Areas separated with semicolons (only available for truck mode at this time).'
        optional :lang, type: String, default: :en
        requires :locs, type: Array, coerce_with: ->(c) { c.split(';').collect{ |b| b.split(',').collect{ |f| Float(f) }.each_slice(2).to_a } }, desc: 'List of latitudes and longitudes separated with commas. Each route separated with semicolons. E.g. r1lat1,r1lng1,r1lat2,r1lng2;r2lat1,r2lng1,r2lat2,r2lng2'
      }
      resource :routes do
        desc 'Many routes, each via two points or more', {
          detail: 'Find many routes between many couples of two or more points. Area/speed_multiplicator_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time).',
          nickname: 'routes',
          success: RouteResult,
          failures: [
            {code: 400, model: Status}
          ],
          produces: [
            'application/json; charset=UTF-8',
            'application/vnd.geo+json; charset=UTF-8',
            'application/xml',
          ]
        }
        get do
          many_routes params
        end

        desc 'Many routes, each via two points or more', {
          detail: 'Find many routes between many couples of two or more points. Area/speed_multiplicator_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time).',
          nickname: 'routes_post',
          success: RouteResult,
          failures: [
            {code: 400, model: Status}
          ],
          produces: [
            'application/json; charset=UTF-8',
            'application/vnd.geo+json; charset=UTF-8',
            'application/xml',
          ]
        }
        post do
          many_routes params
          status 200
        end
      end

      helpers do
        def compute_routes(params)
          params[:mode] ||= APIBase.services(params[:api_key])[:route_default]
          if params[:area]
            params[:area].all?{ |area| area.size % 2 == 0 } || error!({detail: 'area: couples of lat/lng required.'}, 400)
            params[:area] = params[:area].collect{ |area| area.each_slice(2).to_a }
          end
          params[:locs].each_with_index{ |loc, index|
            loc.size >= 2 || error!({detail: 'locs: segment ##{index}, at least two couples of lat/lng required.'}, 400)
            loc[-1].size == 2 || error!({detail: 'locs: segment ##{index}, couples of lat/lng required.'}, 400)
          }

          routes = params[:locs].collect{ |loc|
            params[:loc] = loc
            begin
              results = RouterWrapper::wrapper_route(APIBase.services(params[:api_key]), params)
              results[:router][:version] = 'draft'
              results[:features].each{ |feature|
                if feature[:geometry]
                  if params[:format] == 'geojson'
                    if feature[:geometry][:polylines]
                      feature[:geometry][:coordinates] = Polylines::Decoder.decode_polyline(feature[:geometry][:polylines], 1e6).collect(&:reverse)
                      feature[:geometry].delete(:polylines)
                    end
                  else
                    if feature[:geometry][:coordinates]
                      feature[:geometry][:polylines] = Polylines::Encoder.encode_points(feature[:geometry][:coordinates].collect(&:reverse), 1e6)
                      feature[:geometry].delete(:coordinates)
                    end
                  end
                end
              }
              results
            rescue => e
              if params[:locs] && params[:locs].size > 1
                {
                  type: 'Feature',
                  properties: nil,
                  geometry: nil
                }
              else
                raise e
              end
            end
          }
        end

        def many_routes(params)
          routes = compute_routes(params)
          ret = {
            type: 'FeatureCollection',
            router: routes[0][:router],
            features: routes.collect{ |r|
              if r[:type] == 'FeatureCollection'
                r[:features][0]
              else
                r
              end
            }
          }
          present ret, with: RoutesResult
        end
      end
    end
  end
end

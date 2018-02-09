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

      resource :route do
        desc 'Route via two points or more', {
          detail: 'Find the route between two or more points depending of transportation mode, dimension, etc... Area/speed_multiplier_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time, see capability operation for information).',
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
          optional :traffic, type: Boolean, default: false, desc: 'Traffic (default: false), not available on all transport modes.'
          optional :departure, type: DateTime, desc: 'Departure date time (not used by all transport modes). Traffic (if used) is taken into account at this time.'
          optional :arrival, type: DateTime, desc: 'Arrival date time (not used by all transport modes). In exclusion with departure.'
          optional :speed_multiplier, type: Float, desc: 'Speed multiplier (default: 1), not available on all transport modes.'
          optional :speed_multiplicator, type: Float, desc: 'Deprecated, use speed_multiplier instead.'
#          optional :area, type: Array[Array[Float]], coerce_with: ->(c) { c.split(';').collect{ |b| b.split(',').collect{ |f| Float(f) }}}, desc: 'List of latitudes and longitudes separated with commas. Areas separated with semicolons (only available for truck mode at this time).'
          optional :area, type: Array, coerce_with: ->(c) { c.split(/;|\|/).collect{ |b| b.split(',').collect{ |f| Float(f) }}}, desc: 'List of latitudes and longitudes separated with commas. Areas separated with pipes (only available for truck mode at this time).'
          optional :speed_multiplier_area, type: Array[Float], coerce_with: ->(c) { c.split(/;|\|/).collect{ |f| Float(f) }}, desc: 'Speed multiplier per area, 0 avoid area. Areas separated with pipes (only available for truck mode at this time).'
          optional :speed_multiplicator_area, type: Array[Float], coerce_with: ->(c) { c.split(/;|\|/).collect{ |f| Float(f) }}, desc: 'Deprecated, use speed_multiplier_area instead.'
          optional :track, type: Boolean, default: true, desc: 'Use track or not.'
          optional :motorway, type: Boolean, default: true, desc: 'Use motorway or not.'
          optional :toll, type: Boolean, default: true, desc: 'Use toll section or not.'
          optional :trailers, type: Integer, desc: 'Number of trailers.'
          optional :weight, type: Float, desc: 'Vehicle weight including trailers and shipped goods, in tons.'
          optional :weight_per_axle, type: Float, desc: 'Weight per axle in tons.'
          optional :height, type: Float, desc: 'Height in meters.'
          optional :width, type: Float, desc: 'Width in meters.'
          optional :length, type: Float, desc: 'Length in meters.'
          optional :hazardous_goods, type: Symbol, values: [:explosive, :gas, :flammable, :combustible, :organic, :poison, :radio_active, :corrosive, :poisonous_inhalation, :harmful_to_water, :other], desc: 'List of hazardous materials in the vehicle.'
          optional :max_walk_distance, type: Float, default: 750, desc: 'Max distance by walk.'
          optional :toll_costs, type: Boolean, default: false
          optional :currency, type: String, default: 'EUR', desc: 'ISO currency code.'
          optional :approach, type: Symbol, values: [:unrestricted, :curb], default: :unrestricted, desc: 'Arrive/Leave in the traffic direction.'
          optional :snap, type: Float, desc: 'Snap waypoint to junction close by snap distance.'
          optional :strict_restriction, type: Boolean, default: true, desc: 'Strict compliance with truck limitations.'
          optional :lang, type: String, default: :en
#          requires :loc, type: Array[Array[Float]], coerce_with: ->(c) { c.split(',').collect{ |f| Float(f) }.each_slice(2).to_a }, desc: 'List of latitudes and longitudes separated with commas, e.g. lat1,lng1,lat2,lng2...'
          requires :loc, type: Array[Float], coerce_with: ->(c) { c.split(',').collect{ |f| Float(f) } }, desc: 'List of latitudes and longitudes separated with commas, e.g. lat1,lng1,lat2,lng2...'
          optional :precision, type: Integer, default: 6, desc: 'Precison for encoded polyline.'
          optional :with_summed_by_area, type: Boolean, default: false, desc: 'Returns way type detail when set to true.'
        }
        get do
          params[:locs] = [params[:loc].each_slice(2).to_a]
          params[:speed_multiplier] = params[:speed_multiplicator] if !params[:speed_multiplier]
          params[:speed_multiplier_area] = params[:speed_multiplicator_area] if !params[:speed_multiplier_area]
          present compute_routes(params)[0], with: RouteResult, geometry: params[:geometry], toll_costs: params[:toll_costs], with_summed_by_area: params[:with_summed_by_area]
        end
      end

      params {
        optional :mode, type: Symbol, desc: 'Transportation mode (see capability operation for available modes).'
        optional :dimension, type: Symbol, values: [:time, :distance], default: :time, desc: 'Compute fastest or shortest (default on time.)'
        optional :geometry, type: Boolean, default: true, desc: 'Return the route trace geometry.'
        optional :traffic, type: Boolean, default: false, desc: 'Traffic (default: false), not available on all transport modes.'
        optional :departure, type: DateTime, desc: 'Departure date time (not used by all transport modes). Traffic (if used) is taken into account at this time.'
        optional :arrival, type: DateTime, desc: 'Arrival date time (not used by all transport modes). In exclusion with departure.'
        optional :speed_multiplier, type: Float, desc: 'Speed multiplier (default: 1), not available on all transport modes.'
        optional :speed_multiplicator, type: Float, desc: 'Deprecated, use speed_multiplier instead.'
#        optional :area, type: Array[Array[Float]], coerce_with: ->(c) { c.split(';').collect{ |b| b.split(',').collect{ |f| Float(f) }}}, desc: 'List of latitudes and longitudes separated with commas. Areas separated with semicolons (only available for truck mode at this time, see capability operation for informations).'
        optional :area, type: Array, coerce_with: ->(c) { c.split(/;|\|/).collect{ |b| b.split(',').collect{ |f| Float(f) }}}, desc: 'List of latitudes and longitudes separated with commas. Areas separated with pipes (only available for truck mode at this time, see capability operation for informations).'
        optional :speed_multiplier_area, type: Array[Float], coerce_with: ->(c) { c.split(/;|\|/).collect{ |f| Float(f) }}, desc: 'Speed multiplier per area, 0 avoid area. Areas separated with pipes (only available for truck mode at this time).'
        optional :speed_multiplicator_area, type: Array[Float], coerce_with: ->(c) { c.split(/;|\|/).collect{ |f| Float(f) }}, desc: 'Deprecated, use speed_multiplier_area instead.'
        optional :track, type: Boolean, default: true, desc: 'Use track or not.'
        optional :motorway, type: Boolean, default: true, desc: 'Use motorway or not.'
        optional :toll, type: Boolean, default: true, desc: 'Use toll section or not.'
        optional :trailers, type: Integer, desc: 'Number of trailers.'
        optional :weight, type: Float, desc: 'Vehicle weight including trailers and shipped goods, in tons.'
        optional :weight_per_axle, type: Float, desc: 'Weight per axle, in tons.'
        optional :height, type: Float, desc: 'Height in meters.'
        optional :width, type: Float, desc: 'Width in meters.'
        optional :length, type: Float, desc: 'Length in meters.'
        optional :hazardous_goods, type: Symbol, values: [:explosive, :gas, :flammable, :combustible, :organic, :poison, :radio_active, :corrosive, :poisonous_inhalation, :harmful_to_water, :other], desc: 'List of hazardous materials in the vehicle.'
        optional :max_walk_distance, type: Float, default: 750, desc: 'Max distance by walk.'
        optional :toll_costs, type: Boolean, default: false
        optional :currency, type: String, default: 'EUR', desc: 'ISO currency code.'
        optional :approach, type: Symbol, values: [:unrestricted, :curb], default: :unrestricted, desc: 'Arrive/Leave in the traffic direction.'
        optional :snap, type: Float, desc: 'Snap waypoint to junction close by snap distance.'
        optional :strict_restriction, type: Boolean, default: true, desc: 'Strict compliance with truck limitations.'
        optional :lang, type: String, default: :en
#        requires :locs, type: Array[Array[Array[Float]]], coerce_with: ->(c) { c.split(';').collect{ |b| b.split(',').collect{ |f| Float(f) }.each_slice(2).to_a } }, desc: 'List of latitudes and longitudes separated with commas. Each route separated with semicolons. E.g. r1lat1,r1lng1,r1lat2,r1lng2;r2lat1,r2lng1,r2lat2,r2lng2'
        requires :locs, type: Array[String], coerce_with: ->(c) { c.split(/;|\|/) }, desc: 'List of latitudes and longitudes separated with commas. Each route separated by pipes. E.g. r1lat1,r1lng1,r1lat2,r1lng2|r2lat1,r2lng1,r2lat2,r2lng2'
        optional :precision, type: Integer, default: 6, desc: 'Precison for encoded polyline.'
      }
      resource :routes do
        desc 'Many routes, each via two points or more', {
          detail: 'Find many routes between many couples of two or more points. Area/speed_multiplier_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time).',
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
          params[:locs] = params[:locs].collect{ |b| b.split(',').collect{ |f| Float(f) }.each_slice(2).to_a }
          params[:speed_multiplier] = params[:speed_multiplicator] if !params[:speed_multiplier]
          params[:speed_multiplier_area] = params[:speed_multiplicator_area] if !params[:speed_multiplier_area] || params[:speed_multiplier_area].size == 0
          many_routes params
        end

        desc 'Many routes, each via two points or more', {
          detail: 'Find many routes between many couples of two or more points. Area/speed_multiplier_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time).',
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
          params[:locs] = params[:locs].collect{ |b| b.split(',').collect{ |f| Float(f) }.each_slice(2).to_a }
          params[:speed_multiplier] = params[:speed_multiplicator] if !params[:speed_multiplier]
          params[:speed_multiplier_area] = params[:speed_multiplicator_area] if !params[:speed_multiplier_area] || params[:speed_multiplier_area].size == 0
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
            loc.size >= 2 || error!({detail: "locs: segment ##{index}, at least two couples of lat/lng required."}, 400)
            loc[-1].size == 2 || error!({detail: "locs: segment ##{index}, couples of lat/lng required."}, 400)
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
                      feature[:geometry][:coordinates] = Polylines::Decoder.decode_polyline(feature[:geometry][:polylines], 10**params[:precision]).collect(&:reverse)
                      feature[:geometry].delete(:polylines)
                    end
                  else
                    if feature[:geometry][:coordinates]
                      feature[:geometry][:polylines] = Polylines::Encoder.encode_points(feature[:geometry][:coordinates].collect(&:reverse), 10**params[:precision])
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
          present ret, with: RoutesResult, geometry: params[:geometry], toll_costs: params[:toll_costs]
        end
      end
    end
  end
end

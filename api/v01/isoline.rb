# Copyright © Mapotempo, 2016
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
require './api/v01/entities/isoline_result'
require './api/v01/entities/status'
require './wrappers/wrapper'
require './router_wrapper'

module Api
  module V01
    class Isoline < APIBase
      content_type :json, 'application/json; charset=UTF-8'
      content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
      content_type :xml, 'application/xml'
      formatter :geojson, GeoJsonFormatter
      # content_type :gpx, 'application/gpx+xml; charset=UTF-8'
      # formatter :gpx, GpxFormatter
      default_format :json

      params {
        optional :mode, type: Symbol, desc: 'Transportation mode (see capability operation for available modes).'
        optional :dimension, type: Symbol, values: [:time, :distance], default: :time, desc: 'Compute isochrone or isodistance (default on time.)'
        optional :departure, type: DateTime, desc: 'Departure date time (currently not used).'
        optional :speed_multiplier, type: Float, desc: 'Speed multiplier (default: 1), not available on all transport modes.'
        optional :speed_multiplicator, type: Float, desc: 'Deprecated, use speed_multiplier instead.'
#        optional :area, type: Array[Array[Float]], coerce_with: ->(c) { c.split(';').collect{ |b| b.split(',').collect{ |f| Float(f) }}}, desc: 'List of latitudes and longitudes separated with commas. Areas separated with semicolons (only available for truck mode at this time).'
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
        optional :approach, type: Symbol, values: [:unrestricted, :curb], default: :unrestricted, desc: 'Arrive/Leave in the traffic direction.'
        optional :snap, type: Float, desc: 'Snap waypoint to junction close by snap distance.'
        optional :strict_restriction, type: Boolean, default: true, desc: 'Strict compliance with truck limitations.'
        optional :lang, type: String, default: :en
        requires :loc, type: Array[Float], coerce_with: ->(c) { c.split(',').collect{ |f| Float(f) } }, desc: 'Start latitude and longitude separated with a comma, e.g. lat1,lng1.'

        requires :size, type: Integer, desc: 'Size of isoline. Time in second, distance in meters.'
      }
      resource :isoline do
        desc 'Isoline from a start point', {
          detail: 'Build isoline from a point with defined size depending of transportation mode, dimension, etc... Area/speed_multiplier_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time, see capability operation for informations).',
          nickname: 'isoline',
          success: IsolineResult,
          failure: Status.failure,
          produces: [
            'application/json; charset=UTF-8',
            'application/vnd.geo+json; charset=UTF-8',
            'application/xml',
          ]
        }
        get do
          params[:speed_multiplier] = params[:speed_multiplicator] if !params[:speed_multiplier]
          params[:speed_multiplier_area] = params[:speed_multiplicator_area] if !params[:speed_multiplier_area] || params[:speed_multiplier_area].size == 0
          isoline params
        end

        desc 'Isoline from a start point', {
          detail: 'Build isoline from a point with defined size depending of transportation mode, dimension, etc... Area/speed_multiplier_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time, see capability operation for informations).',
          nickname: 'isoline_post',
          success: IsolineResult,
          failure: Status.failure,
          produces: [
            'application/json; charset=UTF-8',
            'application/vnd.geo+json; charset=UTF-8',
            'application/xml',
          ]
        }
        post do
          params[:speed_multiplier] = params[:speed_multiplicator] if !params[:speed_multiplier]
          params[:speed_multiplier_area] = params[:speed_multiplicator_area] if !params[:speed_multiplier_area] || params[:speed_multiplier_area].size == 0
          isoline params
          status 200
        end
      end

      helpers do
        def isoline(params)
          params[:mode] ||= APIBase.services(params[:api_key])[:route_default]
          if params[:area]
            params[:area].all?{ |area| area.size % 2 == 0 } || error!({detail: 'area: couples of lat/lng are needed.'}, 400)
            params[:area] = params[:area].collect{ |area| area.each_slice(2).to_a }
          end
          params[:loc].size == 2 || error!({detail: 'Start lat/lng is needed.'}, 400)

          results = RouterWrapper::wrapper_isoline(APIBase.services(params[:api_key]), params)
          results[:router][:version] = 'draft'
          present results, with: IsolineResult, geometry: true
        end
      end
    end
  end
end

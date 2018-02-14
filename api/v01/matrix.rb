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
require './api/v01/entities/matrix_result'
require './api/v01/entities/status'
require './wrappers/wrapper'
require './router_wrapper'

module Api
  module V01
    class Matrix < APIBase
      content_type :json, 'application/json; charset=UTF-8'
      content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
      content_type :xml, 'application/xml'
      formatter :geojson, GeoJsonFormatter
      # content_type :gpx, 'application/gpx+xml; charset=UTF-8'
      # formatter :gpx, GpxFormatter
      default_format :json

      params {
        optional :mode, type: Symbol, desc: 'Transportation mode (see capability operation for available modes).'
        optional :dimension, type: Symbol, values: [:time, :time_distance, :distance, :distance_time], default: :time, desc: 'Compute fastest or shortest and the optional additional dimension (default on time.)'
        optional :traffic, type: Boolean, default: false, desc: 'Traffic (default: false), not available on all transport modes.'
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
        requires :src, type: Array[Float], coerce_with: ->(c) { c.split(',').collect{ |f| Float(f) } }, desc: 'List of sources of latitudes and longitudes separated with comma, e.g. lat1,lng1,lat2,lng2...'
        optional :dst, type: Array[Float], coerce_with: ->(c) { c.split(',').collect{ |f| Float(f) } }, desc: 'List of destination of latitudes and longitudes, if not present compute square matrix with sources points.'
      }
      resource :matrix do
        desc 'Rectangular matrix between two points set', {
          detail: 'Build time/distance matrix between several points depending of transportation mode, dimension, etc... Area/speed_multiplier_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time, see capability operation for informations).',
          nickname: 'matrix',
          success: MatrixResult,
          failure: Status.failure,
        }
        get do
          params[:speed_multiplier] = params[:speed_multiplicator] if !params[:speed_multiplier]
          params[:speed_multiplier_area] = params[:speed_multiplicator_area] if !params[:speed_multiplier_area] || params[:speed_multiplier_area].size == 0
          matrix params
        end

        desc 'Rectangular matrix between two points set', {
          detail: 'Build time/distance matrix between several points depending of transportation mode, dimension, etc... Area/speed_multiplier_area can be used to define areas where not to go or with heavy traffic (only available for truck mode at this time, see capability operation for informations).',
          nickname: 'matrix_post',
          success: MatrixResult,
          failure: Status.failure,
        }
        post do
          params[:speed_multiplier] = params[:speed_multiplicator] if !params[:speed_multiplier]
          params[:speed_multiplier_area] = params[:speed_multiplicator_area] if !params[:speed_multiplier_area] || params[:speed_multiplier_area].size == 0
          matrix params
          status 200
        end
      end

      helpers do
        def matrix(params)
          params[:mode] ||= APIBase.services(params[:api_key])[:route_default]
          if params[:area]
            params[:area].all?{ |area| area.size % 2 == 0 } || error!({detail: 'area: couples of lat/lng are needed.'}, 400)
            params[:area] = params[:area].collect{ |area| area.each_slice(2).to_a }
          end
          params[:src] = params[:src].each_slice(2).to_a
          params[:src][-1].size == 2 || error!({detail: 'Source couples of lat/lng are needed.'}, 400)

          if params.key?(:dst)
            params[:dst] = params[:dst].each_slice(2).to_a
            params[:dst][-1].size == 2 || error!({detail: 'Destination couples of lat/lng are needed.'}, 400)
          else
            params[:dst] =  params[:src]
          end

          results = RouterWrapper::wrapper_matrix(APIBase.services(params[:api_key]), params)
          results[:router][:version] = 'draft'
          present results, with: MatrixResult
        end
      end
    end
  end
end

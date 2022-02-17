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
require 'grape'
require 'grape-swagger'

module Api
  module V01
    class APIBase < Grape::API
      def self.profile(api_key)
        raise 'Profile missing in configuration' unless ::RouterWrapper.config[:profiles].key? ::RouterWrapper.access[api_key][:profile]

        ::RouterWrapper.config[:profiles][::RouterWrapper.access[api_key][:profile]].deep_merge(
          ::RouterWrapper.access[api_key].except(:profile)
        )
      end

      ##
      # @param obj can be a string or an array
      def self.count_locations(obj)
        raise 'count_locations cannot be called with a nil object' unless obj

        case obj
        when Array
          # For route and routes, loc and locs become an array of arrays internally as follows:
          # 1 route with 3 locations         ->  [[[lat, lng], [lat, lng], [lat, lng]]]
          # 2 routes with 3 locations each   ->  [[[lat, lng], [lat, lng], [lat, lng]], [[lat, lng], [lat, lng], [lat, lng]]]
          # For matrix, src and dst become internally array and array of arrays:
          # [lat, lng, lat, lng, lat, lng]
          # [[lat, lng], [lat, lng], [lat, lng]]
          # For isoline it is a single pair of lat, lng
          # [lat, lng]
          obj.flatten.size / 2
        when String
          # The endpoints can receive values as follows (i.e., before coerce_with):
          # route and routes
          # 1 route with 3 locations      ->   "lat,lng,lat,lng,lat,lng"
          # 2 routes with 3+2 locations   ->   "lat,lng,lat,lng,lat,lng;lat,lng,lat,lng"
          # 2 routes with 3+2 locations   ->   "lat,lng,lat,lng,lat,lng|lat,lng,lat,lng"
          # matrix
          # "lat,lng,lat,lng,lat,lng"
          # isoline
          # "lat,lng"
          obj.split(/,|;|\|/).size / 2
        else
          raise 'Unknown obj type in count_locations'
        end
      end

      ##
      # @param obj can be a string or an array
      def self.count_distinct_routes(obj)
        case obj
        when String
          obj.count(';|\|') + 1
        when Array
          obj.size
        else
          raise 'Unknown obj type in count_distinct_routes'
        end
      end

      # Calculate route legs for given points considering start and end are not the same
      # For A-B ; C-D-E-F it equals to 4 -- i.e., (2-1) + (4-1) => (2+4) - (1+1)
      def self.count_route_legs(params)
        locations = params[:locs] || params[:loc] # The order is important since loc is expanded to locs in the endpoint

        # :loc or :locs is required, returning 0 since the request is invalid and will be refused
        return 0 unless locations

        count_locations(locations) - count_distinct_routes(locations)
      end

      def self.count_matrix_cells(params)
        # :src is required, returning 0 since the request is invalid and will be refused
        return 0 unless params[:src]

        src_size = count_locations(params[:src])
        dst_size = params[:dst] ? count_locations(params[:dst]) : src_size
        src_size * dst_size
      end

      def self.limit_matrix_side_size(params)
        src_size = count_locations(params[:src])
        dst_size = params[:dst] ? count_locations(params[:dst]) : src_size
        [src_size, dst_size].max
      end
    end
  end
end

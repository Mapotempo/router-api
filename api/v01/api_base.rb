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
        if obj.is_a? Array
          # route, matrix and isoline can send array like :
          # [[[lat, lng], [lat, lng]]] or [[lat, lng], [lat, lng]] or [lat, lng, lat, lng]
          obj.flatten.size / 2
        elsif obj.nil?
          0
        else
          # route, matrix and isoline can send value like :
          # "lat,lng,lat,lng" or "lat,lng;lat,lng" or "lat,lng|lat,lng"
          obj.split(/,|\;|\|/).size / 2
        end
      end

      # Calculate route legs for given points considering start and end are not the same
      # For A-B D-E-F it equals to 3 -- i.e., 2-1 + 3-1 => 2+3 - 1+1
      def self.count_route_legs(params)
        if params[:loc]
          count_locations(params[:loc]) - 1
        elsif params[:locs]
          [1, legs_in_distinct_routes(params[:locs]) - distinct_routes(params[:locs])].max
        end
      end

      def self.count_matrix_cells(params)
        src_size = count_locations(params[:src])
        dst_size = params[:dst] ? count_locations(params[:dst]) : src_size
        src_size * dst_size
      end

      def self.limit_matrix_side_size(params)
        src_size = count_locations(params[:src])
        dst_size = params[:dst] ? count_locations(params[:dst]) : src_size
        [src_size, dst_size].max
      end

      def self.legs_in_distinct_routes(obj)
        return count_locations(obj) unless multi_leg_route?(obj)

        case obj
        when Array
          obj.map { |locs| count_locations(locs) }.sum
        when String
          obj.split('\;|\|').map { |locs| count_locations(locs) }.sum
        end
      end

      def self.distinct_routes(obj)
        case obj
        when Array
          multi_leg_route?(obj) ? obj.size : 1
        when String
          multi_leg_route?(obj) ? obj.count('\;|\|') + 1 : 1
        end
      end

      def self.multi_leg_route?(obj)
        case obj
        when Array
          depth(obj) == 3 # Because of multi route structure [ [[], []], [[], []] ]
        when String
          obj.match(/\;|\|/) ? true : false
        end
      end

      def self.depth(arr)
        return 0 unless arr.is_a?(Array)

        1 + depth(arr[0])
      end
    end
  end
end

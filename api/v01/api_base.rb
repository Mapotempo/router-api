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

      def self.count_locations(obj)
        return 0 if obj.nil?

        if obj.is_a? Array
          # route, matrix and isoline can send array like :
          # [[[lat, lng], [lat, lng]]] or [[lat, lng], [lat, lng]] or [lat, lng, lat, lng]
          obj.flatten.size / 2
        else
          obj.split(',').size / 2 # matrix, isoline, route : "lat,lng,lat,lng"
        end
      end

      def self.count_route_locations(params)
        if params[:loc]
          count_locations(params[:loc])
        elsif params[:locs]
          count_locations(params[:locs])
        end
      end

      def self.count_matrix_locations(params)
        if params[:dst] && params[:src]
          count_locations(params[:src]) * count_locations(params[:dst])
        elsif params[:src] && !params[:dst]
          count_locations(params[:src]) * count_locations(params[:src])
        end
      end
    end
  end
end

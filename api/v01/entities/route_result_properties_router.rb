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
require './api/v01/entities/entity'
require './api/v01/entities/route_result_properties_router_summed_by_area'

module Api
  module V01
    class RouteResultPropertiesRouter < Grape::Entity
      def self.entity_name
        'RouteResultPropertiesRouter'
      end

      # RECOMMENDED
      expose_not_nil(:total_distance, documentation: { type: Integer, desc: 'Route total distance in meters.' })
      # RECOMMENDED
      expose_not_nil(:total_time, documentation: { type: Integer, desc: 'Route total time in seconds.' })
      # OPTIONAL
      expose(:start_point, documentation: { type: Float, is_array: true, desc: 'Latitude and longitude of starting point.' })
      # OPTIONAL
      expose(:end_point, documentation: { type: Float, is_array: true, desc: 'Latitude and longitude of ending point.' })
      # OPTIONAL
      expose :total_toll_costs, documentation: { type: Float, desc: 'Total toll costs amount in specified currency.' }, if: :toll_costs
      # OPTIONAL
      expose :summed_by_area, using: RouteResultPropertiesRouterSummedByArea, documentation: { type: Array, desc: 'Distance summed by area type.' }, if: :with_summed_by_area
    end
  end
end

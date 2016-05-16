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


module Api
  module V01
    class RouterDesc < Grape::Entity
      def self.entity_name
        'RouterDesc'
      end

      expose(:mode, documentation: { type: String })
      expose(:name, documentation: { type: String })
      expose(:dimensions, documentation: { type: String, values: ['time', 'time_distance', 'distance', 'distance_time'] })
      expose(:support_avoid_area, documentation: { type: 'Boolean' })
      expose(:support_speed_multiplicator_area, documentation: { type: 'Boolean' })
      expose(:area, documentation: { type: String, is_array: true })
    end
  end
end

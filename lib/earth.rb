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
module RouterWrapper
  # Class regrouping earth calculations tools
  class Earth
    RAD_PER_DEG = Math::PI / 180
    DEG_PER_RAD = 180 / Math::PI
    RM = 6371000 # Earth radius in meters

    def self.distance_between(lon1, lat1, lon2, lat2)
      lat1_rad = lat1 * RAD_PER_DEG
      lat2_rad = lat2 * RAD_PER_DEG
      lon1_rad = lon1 * RAD_PER_DEG
      lon2_rad = lon2 * RAD_PER_DEG

      a = Math.sin((lat2_rad - lat1_rad) / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin((lon2_rad - lon1_rad) / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      RM * c # Delta in meters
    end

    def self.draw_circle(lat, lng, radius, points = 64)
      rlat = radius.to_f / RM * DEG_PER_RAD
      rlng = rlat / Math.cos(lat * RAD_PER_DEG)
      rtheta = 1 / (points.to_f / 2) * Math::PI

      Array.new(points) do |i|
        [lng + rlng * Math.cos(i * rtheta), lat + rlat * Math.sin(i * rtheta)]
      end
    end
  end
end

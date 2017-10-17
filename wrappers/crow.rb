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
require './wrappers/wrapper'


module Wrappers
  class Crow < Wrapper
    def initialize(cache, hash = {})
      super(cache, hash)
    end

    # Declare available router options for capability operation
    def speed_multiplier?
      true
    end

    def route(locs, dimension, departure, arrival, language, with_geometry, options = {})
      d = distance_between(locs[0][1], locs[0][0], locs[-1][1], locs[-1][0])
      ret = {
        type: 'FeatureCollection',
        router: {
          licence: 'CC0',
          attribution: 'none',
        },
        features: [{
          type: 'Feature',
          properties: {
            router: {
              total_distance: d,
              total_time: d * 1.0 / (options[:speed_multiplier] || 1),
              start_point: locs[0],
              end_point: locs[-1]
            }
          }
        }]
      }

      if with_geometry
        ret[:features][0][:geometry] = {
          type: 'LineString',
          coordinates: locs.collect(&:reverse)
        }
      end

      ret
    end

    def matrix(src, dst, dimension, departure, arrival, language, options = {})
      {
        router: {
          licence: 'CC0',
          attribution: 'none',
        },
        matrix_time: src.collect{ |s|
          dst.collect{ |d|
            distance_between(s[1], s[0], d[1], d[0]) * 1.0 / (options[:speed_multiplier] || 1)
          }
        }
      }
    end

    def isoline(loc, dimension, size, departure, language, options = {})
      ret = {
        type: 'FeatureCollection',
        router: {
          licence: 'CC0',
          attribution: 'none',
        },
        features: [{
          type: 'Feature',
          geometry: {
            type: 'Polygon',
            coordinates: [draw_circle(loc[0], loc[1], size * 1.0 / (options[:speed_multiplier] || 1))]
          }
        }]
      }
    end

    private

    RAD_PER_DEG = Math::PI / 180
    DEG_PER_RAD = 180 / Math::PI
    RM = 6371000 # Earth radius in meters

    def distance_between(lat1, lon1, lat2, lon2)
      lat1_rad, lat2_rad = lat1 * RAD_PER_DEG, lat2 * RAD_PER_DEG
      lon1_rad, lon2_rad = lon1 * RAD_PER_DEG, lon2 * RAD_PER_DEG

      a = Math.sin((lat2_rad - lat1_rad) / 2) ** 2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin((lon2_rad - lon1_rad) / 2) ** 2
      c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1 - a))

      RM * c # Delta in meters
    end

    def draw_circle(lat, lng, radius, points = 64)
      rlat = radius.to_f / RM * DEG_PER_RAD
      rlng = rlat / Math.cos(lat * RAD_PER_DEG)
      rtheta = 1 / (points.to_f / 2) * Math::PI

      points.times.collect{ |i|
        [lng + rlng * Math.cos(i* rtheta), lat + rlat * Math.sin(i * rtheta)]
      }
    end
  end
end

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
  class Demo < Wrapper
    def initialize(cache, hash = {})
      super(cache, hash)
    end

    def route(locs, dimension, departure, arrival, language, with_geometry, options = {})
      ret = {
        type: 'FeatureCollection',
        router: {
          licence: 'demo',
          attribution: 'demo',
        },
        features: [{
          type: 'Feature',
          properties: {
            router: {
              total_distance: 1,
              total_time: 1,
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
          licence: 'demo',
          attribution: 'demo',
        },
        matrix_time: src.collect{ |s|
          dst.collect{ |d|
            1
          }
        }
      }
    end

    def isoline(loc, dimension, size, departure, language, options = {})
      ret = {
        type: 'FeatureCollection',
        router: {
          licence: 'demo',
          attribution: 'demo',
        },
        features: [{
          type: 'Feature',
          geometry: {
            type: 'Polygon',
            coordinates: [[
              [-51.67968749999999, 68.13885164925573],
              [-50.625, 62.2679226294176],
              [-44.29687499999999, 60.06484046010452],
              [-40.078125, 65.36683689226321],
              [-23.5546875, 70.02058730174062],
              [-51.328125, 70.72897946208789],
              [-51.67968749999999, 68.13885164925573]
            ]]
          }
        }]
      }
    end
  end
end

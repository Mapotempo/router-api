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
require './wrappers/wrapper'


module Wrappers
  class Demo < Wrapper
    def initialize(cache, hash = {})
      super(cache, hash)
    end

    def route(locs, departure, arrival, language, with_geometry, options = {})
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

    def matrix(src, dst, departure, arrival, language, options = {})
      {
        router: {
          licence: 'demo',
          attribution: 'demo',
        },
        matrix: src.collect{ |s|
          dst.collect{ |d|
            1
          }
        }
      }
    end
  end
end

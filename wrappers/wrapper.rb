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
require 'digest/md5'
require 'border_patrol'


module Wrappers
  class Wrapper
    def initialize(cache, hash = {})
      @cache = cache
      if hash[:boundary]
        @boundary = BorderPatrol.parse_kml(File.read(hash[:boundary]))
      end
      @area = hash[:area]
    end

    def area
      @area
    end

    def avoid_area?
      false
    end

    def speed_multiplicator_area?
      false
    end

    def route_dimension
      [:time]
    end

    def route?(start, stop, dimension)
      if @boundary
        contains?(*start) && contains?(*stop)
      else
        true
      end
    end

    def matrix_dimension
      [:time]
    end

    def matrix?(top_left, down_right, dimension)
      if @boundary
        contains?(*top_left[0]) && contains?(*top_left[1]) && contains?(*down_right[0]) && contains?(*down_right[1])
      else
        true
      end
    end

    def matrix(srcs, dsts, dimension, departure, arrival, language, options = {})
      m = srcs.collect{ |src|
        dsts.collect{ |dst|
          ret = route([src, dst], dimension, departure, arrival, language, options)
          if ret.key?(:features) && ret[:features].size > 0
            ret[:features][0][:properties][:router][:total_time]
          end
        }
      }

      {
        router: {
          licence: @licence,
          attribution: @attribution,
        },
        matrix_time: m
      }
    end

    def isoline_dimension
      [:time]
    end

    def isoline?(loc, dimension)
      if @boundary
        contains?(*loc)
      else
        true
      end
    end

    private

    def contains?(lat, lng)
      if !lat.nil? && !lng.nil?
        @boundary.contains_point?(lng, lat)
      end
    end
  end

  class UnreachablePointError < StandardError
  end
end

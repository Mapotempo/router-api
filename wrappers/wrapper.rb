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
    OPTIONS = [
      :speed_multiplier,
      :avoid_area,
      :speed_multiplier_area,
      :departure,
      :arrival,
      :traffic,
      :track,
      :motorway,
      :toll,
      :trailers,
      :weight,
      :weight_per_axle,
      :height,
      :width,
      :length,
      :hazardous_goods,
      :max_walk_distance,
      :toll_costs,
      :currency,
      :approach,
      :snap,
      :strict_restriction,
      :with_summed_by_area
    ]

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

    OPTIONS.each do |s|
      define_method("#{s}?") do
        false
      end
    end

    def route_dimension
      [:time]
    end

    def route?(start, stop, dimension)
      route_dimension.include?(dimension) && (!@boundary || (contains?(*start) && contains?(*stop)))
    end

    def matrix_dimension
      [:time]
    end

    def matrix?(src, dst, dimension)
      matrix_dimension.include?(dimension) && (!@boundary || (contains?(*src) && contains?(*dst)))
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
      isoline_dimension.include?(dimension) && (!@boundary || contains?(*loc))
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

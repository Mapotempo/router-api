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

require 'uri'
require 'rest-client'
#RestClient.log = $stdout


module Wrappers
  class Otp < Wrapper
    def initialize(cache, url, router_id, licence, attribution, boundary = nil)
      super(cache, boundary)
      @url = url
      @router_id = router_id
      @licence = licence
      @attribution = attribution
    end

    def route(locs, departure, arrival, language, with_geometry)
      datetime, arrive_by = departure ? [departure, false] : arrival ? [arrival, true] : [Time.now, false]
      key = [:otp, :request, @router_id, Digest::MD5.hexdigest(Marshal.dump([@url, locs[0], locs[-1], datetime, arrive_by]))]
      request = @cache.read(key)
      if !request
        params = {
          fromPlace: locs[0].join(','),
          toPlace: locs[-1].join(','),
          # Warning, full english fashion date and time
          time: datetime.strftime('%I:%M%p'),
          date: datetime.strftime('%m-%d-%Y'),
          arriveBy: arrive_by,
          maxWalkDistance: 500,
          wheelchair: false,
          showIntermediateStops: false
        }
        request = String.new(RestClient.get(@url + '/otp/routers/' + @router_id + '/plan', {
          accept: :json,
          params: params
        }))
        @cache.write(key, request)
      end

      ret = {
        type: 'FeatureCollection',
        router: {
          licence: @licence,
          attribution: @attribution,
        },
        features: []
      }

      data = JSON.parse(request) if request
      if data && !data['error'] && data['plan'] && data['plan']['itineraries']
        i = data['plan']['itineraries'][0]

        ret[:features] = [{
          type: 'Feature',
          properties: {
            router: {
              total_distance: i['walkDistance'] || 0, # FIXME walk onl
              total_time: i['duration'],
              start_point: locs[0].reverse,
              end_point: locs[-1].reverse
            }
          }
        }]

        if with_geometry
          ret[:features][0][:geometry] = {
            type: 'LineString',
            coordinates: i['legs'].collect{ |leg| leg['legGeometry']['points'] }.collect{ |code|
              Polylines::Decoder.decode_polyline(code)
            }.flatten(1).collect(&:reverse)
          }
        end
      end

      ret
    end
  end
end

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

require 'uri'
require 'rest-client'
#RestClient.log = $stdout


module Wrappers
  class Otp < Wrapper
    def initialize(cache, hash = {})
      super(cache, hash)
      @url = hash[:url]
      @router_id = hash[:router_id]
      @licence = hash[:licence]
      @attribution = hash[:attribution]
      @crs = hash[:crs]
    end

    # Declare available router options for capability operation
    [:departure, :arrival, :max_walk_distance].each do |s|
      define_method("#{s}?") do
        true
      end
    end

    def route?(start, stop, dimension)
      dimension == :time && super(start, stop, dimension)
    end

    def route(locs, dimension, departure, arrival, language, with_geometry, options = {})
      datetime, arrive_by = departure ? [departure, false] : arrival ? [arrival, true] : [monday_morning, false]
      key = [:otp, :route, @router_id, Digest::MD5.hexdigest(Marshal.dump([@url, locs[0], locs[-1], dimension, datetime, arrive_by, language, options]))]
      request = @cache.read(key)
      if !request
        params = {
          fromPlace: locs[0].join(','),
          toPlace: locs[-1].join(','),
          # Warning, full english fashion date and time
          time: datetime.strftime('%I:%M%p'),
          date: datetime.strftime('%m-%d-%Y'),
          arriveBy: arrive_by,
          maxWalkDistance: options[:max_walk_distance] || 750,
          wheelchair: false,
          showIntermediateStops: false
        }
        request = RestClient.get(@url + '/otp/routers/' + @router_id + '/plan', {
          accept: :json,
          params: params
        })
        @cache.write(key, request.body)
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
              total_distance: i['walkDistance'] || 0, # FIXME walk only
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

    def matrix?(src, dst, dimension)
      dimension == :time && super(src, dst, dimension)
    end

    def isoline?(loc, dimension)
      dimension == :time && super(loc, dimension)
    end

    def isoline(loc, dimension, size, departure, language, options = {})
      key = [:otp, :isoline, @router_id, loc, dimension, size, departure, language, Digest::MD5.hexdigest(Marshal.dump([options]))]

      departure ||= monday_morning

      request = @cache.read(key)
      if !request
        params = {
          requestTimespanHours: 2,
          radiusMeters: 750,
          nContours: 1,
          contourSpacingMinutes: size / 60,
          crs: @crs,
          fromPlace: loc.join(','),
          maxTransfers: 2,
          batch: true,
          # Warning, full english fashion date and time
          time: departure && departure.strftime('%I:%M%p'),
          date: departure && departure.strftime('%m-%d-%Y'),
          wheelchair: false,
        }
        request = RestClient::Request.execute(method: :get, url: @url + '/otp/routers/' + @router_id + '/simpleIsochrone',
          timeout: nil,
          headers: {
            accept: :json,
            params: params
          }
        )
        @cache.write(key, request.body)
      end

      if request
        data = JSON.parse(request).with_indifferent_access
        data[:router] = {
          licence: @licence,
          attribution: @attribution,
        }
        data
      end
    end

    private

    def monday_morning
      monday_morning = Date.today
      #monday_morning += (8 - monday_morning.cwday).modulo(7) # Go to current week monday
      monday_morning.to_time + 9.hours # Go to monday 09:00
    end
  end
end

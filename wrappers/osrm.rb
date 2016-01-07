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
  class Osrm < Wrapper
    def initialize(cache, hash = {})
      super(cache, hash)
      @url_osrm = hash[:url_osrm]
      @url_isochrone = hash[:url_isochrone]
      @licence = hash[:licence]
      @attribution = hash[:attribution]
    end

    def route(locs, departure, arrival, language, with_geometry, options = {})
      # Workaround, cause restclient dosen't deals with array params
      query_params = 'viaroute?' + URI::encode_www_form([[:alt, false], [:geometry, with_geometry]] + locs.collect{ |loc| [:loc, loc.join(',')] })

      key = [:osrm, :route, Digest::MD5.hexdigest(Marshal.dump([@url_osrm, query_params, language]))]
      json = @cache.read(key)
      if !json
        resource = RestClient::Resource.new(@url_osrm)
        response = resource[query_params].get
        json = JSON.parse(response)
        @cache.write(key, json)
      end

      ret = {
        type: 'FeatureCollection',
        router: {
          licence: @licence,
          attribution: @attribution,
        },
        features: []
      }

      if json['status'] == 200
        ret[:features] = [{
          type: 'Feature',
          properties: {
            router: {
              total_distance: json['route_summary']['total_distance'],
              total_time: json['route_summary']['total_time'] * 1.0 / (options[:speed_multiplicator] || 1),
              start_point: locs[0].reverse,
              end_point: locs[-1].reverse
            }
          }
        }]

        if with_geometry
          ret[:features][0][:geometry] = {
            type: 'LineString',
            polylines: json['route_geometry']
          }
        end
      end

      ret
    end

    def matrix(srcs, dsts, departure, arrival, language, options = {})
      # Workaround, cause restclient dosen't deals with array params
      query_params = 'table?' + URI::encode_www_form([[:alt, false]] + srcs.collect{ |src| [:src, src.join(',')] } + dsts.collect{ |dst| [:dst, dst.join(',')] })

      key = [:osrm, :matrix, Digest::MD5.hexdigest(Marshal.dump([@url_osrm, query_params, language]))]
      json = @cache.read(key)
      if !json
        resource = RestClient::Resource.new(@url_osrm)
        response = resource[query_params].get
        json = JSON.parse(response)
        @cache.write(key, json)
      end

      {
        router: {
          licence: @licence,
          attribution: @attribution,
        },
        matrix: json['distance_table'].collect { |r|
          r.collect { |rr|
            rr >= 2147483647 ? nil : (rr / 10.0 / (options[:speed_multiplicator] || 1)).round
          }
        }
      }
    end

    def isoline(loc, size, departure, language, options = {})
      key = [:osrm, :isoline, Digest::MD5.hexdigest(Marshal.dump([@url_isochrone, loc, size]))]
      request = @cache.read(key)
      if !request
        params = {
          lat: loc[0],
          lng: loc[1],
          time: size * (options[:speed_multiplicator] || 1)
        }
        request = String.new(RestClient.get(@url_isochrone + '/0.1/isochrone', {
          accept: :json,
          params: params
        }))
        @cache.write(key, request)
      end

      if request
        data = JSON.parse(request)
        data[:router] = {
          licence: @licence,
          attribution: @attribution,
        }
        data
      end
    end
  end
end

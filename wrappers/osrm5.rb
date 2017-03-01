# Copyright © Mapotempo, 2016
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
require 'addressable'
#RestClient.log = $stdout
require 'polylines'


module Wrappers
  class Osrm5 < Wrapper
    def initialize(cache, hash = {})
      super(cache, hash)
      @url_trace = {
        time: hash[:url_time],
        distance: hash[:url_distance]
      }
      @url_matrix = {
        time: hash[:url_time],
        time_distance: hash[:url_time],
        distance: hash[:url_distance],
        distance_time: hash[:url_distance]
      }
      @url_isoline = {
        time: hash[:url_isochrone],
        distance: hash[:url_isodistance]
      }
      @licence = hash[:licence]
      @attribution = hash[:attribution]
    end

    def route_dimension
      @url_trace.keys.select{ |d| @url_trace[d] }.compact
    end

    def route?(top_left, down_right, dimension)
      @url_trace[dimension] && super(top_left, down_right, dimension)
    end

    def route(locs, dimension, departure, arrival, language, with_geometry, options = {})
      key = [:osrm5, :route, Digest::MD5.hexdigest(Marshal.dump([@url_trace[dimension], with_geometry, locs, language, options]))]

      json = @cache.read(key)
      if !json
        params = {
          alternatives: false,
          steps: false,
          annotations: false,
          geometries: :polyline,
          overview: with_geometry ? :full : false,
          continue_straight: false
        }
        coordinates = locs.collect{ |loc| [loc[1], loc[0]].join(',') }.join(';')
        request = RestClient.get(@url_trace[dimension] + '/route/v1/driving/' + coordinates, {
          accept: :json,
          params: params
        }) { |response, request, result, &block|
          case response.code
          when 200, 400
            response
          else
            raise response
          end
        }

        json = JSON.parse(request)
        if ['Ok', 'NoRoute'].include?(json['code'])
          @cache.write(key, json)
        else
          raise 'OSRM request fails with: ' + (json['code'] || '')  + ' ' + (json['message'] || '')
        end
      end

      ret = {
        type: 'FeatureCollection',
        router: {
          licence: @licence,
          attribution: @attribution,
        },
        features: []
      }

      ret[:features] = (json['routes'] || []).collect{ |route| {
        type: 'Feature',
        properties: {
          router: {
            total_distance: route['distance'],
            total_time: (route['duration'] * 1.0 / (options[:speed_multiplier] || 1)).round(1),
            start_point: locs[0].reverse,
            end_point: locs[-1].reverse
          }
        }
      }}

      if with_geometry
        (json['routes'] || []).each_with_index{ |route, index|
          ret[:features][index][:geometry] = {
            type: 'LineString',
            coordinates: Polylines::Decoder.decode_polyline(route['geometry'], 1e5).collect(&:reverse)
          }
        }
      end

      ret
    end


    def matrix_dimension
      @url_matrix.keys.select{ |d| @url_matrix[d] }.compact
    end

    def matrix?(src, dst, dimension)
      @url_matrix[dimension] && super(src, dst, dimension)
    end

    def matrix(srcs, dsts, dimension, departure, arrival, language, options = {})
      dim1, dim2 = dimension.to_s.split('_').collect(&:to_sym)
      key = [:osrm5, :matrix, Digest::MD5.hexdigest(Marshal.dump([@url_matrix[dim1], srcs, dsts, options]))]

      json = @cache.read(key)
      if !json
        if srcs == dsts
          locs_uniq = srcs
          params = {}
        else
          locs_uniq = (srcs + dsts).uniq.sort_by{ |a, b| a + b }
          params = {
            sources: srcs.collect{ |d| locs_uniq.index(d) }.join(';'),
            destinations: dsts.collect{ |d| locs_uniq.index(d) }.join(';'),
          }
        end

        if locs_uniq.size == 1
          json['durations'] = [[0], [0]]
        else
          uri = ::Addressable::URI.parse(@url_matrix[dim1])
          uri.path = '/table/v1/driving/polyline(' + Polylines::Encoder.encode_points(locs_uniq, 1e5) + ')'
          request = RestClient.get(uri.normalize.to_str, {
            accept: :json,
            params: params
          }) { |response, request, result, &block|
            case response.code
            when 200, 400
              response
            else
              raise response
            end
          }

          json = JSON.parse(request)
          if json['code'] == 'Ok'
            @cache.write(key, json)
          else
            raise 'OSRM request fails with: ' + (json['code'] || '') + ' ' + (json['message'] || '')
          end
        end
      end

      ret = {
        router: {
          licence: @licence,
          attribution: @attribution,
        },
        "matrix_#{dim1}".to_sym => json['durations'].collect { |r|
          r.collect { |rr|
            rr ? (rr * 1.0 / (options[:speed_multiplier] || 1)).round : nil
          }
        }
      }

      if dim2
        ret["matrix_#{dim2}".to_sym] = srcs.collect{ |src|
          dsts.collect{ |dst|
            if src == dst
              0.0
            else
              locs = [src, dst]
              key = [:osrm5, :route, Digest::MD5.hexdigest(Marshal.dump([@url_trace[dim1], false, locs, language, options]))]

              json = @cache.read(key)
              if !json
                params = {
                  alternatives: false,
                  steps: false,
                  annotations: false,
                  geometries: :polyline,
                  overview: false,
                  continue_straight: false
                }
                coordinates = locs.collect{ |loc| loc.reverse.join(',') }.join(';')
                request = RestClient.get(@url_trace[dim1] + '/route/v1/driving/' + coordinates, {
                  accept: :json,
                  params: params
                }) { |response, request, result, &block|
                  case response.code
                  when 200, 400
                    response
                  else
                    response.return!(request, result, &block)
                  end
                }

                if request
                  json = JSON.parse(request)
                  if ['Ok', 'NoRoute'].include?(json['code'])
                    @cache.write(key, json)
                    if json['code'] == 'Ok'
                      json['routes'][0]['distance']
                    end
                  end
                end
              end
            end
          }
        }
      end

      ret
    end

    def isoline_dimension
      @url_isoline.keys.select{ |d| @url_isoline[d] }.compact
    end

    def isoline?(loc, dimension)
      @url_isoline[dimension] && super(loc, dimension)
    end

    def isoline(loc, dimension, size, departure, language, options = {})
      key = [:osrm5, :isoline, Digest::MD5.hexdigest(Marshal.dump([@url_isoline[dimension], loc, size, options]))]
      request = @cache.read(key)
      if !request
        params = {
          lat: loc[0],
          lng: loc[1],
          time: (size * (options[:speed_multiplier] || 1)).round(1)
        }
        request = RestClient.get(@url_isoline[dimension] + '/0.1/isochrone', {
          accept: :json,
          params: params
        })
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
  end
end

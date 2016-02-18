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
  class Here < Wrapper

    def initialize(cache, hash = {})
      super(cache, hash)
      @url = 'https://route.nlp.nokia.com/routing'
      @app_id = hash[:app_id]
      @app_code = hash[:app_code]
      @mode = hash[:mode]
    end

    def route(locs, departure, arrival, language, with_geometry, options = {})
      params = {
        mode: "fastest;#{@mode};traffic:disabled",
        alternatives: 0,
        resolution: 1,
        language: language,
        representation: 'display',
        routeAttributes: 'summary,shape',
        truckType: @mode,
        #limitedWeight: # Truck routing only, vehicle weight including trailers and shipped goods, in tons.
        #weightPerAxle: # Truck routing only, vehicle weight per axle in tons.
        #height: # Truck routing only, vehicle height in meters.
        #width: # Truck routing only, vehicle width in meters.
        #length: # Truck routing only, vehicle length in meters.
        #tunnelCategory : # Specifies the tunnel category to restrict certain route links. The route will pass only through tunnels of a les
      }
      locs.each_with_index{ |loc, index|
        params["waypoint#{index}"] = "geo!#{loc[0]},#{loc[1]}"
      }
      request = get('7.2/calculateroute', params)

      ret = {
        type: 'FeatureCollection',
        router: {
          licence: 'HERE',
          attribution: 'HERE',
        },
        features: []
      }

      if request && request['response'] && request['response']['route']
        r = request['response']['route'][0]
        s = r['summary']

        ret[:features] = [{
          type: 'Feature',
          properties: {
            router: {
              total_distance: s['distance'],
              total_time: s['trafficTime'] * 1.0 / (options[:speed_multiplicator] || 1),
              start_point: locs[0].reverse,
              end_point: locs[-1].reverse
            }
          }
        }]

        if with_geometry
          ret[:features][0][:geometry] = {
            type: 'LineString',
            coordinates: r['shape'].collect{ |p|
              p.split(',').collect(&:to_f)
            }.each_slice(2).each(&:reverse)
          }
        end
      end

      ret
    end

    def matrix(srcs, dsts, departure, arrival, language, options = {})
      raise 'More than 100x100 matrix, not possible with Here' if srcs.size > 100 || dsts.size > 100

      srcs = srcs.collect{ |r| [r[0].round(5), r[1].round(5)] }
      dsts = dsts.collect{ |c| [c[0].round(5), c[1].round(5)] }

      key = Digest::MD5.hexdigest(Marshal.dump([srcs, dsts, options]))

      result = @cache.read(key)
      if !result

        # From Here "Matrix Routing API Developer's Guide"
        # Recommendations for Splitting Matrixes
        # The best way to split a matrix request is to split it into parts with only few start positions and many
        # destinations. The number of the start positions should be between 3 and 15, depending on the size
        # of the area covered by the matrix. The matrices should be split into requests sufficiently small to
        # ensure a response time of 30 seconds each. The number of the destinations in one request is limited
        # to 100.

        # Request should not contain more than 15 starts per request
        # 500 to get response before 30 seconds timeout
        split_size = [5, (1000 / srcs.size).round].min

        result = Array.new(srcs.size) { Array.new(dsts.size) }

        commons_param = {
          mode: 'fastest;truck;traffic:disabled',
          truckType: 'truck',
          summaryAttributes: 'traveltime', # TODO: manage distance here (dimension)
          #limitedWeight: # Truck routing only, vehicle weight including trailers and shipped goods, in tons.
          #weightPerAxle: # Truck routing only, vehicle weight per axle in tons.
          #height: # Truck routing only, vehicle height in meters.
          #width: # Truck routing only, vehicle width in meters.
          #length: # Truck routing only, vehicle length in meters.
        }
        0.upto(dsts.size - 1).each{ |i|
          commons_param["destination#{i}"] = dsts[i].join(',')
        }

        total = srcs.size * dsts.size
        srcs_start = 0
        while srcs_start < srcs.size do
          param = commons_param.dup
          srcs_start.upto([srcs_start + split_size - 1, srcs.size - 1].min).each{ |i|
            param["start#{i - srcs_start}"] = srcs[i].join(',')
          }
          request = get('7.2/calculatematrix', param)

          request['response']['matrixEntry'].each{ |e|
            s = e['summary']
            result[srcs_start + e['startIndex']][e['destinationIndex']] = s ? s['travelTime'].round : nil # TODO: return distance in addition
          }

          srcs_start += split_size
        end

        @cache.write(key, result)
      end

      {
        router: {
          licence: 'HERE',
          attribution: 'HERE',
        },
        matrix: result.collect { |r|
          r.collect { |rr|
            rr ? (rr / (options[:speed_multiplicator] || 1)).round : nil
          }
        }
      }
    end

    private

    def get(object, params = {})
      url = "#{@url}/#{object}.json"
      params = {app_id: @app_id, app_code: @app_code}.merge(params)

      key = [:here, :request, Digest::MD5.hexdigest(Marshal.dump([url, params.to_a.sort_by{ |i| i[0].to_s }]))]
      request = @cache.read(key)
      if !request
        begin
          response = RestClient.get(url, {params: params})
        rescue => e
          error = JSON.parse(e.response)
          if error['type'] == 'ApplicationError'
            additional_data = error['AdditionalData'] || error['additionalData']
            if additional_data
              if additional_data.include?({'key' => 'error_code', 'value' => 'NGEO_ERROR_GRAPH_DISCONNECTED'})
                return
              elsif additional_data.include?({'key' => 'error_code', 'value' => 'NGEO_ERROR_ROUTE_NO_START_POINT'})
                raise UnreachablePointError
              else
                raise
              end
            end
          end
          Api::Root.logger.info [url, params]
          Api::Root.logger.info error
          error = error['response'] if error.key?('response')
          raise ['Here', error['type'], error['subtype'], error['details'], error['Details']].compact.join(' ')
        end

        request = JSON.parse(response)
        @cache.write(key, request)
      end

      request
    end
  end
end

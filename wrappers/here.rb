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
      @url_router = 'https://route.api.here.com/routing'
      @url_matrix = 'https://matrix.route.api.here.com/routing'
      @url_isoline = 'https://isoline.route.api.here.com/routing'
      @app_id = hash[:app_id]
      @app_code = hash[:app_code]
      @mode = hash[:mode]
    end

    def avoid_area?
      true
    end

    def route(locs, dimension, departure, arrival, language, with_geometry, options = {})
      params = {
        mode: here_mode(dimension.to_s.split('_').collect(&:to_sym), @mode),
        avoidAreas: here_avoid_areas(options[:speed_multiplicator_area]),
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
      request = get(@url_router, '7.2/calculateroute', params)

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
            }.collect(&:reverse)
          }
        end
      end

      ret
    end

    def matrix_dimension
      [:time, :time_distance].push(* here_dimension_distance? ? [:distance, :distance_time] : nil)
    end

    def matrix(srcs, dsts, dimension, departure, arrival, language, options = {})
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

        # Request should not contain more than 15 starts per request / 100 combinaisons
        # 500 to get response before 30 seconds timeout
        srcs_split = [(100 / [dsts.size, 100].min).to_i, (1000 / srcs.size).round].min
        dsts_split = dsts_max = [100, dsts.size].min

        result = {
          time: Array.new(srcs.size) { Array.new(dsts.size) },
          distance: Array.new(srcs.size) { Array.new(dsts.size) }
        }

        dim = dimension.to_s.split('_').collect(&:to_sym)

        commons_param = {
          mode: here_mode(dim, @mode),
          avoidAreas: here_avoid_areas(options[:speed_multiplicator_area]),
          truckType: @mode,
          summaryAttributes: dim.collect{ |d| d == :time ? 'traveltime' : d == :distance ? 'distance' : nil }.compact.join(',')
          #limitedWeight: # Truck routing only, vehicle weight including trailers and shipped goods, in tons.
          #weightPerAxle: # Truck routing only, vehicle weight per axle in tons.
          #height: # Truck routing only, vehicle height in meters.
          #width: # Truck routing only, vehicle width in meters.
          #length: # Truck routing only, vehicle length in meters.
        }

        total = srcs.size * dsts.size
        srcs_start = 0
        while srcs_start < srcs.size do
          param_start = {}
          srcs_start.upto([srcs_start + srcs_split - 1, srcs.size - 1].min).each{ |i|
            param_start["start#{i - srcs_start}"] = srcs[i].join(',')
          }
          dsts_start = 0
          dsts_split = [dsts_split * 2, dsts_max].min
          while dsts_start < dsts.size do
            param_destination = {}
            dsts_start.upto([dsts_start + dsts_split - 1, dsts.size - 1].min).each{ |i|
              param_destination["destination#{i - dsts_start}"] = dsts[i].join(',')
            }
            request = get(@url_matrix, '7.2/calculatematrix', commons_param.dup.merge(param_start).merge(param_destination))

            if request
              request['response']['matrixEntry'].each{ |e|
                s = e['summary']
                if s
                  result[:time][srcs_start + e['startIndex']][dsts_start + e['destinationIndex']] = s && s.key?('travelTime') ? s['travelTime'].round : nil
                  result[:distance][srcs_start + e['startIndex']][dsts_start + e['destinationIndex']] = s && s.key?('distance') ? s['distance'].round : nil
                elsif e['status'] == 'failed'
                  request = nil
                  break
                end
              }
            end

            # in some cases, matrix cannot be computed (cancelled) or is incomplete => try to decrease matrix size
            if !request && dsts_split > 2
              dsts_start = [dsts_start - dsts_split, 0].max
              dsts_split = (dsts_split / 2).ceil
            else
              dsts_start += dsts_split
            end
          end

          srcs_start += srcs_split
        end

        @cache.write(key, result)
      end

      ret = {
        router: {
          licence: 'HERE',
          attribution: 'HERE',
        },
        matrix_time: result[:time].collect { |r|
          r.collect { |rr|
            rr ? (rr / (options[:speed_multiplicator] || 1)).round : nil
          }
        }
      }

      if dimension == :time_distance
        ret[:matrix_distance] = result[:distance].collect { |r|
          r.collect { |rr|
            rr ? (rr / (options[:speed_multiplicator] || 1)).round : nil
          }
        }
      end

      ret
    end

    def isoline?(loc, dimension)
      false # TODO: not implemented
    end

    private

    def here_dimension_distance?
      if @mode == 'truck'
        false # not supported in 7.2 for truck
      else
        true
      end
    end

    def here_mode(dimension, mode)
      "#{dimension[0] == :time ? 'fastest' : 'shortest'};#{@mode};traffic:disabled"
    end

    def here_avoid_areas(areas)
      # Keep only avoid area
      areas.select{ |k, v| v == 0 }.collect{ |area, _v|
        lats = area.minmax_by{ |p| p[0] }
        lons = area.minmax_by{ |p| p[1] }
        "#{lats[1][0]},#{lons[1][1]};#{lats[0][0]},#{lons[0][1]}"
      }.join('!') if areas
    end

    def get(url_base, object, params = {})
      url = "#{url_base}/#{object}.json"
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
              elsif additional_data.include?({'key' => 'error_code', 'value' => 'NGEO_ERROR_ROUTING_CANCELLED'})
                return
              elsif additional_data.include?({'key' => 'error_code', 'value' => 'NGEO_ERROR_ROUTE_NO_START_POINT'})
                raise UnreachablePointError
              else
                raise
              end
            end
          end
          Api::Root.logger.info [url, params]
          Api::Root.logger.info error.inspect
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

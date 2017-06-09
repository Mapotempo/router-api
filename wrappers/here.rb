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
      @url_tce = 'https://tce.api.here.com'
      @app_id = hash[:app_id]
      @app_code = hash[:app_code]
      @mode = hash[:mode]
    end

    # Declare available router options for capability operation
    # Here api supports most of options... remove unsupported options below
    (OPTIONS - [:speed_multiplier_area, :max_walk_distance]).each do |s|
      define_method("#{s}?") do
        true
      end
    end

    def toll_costs(link_ids, departure, options = {})
      # https://developer.here.com/platform-extensions/documentation/toll-cost/topics/example-tollcost.html
      params = {
        # https://developer.here.com/platform-extensions/documentation/toll-cost/topics/resource-tollcost-input-param-vspec.html
        tollVehicleType: 3,
        trailerType: options[:trailers] ? 2 : nil,
        trailersCount: options[:trailers],
        vehicleNumberAxles: 2, # Not including trailer axles
        trailerNumberAxles: options[:trailers] ? 2 * options[:trailers] : nil,
        # hybrid:
        emissionType: 6,
        height: options[:height] ? "#{options[:height]}m" : nil,
        trailerHeight: options[:trailers] ? "#{options[:height] || 3}m" : nil,
        vehicleWeight: options[:weight] ? "#{options[:weight]}m" : nil,
        limitedWeight: options[:weight] ? "#{options[:weight]}m" : nil,
        # disabledEquipped:
        passengersCount: 1,
        # tiresCount: 8, # Default 4
        # commercial:
        shippedHazardousGoods: here_hazardous_map[options[:hazardous_goods]] == :explosive ? 1 : here_hazardous_map[options[:hazardous_goods]] ? 2 : nil,
        # heightAbove1stAxle:
        # departure:
        # If departure is given, then each route detail is a comma separated struct of link id,seconds left to destination. Otherwise, each route detail is only a link id.
        route: link_ids.join(';'), # FIXME add seconds if departure
        detail: 1,
        rollup: 'total,tollsys,country', # none(per_links),total,tollsys(toll_system_summary),country(per_contries),country;tollsys(per_contries_and_toll_sys)
        currency: options[:currency],
      }.delete_if{ |k, v| v.nil? }
      response = get(@url_tce, '2/tollcost', params)

      if response && response['totalCost']
        response['totalCost']['amountInTargetCurrency']
      end
    end

    def route(locs, dimension, departure, arrival, language, with_geometry, options = {})
      # Cache defined inside private get method
      params = {
        mode: here_mode(dimension.to_s.split('_').collect(&:to_sym), @mode, options),
        departure: departure,
        arrival: arrival,
        avoidAreas: here_avoid_areas(options[:speed_multiplier_area]),
        alternatives: 0,
        resolution: 1,
        language: language,
        representation: with_geometry || options[:toll_costs] ? 'display' : 'overview',
        routeAttributes: 'summary' + (with_geometry ? ',shape' : ''),
        truckType: @mode,
        trailersCount: options[:trailers], # Truck routing only, number of trailers.
        limitedWeight: options[:weight], # Truck routing only, vehicle weight including trailers and shipped goods, in tons.
        weightPerAxle: options[:weight_per_axle], # Truck routing only, vehicle weight per axle in tons.
        height: options[:height], # Truck routing only, vehicle height in meters.
        width: options[:width], # Truck routing only, vehicle width in meters.
        length: options[:length], # Truck routing only, vehicle length in meters.
        shippedHazardousGoods: here_hazardous_map[options[:hazardous_goods]], # Truck routing only, list of hazardous materials.
        #tunnelCategory : # Specifies the tunnel category to restrict certain route links. The route will pass only through tunnels of a les
        legAttributes: options[:toll_costs] ? 'maneuvers,waypoint,length,travelTime,links' : nil,
        # maneuverAttributes: options[:toll_costs] ? 'link' : nil, # links are already returned in legs
        linkAttributes: options[:toll_costs] && !with_geometry ? 'speedLimit' : nil, # Avoid shapes
      }.delete_if{ |k, v| v.nil? }
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
        infos = {
          total_distance: s['distance'],
          total_time: (s['trafficTime'] * 1.0 / (options[:speed_multiplier] || 1)).round(1),
          start_point: locs[0].reverse,
          end_point: locs[-1].reverse
        }
        if options[:toll_costs]
          infos[:total_toll_costs] = toll_costs(r['leg'].flat_map{ |l|
              l['link'].map{ |ll| ll['linkId'] }
            }.compact, departure, options)
        end

        ret[:features] = [{
          type: 'Feature',
          properties: {
            router: infos
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

      # In addition of cache defined inside private get method
      key = Digest::MD5.hexdigest(Marshal.dump([srcs, dsts, dimension, departure, arrival, language, options]))
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

        lats = (srcs + dsts).minmax_by{ |p| p[0] }
        lons = (srcs + dsts).minmax_by{ |p| p[1] }
        dist = distance([lats[1][0], lons[1][1]], [lats[0][0], lons[0][1]])
        coef_distance = 7 - [dist / 200, 6.0].min # 100km: 7, 1200km: 2, 1400km: 1

        srcs_split = [100 / [(dsts.size / coef_distance).ceil, 100].min, (1000 / srcs.size.to_f).ceil].min
        dsts_split = dsts_max = [100, dsts.size].min
        srcs_split = [srcs_split, 15].min if srcs_split * dsts_split > 99

        result = {
          time: Array.new(srcs.size) { Array.new(dsts.size) },
          distance: Array.new(srcs.size) { Array.new(dsts.size) }
        }

        dim = dimension.to_s.split('_').collect(&:to_sym)

        commons_param = {
          mode: here_mode(dim, @mode, options),
          departure: departure,
          avoidAreas: here_avoid_areas(options[:speed_multiplier_area]),
          truckType: @mode,
          summaryAttributes: dim.collect{ |d| d == :time ? 'traveltime' : d == :distance ? 'distance' : nil }.compact.join(','),
          trailersCount: options[:trailers], # Truck routing only, number of trailers.
          limitedWeight: options[:weight], # Truck routing only, vehicle weight including trailers and shipped goods, in tons.
          weightPerAxle: options[:weight_per_axle], # Truck routing only, vehicle weight per axle in tons.
          height: options[:height], # Truck routing only, vehicle height in meters.
          width: options[:width], # Truck routing only, vehicle width in meters.
          length: options[:length], # Truck routing only, vehicle length in meters.
          shippedHazardousGoods: here_hazardous_map[options[:hazardous_goods]], # Truck routing only, list of hazardous materials.
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
            rr ? (rr / (options[:speed_multiplier] || 1)).round : nil
          }
        }
      }

      if dimension == :time_distance
        ret[:matrix_distance] = result[:distance].collect { |r|
          r.collect { |rr|
            rr ? (rr / (options[:speed_multiplier] || 1)).round : nil
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

    def here_mode(dimension, mode, options)
      "#{dimension[0] == :time ? 'fastest' : 'shortest'};#{@mode};traffic:#{options[:traffic] ? 'enabled' : 'disabled'}#{!options[:motorway] ? ';motorway:-3' : !options[:toll] ? ';tollroad:-3' : ''}"
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
        rescue RestClient::Exception => e
          error = JSON.parse(e.response)
          if error['type'] == 'ApplicationError'
            additional_data = error['AdditionalData'] || error['additionalData']
            if additional_data
              if additional_data.include?({'key' => 'error_code', 'value' => 'NGEO_ERROR_GRAPH_DISCONNECTED'}) ||
                additional_data.include?({'key' => 'error_code', 'value' => 'NGEO_ERROR_GRAPH_DISCONNECTED_CHECK_OPTIONS'})
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

    def here_hazardous_map
      {
        explosive: :explosive,
        gas: :gas,
        flammable: :flammable,
        combustible: :combustible,
        organic: :organic,
        poison: :poison,
        radio_active: :radioActive,
        corrosive: :corrosive,
        poisonous_inhalation: :poisonousInhalation,
        harmful_to_water: :harmfulToWater,
        other: :other
      }
    end

    def distance(src, dst)
      dtor = Math::PI/180
      r = 6378.14

      rlat1 = src[0] * dtor
      rlon1 = src[1] * dtor
      rlat2 = dst[0] * dtor
      rlon2 = dst[1] * dtor

      dlon = rlon1 - rlon2
      dlat = rlat1 - rlat2

      a = (Math::sin(dlat/2) ** 2) + Math::cos(rlat1) * Math::cos(rlat2) * (Math::sin(dlon/2) ** 2)
      c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
      d = r * c

      d
    end
  end
end

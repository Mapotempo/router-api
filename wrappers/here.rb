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
require 'pycall/import'

module Wrappers
  class Here < Wrapper

    def initialize(cache, hash = {})
      super(cache, hash)
      @url_router = 'https://router.hereapi.com'
      @url_matrix = 'https://matrix.route.api.here.com/routing'
      @url_isoline = 'https://isoline.router.hereapi.com'
      @url_tce = 'https://tce.api.here.com'
      @api_key = hash[:api_key]
      @mode = hash[:mode]
      @flexpolyline = PyCall.import_module('flexpolyline')
    end

    # Declare available router options for capability operation
    # Here api supports most of options... remove unsupported options below
    (OPTIONS - [:speed_multiplier_area, :max_walk_distance, :approach, :snap, :with_summed_by_area]).each do |s|
      define_method("#{s}?") do
        ![:trailers, :weight, :weight_per_axle, :height, :width, :length, :hazardous_goods, :strict_restriction].include?(s) || @mode == 'truck'
      end
    end

    # https://developer.here.com/documentation/routing-api/api-reference-swagger.html
    def route(locs, dimension, departure, arrival, language, with_geometry, options = {})
      # Cache defined inside private get method
      params = {
        arrivalTime: arrival,
        avoid: { # Avoid routes that violate certain features or that go through geographical bounding boxes
          areas: here_avoid_areas(options[:speed_multiplier_area]),
          features: avoid_features(options)
        }.delete_if { |_k, v| v.nil? },
        currency: 'EUR', # required to get converted prices for tolls etc.
        departureTime: departure,
        destination: locs.last.join(','), # {lat},{lng}
        lang: language, # Specifies the preferred language of the response
        origin: locs.first.join(','), # {lat},{lng}
        return: define_return(options),
        routingMode: routing_mode(dimension),
        spans: define_spans(options, with_geometry), # Defines which attributes are included in the response spans
        transportMode: transport_mode,
        truck: truck_parameters(options),
        via: locs.slice(1..-2).join(','), # {lat},{lng}
      }.delete_if { |_k, v| v.nil? || v.empty? }

      request = get(@url_router, 'v8/routes', params, options[:strict_restriction])

      ret = {
        type: 'FeatureCollection',
        router: {
          licence: 'HERE',
          attribution: 'HERE'
        },
        features: []
      }

      if request && request['routes'].present?
        sections = request['routes'][0]['sections'][0] # @todo why only first ? Test with via points
        infos = {
          total_distance: sections['summary']['length'],
          total_time: (sections['summary'][options[:traffic] ? 'duration' : 'baseDuration'] * 1.0 / (options[:speed_multiplier] || 1)).round(1),
          start_point: locs[0].reverse,
          end_point: locs[-1].reverse
        }
        if options[:toll_costs]
          infos[:total_toll_costs] = sections['tolls'].map{ |to|
            to['fares'].map{ |fa| fa['price']['value'] }
          }.flatten.sum
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
            coordinates: flexpolyline_decode(sections['polyline'])
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

      dim = dimension.to_s.split('_').collect(&:to_sym)

      # In addition of cache defined inside private get method
      key = Digest::MD5.hexdigest(Marshal.dump([srcs, dsts, dimension, departure, arrival, language, options.except(:speed_multiplier)]))
      result = @cache.read(key)
      if !result

        # From Here "Matrix Routing API Developer's Guide"
        # Recommendations for Splitting Matrixes
        # The best way to split a matrix request is to split it into parts with only few start positions and many
        # destinations. The number of the start positions should be between 3 and 15, depending on the size
        # of the area covered by the matrix. The matrices should be split into requests sufficiently small to
        # ensure a response time of 60 seconds each. The number of the destinations in one request is limited
        # to 100.

        # Request should not contain more than 15 starts per request / 100 combinaisons

        lats = (srcs + dsts).minmax_by{ |p| p[0] }
        lons = (srcs + dsts).minmax_by{ |p| p[1] }
        dist_km = RouterWrapper::Earth.distance_between(lons[1][1], lats[1][0], lons[0][1], lats[0][0]) / 1000.0
        dsts_split = dsts_max = [100, dsts.size].min
        srcs_split = max_srcs(dist_km)

        Api::Root.logger.debug("Options: #{options}")
        Api::Root.logger.debug("dist_km: #{dist_km}, srcs_split: #{srcs_split}, dsts_split: #{dsts_split}")

        params = {
          mode: here_mode(dim, @mode, options),
          departure: departure,
          avoidAreas: here_avoid_areas(options[:speed_multiplier_area]),
          truckType: @mode == 'truck' ? 'truck' : nil,
          summaryAttributes: dim.collect{ |d| d == :time ? 'traveltime' : d == :distance ? 'distance' : nil }.compact.join(','),
          trailersCount: options[:trailers], # Truck routing only, number of trailers.
          limitedWeight: options[:weight], # Truck routing only, vehicle weight including trailers and shipped goods, in tons.
          weightPerAxle: options[:weight_per_axle], # Truck routing only, vehicle weight per axle in tons.
          height: options[:height], # Truck routing only, vehicle height in meters.
          width: options[:width], # Truck routing only, vehicle width in meters.
          length: options[:length], # Truck routing only, vehicle length in meters.
          shippedHazardousGoods: here_hazardous_map[options[:hazardous_goods]], # Truck routing only, list of hazardous materials.
          # truckRestrictionPenalty: here_strict_restriction(options[:strict_restriction]),
          # matrixAttributes: options[:strict_restriction] == 'soft' ? 'notes' : nil
        }

        result = split_matrix(srcs_split, dsts_split, dsts_max, srcs, dsts, params, options[:strict_restriction])

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

      ret[:matrix_distance] = result[:distance] if dim.include?(:distance)

      ret
    end

    # https://developer.here.com/documentation/isoline-routing-api/api-reference-swagger.html
    def isoline(loc, dimension, size, departure, _language, options = {})
      # Cache defined inside private get method
      params = {
        departureTime: departure,
        origin: "#{loc[0]},#{loc[1]}", # required <latitude>,<longitude>
        range: range(dimension, size, options),
        routingMode: routing_mode(dimension),
        transportMode: transport_mode, # required
        truck: truck_parameters(options)
      }.delete_if { |_k, v| v.nil? }

      request = get(@url_isoline, 'v8/isolines', params)

      ret = {
        type: 'FeatureCollection',
        router: {
          licence: 'HERE',
          attribution: 'HERE'
        },
        features: []
      }

      if request && request['isolines']
        isoline = request['isolines'][0]
        ret[:features] = isoline['polygons'].map{ |polygon|
          {
            type: 'Feature',
            properties: {},
            geometry: {
              type: 'Polygon',
              coordinates: [flexpolyline_decode(polygon['outer'])]
            }
          }
        }
        ret
      end
    end

    private

    def flexpolyline_decode(string)
      # Need to revert lat,lng
      @flexpolyline.decode(string).map{ |tuple| [tuple[1], tuple[0]] }
    end

    # Array of strings (Return)
    # polyline, actions, instructions, summary, travelSummary, mlDuration, typicalDuration, turnByTurnActions, elevation, routeHandle, passthrough, incidents, routingZones, tolls
    def define_return(options)
      rtrn = ['summary']
      rtrn << 'tolls' if options[:toll_costs]
      rtrn << 'polyline' if transport_mode == 'car' || transport_mode == 'truck'
      rtrn.join(',')
    end

    # Defines which attributes are included in the response spans
    # walkAttributes, streetAttributes, carAttributes, truckAttributes, scooterAttributes, names, length, duration, baseDuration, typicalDuration, countryCode, functionalClass, routeNumbers, speedLimit, maxSpeed, dynamicSpeedInfo, segmentId, segmentRef, consumption, routingZones, notices, incidents
    def define_spans(options, with_geometry = false)
      spans = []
      if options[:toll_costs]
        spans << 'length'
        spans << 'speedLimit' unless with_geometry
      end

      case transport_mode
      when 'car'
        spans << 'carAttributes '
      when 'truck'
        spans << 'truckAttributes'
      end
      spans.join(',')
    end

    def transport_mode
      ['car', 'truck', 'pedestrian', 'bicycle', 'scooter', 'taxi', 'bus'].include?(@mode) ? @mode : 'car'
    end

    def routing_mode(dimension)
      dimension == :time ? 'fast' : 'short'
    end

    def range(dimension, size, options)
      {
        type: dimension,
        values: dimension == :time ? (size * (options[:speed_multiplier] || 1)).round : size
      }
    end

    def truck_parameters(options)
      {
        grossWeight: options[:weight]&.ceil, # Truck routing only, vehicle weight including trailers and shipped goods, in tons.
        height: options[:height]&.ceil, # Truck routing only, vehicle height in meters.
        length: options[:length]&.ceil, # Truck routing only, vehicle length in meters.
        shippedHazardousGoods: here_hazardous_map[options[:hazardous_goods]], # Truck routing only, list of hazardous materials.
        trailerCount: options[:trailers],
        type: @mode == 'truck' ? 'straight' : nil, # can be tractor too
        weightPerAxle: options[:weight_per_axle], # Truck routing only, vehicle weight per axle in tons.
        width: options[:width]&.ceil, # Truck routing only, vehicle width in meters.
      }.delete_if{ |_k, v| v.blank? }
    end

    # @todo remove ?
    def here_dimension_distance?
      if @mode == 'truck'
        false # not supported in 7.2 for truck
      else
        true
      end
    end

    # @todo remove ?
    def here_mode(dimension, mode, options)
      "#{dimension[0] == :time ? 'fastest' : 'shortest'};#{@mode};traffic:#{options[:traffic] ? 'enabled' : 'disabled'}#{!options[:motorway] ? ';motorway:-3' : !options[:toll] ? ';tollroad:-3' : ''}"
    end

    def avoid_features(options)
      if options[:motorway]
        'tollRoad' unless options[:toll] # old tollroad:-3
      else
        'controlledAccessHighway' # old motorway:-3
      end
    end

    # @todo test it returns bounding boxes with the following format
    # @return format => {shape1}|{shape2}|{shape3}
    # shape => bbox:{west},{south},{east},{north}
    def here_avoid_areas(areas)
      return unless areas

      # Keep only avoid area
      areas.select{ |k, v| v == 0 }.collect{ |area, _v|
        lats = area.minmax_by{ |p| p[0] }
        lons = area.minmax_by{ |p| p[1] }
        "bbox:#{lons[0][1]},#{lats[0][0]},#{lons[1][1]},#{lats[1][0]}"
      }.join('|')
    end

    def get(url_base, object, params = {}, strict_restriction = false)
      url = "#{url_base}/#{object}"
      params = { apiKey: @api_key }.merge(params).delete_if{ |_k, v| v.blank? }
      key = [:here, :request, Digest::MD5.hexdigest(Marshal.dump([url, params.to_a.sort_by{ |i| i[0].to_s }]))]
      request = @cache.read(key)

      unless request
        begin
          response = RestClient.get(url, params: params)
        rescue RestClient::Exception => e
          error = JSON.parse(e.response)

          case error['status']
          when 400
            raise RouterWrapper::InvalidArgumentError.new(error), "Here, #{error['title']}: #{error['cause']} (#{error['action']})"
          end

          Api::Root.logger.info [url, params]
          Api::Root.logger.info error.inspect
          raise ['Here', error].compact.join(' ')
        end

        request = handle_notices(JSON.parse(response), params, strict_restriction)
        @cache.write(key, request)
      end

      request
    end

    def split_matrix(srcs_split, dsts_split, dsts_max, srcs, dsts, params, strict_restriction)
      result = {
        time: Array.new(srcs.size) { Array.new(dsts.size) },
        distance: Array.new(srcs.size) { Array.new(dsts.size) }
      }

      srcs_start = 0
      nb_request = 0
      while srcs_start < srcs.size do
        param_start = {}
        srcs_start.upto([srcs_start + srcs_split - 1, srcs.size - 1].min).each{ |i|
          param_start["start#{i - srcs_start}"] = srcs[i].join(',')
        }
        dsts_start = 0
        dsts_split = [dsts_split * 2, dsts_max].min
        while dsts_start < dsts.size do
          nb_request += 1
          Api::Root.logger.debug("(nb_request: #{nb_request}) srcs_start: #{srcs_start}, dsts: #{dsts_start + dsts_split - 1} / #{dsts.size}")

          param_destination = {}
          dsts_start.upto([dsts_start + dsts_split - 1, dsts.size - 1].min).each{ |i|
            param_destination["destination#{i - dsts_start}"] = dsts[i].join(',')
          }
          request = get(@url_matrix, '7.2/calculatematrix', params.dup.merge(param_start).merge(param_destination))

          if request && (dsts_split <= 2 || request['response']['matrixEntry'].select{ |e| e['status'] == 'failed' }.size < param_start.size * param_destination.size / 2)
            request['response']['matrixEntry'].each{ |e|
              s = e['summary']
              if s && (s.key?('travelTime') || s.key?('distance'))
                result[:time][srcs_start + e['startIndex']][dsts_start + e['destinationIndex']] = s.key?('travelTime') ? s['travelTime'].round : nil
                result[:distance][srcs_start + e['startIndex']][dsts_start + e['destinationIndex']] = s.key?('distance') ? s['distance'].round : nil
              elsif e['status'] == 'failed'
                # FIXME: replace by truckRestrictionPenalty/matrixAttributes when available in matrix
                if !strict_restriction
                  nb_request += 1
                  Api::Root.logger.debug("Status failed, getting a route (waypoint0: 'geo!#{param_start['start' + e['startIndex'].to_s]}', waypoint1: 'geo!#{param_destination['destination' + e['destinationIndex'].to_s]}'), strict_restriction: #{strict_restriction}  (nb_request: #{nb_request}) srcs_start: #{srcs_start}, dsts: #{dsts_start + dsts_split - 1} / #{dsts.size}")

                  route = get(@url_router, 'v8/routes', params.select{ |k, _v|
                    [
                      :mode,
                      :departure,
                      :arrival,
                      :avoidAreas,
                      :language,
                      :truckType,
                      :trailersCount,
                      :limitedWeight,
                      :weightPerAxle,
                      :height,
                      :width,
                      :length,
                      :shippedHazardousGoods,
                      #:tunnelCategory,
                    ].include? k
                  }.merge({
                    alternatives: 0,
                    resolution: 1,
                    representation: 'overview',
                    routeAttributes: 'summary,notes',
                    truckRestrictionPenalty: 'soft',
                    waypoint0: 'geo!' + param_start['start' + e['startIndex'].to_s],
                    waypoint1: 'geo!' + param_destination['destination' + e['destinationIndex'].to_s],
                  }))
                  s = route && !route['response']['route'].empty? && route['response']['route'][0]['summary']
                  if s
                    time_attribute = params[:mode].include?('traffic:enabled') ? 'trafficTime' : 'travelTime'
                    result[:time][srcs_start + e['startIndex']][dsts_start + e['destinationIndex']] = s.key?(time_attribute) ? s[time_attribute].round : nil
                    result[:distance][srcs_start + e['startIndex']][dsts_start + e['destinationIndex']] = s.key?('distance') ? s['distance'].round : nil
                  end
                else
                  Api::Root.logger.debug("Status failed, request set to nil (waypoint0: 'geo!#{param_start['start' + e['startIndex'].to_s]}'', waypoint1: 'geo!#{param_destination['destination' + e['destinationIndex'].to_s]}''), strict_restriction: #{strict_restriction} (nb_request: #{nb_request}) srcs_start: #{srcs_start}, dsts: #{dsts_start + dsts_split - 1} / #{dsts.size}")
                  Api::Root.logger.debug("#{@url_matrix}/7.2/calculatematrix.json?#{params.dup.merge(param_start).merge({app_id: @app_id, app_code: @app_code}).merge(param_destination).reject{|mp, vl| vl.nil?}.to_query}")
                  request = nil
                  break
                end
              end
            }
          else
            Api::Root.logger.debug('Request failed')
            Api::Root.logger.debug("#{@url_matrix}/7.2/calculatematrix.json?#{params.dup.merge(param_start).merge({app_id: @app_id, app_code: @app_code}).merge(param_destination).reject{|mp, vl| vl.nil?}.to_query}")
            request = nil
          end

          # in some cases, matrix cannot be computed (cancelled) or is incomplete => try to decrease matrix size
          if !request && dsts_split > 2
            dsts_start = [dsts_start - dsts_split, 0].max
            dsts_split = (dsts_split / 2).ceil
            Api::Root.logger.debug("Resplit dsts_split to #{dsts_split}")
          else
            dsts_start += dsts_split
          end
        end

        srcs_start += srcs_split
      end

      result
    end

    def here_hazardous_map
      {
        explosive: :explosive,
        gas: :gas,
        flammable: :flammable,
        combustible: :combustible,
        organic: :organic,
        poison: :poison,
        radio_active: :radioactive,
        corrosive: :corrosive,
        poisonous_inhalation: :poisonousInhalation,
        harmful_to_water: :harmfulToWater,
        other: :other
      }
    end

    ##
    # < 1000km: 15, 1500km: 10, 2000km : 5
    def max_srcs(dist_km)
      if dist_km <= 1_000
        15
      else
        [25 - (dist_km / 100).floor, 1].max
      end
    end

    # V8 returns errors and restrictions in notices with a http 200 status
    def handle_notices(body, params, strict_restriction)
      notices = body['notices'] || body['routes']&.map{|rt| rt['sections'].map{|se| se['notices']}}&.flatten.compact
      coordinates = "#{params[:origin]}, #{params[:destination]}"

      notices&.each do |notice|
        case notice['code']
        when 'couldNotMatchOrigin'
          raise UnreachablePointError.new(notice['title']), "Here, couldNotMatchOrigin (#{coordinates})"
        when 'violatedVehicleRestriction'
          Api::Root.logger.debug("HERE, #{notice['title']}, #{notice['code']} (#{coordinates})")
          return {} if strict_restriction
        end
      end

      body

      # if error['type'] == 'ApplicationError'
      #   additional_data = error['AdditionalData'] || error['additionalData']
      #   if additional_data
      #     if additional_data.include?({ 'key' => 'error_code', 'value' => 'NGEO_ERROR_GRAPH_DISCONNECTED' }) ||
      #         additional_data.include?({ 'key' => 'error_code', 'value' => 'NGEO_ERROR_GRAPH_DISCONNECTED_CHECK_OPTIONS' })
      #       return
      #     elsif additional_data.include?({ 'key' => 'error_code', 'value' => 'NGEO_ERROR_ROUTING_CANCELLED' })
      #       return
      #     elsif additional_data.include?({ 'key' => 'error_code', 'value' => 'NGEO_ERROR_ROUTE_NO_START_POINT' })
      #       raise UnreachablePointError.new(error), "Here, UnreachablePoint: #{params.keys.grep(/waypoint/).map{|key| params[key]}}"
      #     elsif error['subtype'] == 'InvalidInputData'
      #       raise RouterWrapper::InvalidArgumentError.new(error), "Here, #{error['subtype']}: #{error['details']} (#{additional_data.first['key']} : #{additional_data.first['value']})"
      #     elsif error['subtype'] == 'NoRouteFound'
      #       raise RouterWrapper::NoRouteFound.new(error), "Here, #{error['subtype']}: #{params.keys.grep(/waypoint/).map{|key| params[key]}}"
      #     else
      #       raise
      #     end
      #   end
      # end
    end
  end
end

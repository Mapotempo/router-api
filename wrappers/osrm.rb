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
require './lib/earth'

require 'uri'
require 'rest-client'
require 'addressable'
#RestClient.log = $stdout
require 'polylines'

module Wrappers
  class Osrm < Wrapper
    TIMEOUT_DEFAULT_OPEN ||= 3
    TIMEOUT_DEFAULT ||= 60
    TIMEOUT_DEFAULT_MATRIX ||= 90 # OSRM takes 55sec for a 5kx5k matrix 1000km diagonal

    def initialize(cache, hash = {})
      super(cache, hash)
      @url_trace = {
        time: hash[:url_time],
        distance: hash[:url_distance]
      }.delete_if { |k, v| v.nil? }
      @url_matrix = {
        time: hash[:url_time],
        time_distance: hash[:url_time],
        distance: hash[:url_distance],
        distance_time: hash[:url_distance]
      }.delete_if { |k, v| v.nil? }
      @url_isoline = {
        time: hash[:url_isochrone],
        distance: hash[:url_isodistance]
      }.delete_if { |k, v| v.nil? }
      @licence = hash[:licence]
      @attribution = hash[:attribution]
      @track = hash[:track] || false
      @motorway = hash[:motorway] || false
      @toll = hash[:toll] || false
      @low_emission_zone = hash[:low_emission_zone] || false
      @large_light_vehicle = hash[:large_light_vehicle] || false
      @area_mapping = hash[:area_mapping] || {}
      @whitelist_classes = hash[:whitelist_classes] || []
      @with_summed_by_area = hash[:with_summed_by_area] || false
      @exclude = hash[:exclude] || []
    end

    # Declare available router options for capability operation
    def speed_multiplier?
      true
    end

    def approach?
      true
    end

    def track?
      @track
    end

    def motorway?
      @motorway
    end

    def toll?
      @toll
    end

    def low_emission_zone?
      @low_emission_zone
    end

    def large_light_vehicle?
      @large_light_vehicle
    end

    def with_summed_by_area?
      @with_summed_by_area
    end

    def route_dimension
      @url_trace.keys
    end

    def route(locs, dimension, _departure, _arrival, language, with_geometry, options = {})
      options[:format] ||= 'json'
      options[:precision] ||= 5
      key = [:osrm, :route, Digest::MD5.hexdigest(Marshal.dump([@url_trace[dimension], dimension, with_geometry, locs, language, options.except(:speed_multiplier)]))]

      json = @cache.read(key)
      if !json
        params = {
          alternatives: false,
          steps: options[:with_summed_by_area] || false,
          annotations: false,
          geometries: options[:format] != 'geojson' && {5 => :polyline, 6 => :polyline6}[options[:precision]] || :geojson,
          overview: with_geometry ? :full : false,
          continue_straight: false,
          generate_hints: false,
          approaches: options[:approach] == :curb ? (['curb'] * locs.size).join(';') : nil,
          exclude: (@exclude + [
            toll? && options[:toll] == false ? 'toll' : nil,
            motorway? && options[:motorway] == false ? 'motorway' : nil,
            track? && options[:track] == false ? 'track' : nil,
            low_emission_zone? && options[:low_emission_zone] == false ? 'lowEmissionZone' : nil,
            large_light_vehicle? && options[:large_light_vehicle] == false ? 'notForLargeVehicule' : nil,
          ].compact).join(','),
        }.delete_if { |k, v| v.nil? || v == '' }
        coordinates = locs.collect{ |loc| ['%f' % loc[1], '%f' % loc[0]].join(',') }.join(';')
        request = RestClient::Request.execute(
          method: :get,
          url: "#{@url_trace[dimension]}/route/v1/driving/#{coordinates}?#{params.to_query}",
          open_timeout: TIMEOUT_DEFAULT_OPEN,
          read_timeout: TIMEOUT_DEFAULT,
          payload: { accept: :json }
        ) { |response, request, result, &block|
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
          raise 'OSRM request fails with: ' + (json['code'] || '') + ' ' + (json['message'] || '')
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
      if options[:with_summed_by_area]
        (json['routes'] || []).each_with_index{ |route, index|
          ret[:features][index][:properties][:router][:summed_by_area] = distance_by_way_type(route, options[:precision])
        }
      end

      if with_geometry
        geojson = options[:format] == 'geojson' || ![5, 6].include?(options[:precision])
        (json['routes'] || []).each_with_index{ |route, index|
          ret[:features][index][:geometry] = {
            type: 'LineString',
            coordinates: geojson && route['geometry']['coordinates'] || nil,
            polylines: !geojson && route['geometry'] || nil
          }
        }
      end

      ret
    end

    def matrix_dimension
      @url_matrix.keys
    end

    def matrix(srcs, dsts, dimension, _departure, _arrival, language, options = {})
      dim1, dim2 = dimension.to_s.split('_').collect(&:to_sym)
      key = [:osrm, :matrix, Digest::MD5.hexdigest(Marshal.dump([@url_matrix[dim1], dim1, dim2, srcs, dsts, options.except(:speed_multiplier)]))]

      json = @cache.read(key)
      if !json
        concern = {
          annotations: ([[dim1, dim2].include?(:time) ? 'duration' : nil] + [[dim1, dim2].include?(:distance) ? 'distance' : nil]).compact.join(','),
          exclude: (@exclude + [options[:toll] == false ? 'toll' : nil, options[:motorway] == false ? 'motorway' : nil, options[:track] == false ? 'track' : nil, options[:large_light_vehicle] == false ? 'notForLargeVehicule' : nil, options[:low_emission_zone] == false ? 'lowEmissionZone' : nil].compact).join(',')
        }

        if srcs == dsts
          locs_uniq = srcs
          params = {
            approaches: options[:approach] == :curb ? (['curb'] * locs_uniq.size).join(';') : nil
          }.merge(concern)
        else
          locs_uniq = (srcs + dsts).uniq.sort_by{ |a, b| a + b }
          params = {
            sources: srcs.collect{ |d| locs_uniq.index(d) }.join(';'),
            destinations: dsts.collect{ |d| locs_uniq.index(d) }.join(';'),
            approaches: options[:approach] == :curb ? (['curb'] * locs_uniq.size).join(';') : nil
          }.merge(concern)
        end

        if locs_uniq.size == 1
          json = {
            'durations' => [[0]],
            'distances' => [[0]]
          }
        else
          uri = ::Addressable::URI.parse(@url_matrix[dim1])
          uri.path = '/table/v1/driving/polyline(' + Polylines::Encoder.encode_points(locs_uniq, 1e5) + ')'
          request = RestClient::Request.execute(
            method: :get,
            url: "#{uri.normalize.to_str}?#{params.delete_if { |k, v| v.nil? || v == '' }.to_query}",
            open_timeout: TIMEOUT_DEFAULT_OPEN,
            read_timeout: TIMEOUT_DEFAULT_MATRIX,
            payload: { accept: :json }
          ) { |response, request, result, &block|
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
        matrix_time: json['durations'] && json['durations'].collect { |r|
          r.collect { |rr|
            rr ? (rr * 1.0 / (options[:speed_multiplier] || 1)).round : nil
          }
        },
        matrix_distance: json['distances']
      }

      ret
    end

    def isoline_dimension
      @url_isoline.keys
    end

    def isoline(loc, dimension, size, _departure, language, options = {})
      key = [:osrm, :isoline, Digest::MD5.hexdigest(Marshal.dump([@url_isoline[dimension], dimension, loc, size, options]))]
      request = @cache.read(key)
      if !request
        params = {
          lat: loc[0],
          lng: loc[1],
          time: dimension == :time ? (size * (options[:speed_multiplier] || 1)).round(1) : nil,
          distance: dimension == :distance ? size : nil,
          approaches: options[:approach] == :curb ? (['curb'] * loc.size).join(';') : nil,
          exclude: (@exclude + [options[:toll] == false ? 'toll' : nil, options[:motorway] == false ? 'motorway' : nil, options[:track] == false ? 'track' : nil, options[:large_light_vehicle] == false ? 'notForLargeVehicule' : nil, options[:low_emission_zone] == false ? 'lowEmissionZone' : nil].compact).join(','),
        }.delete_if { |k, v| v.nil? || v == '' }
        begin
          request = RestClient::Request.execute(
            method: :get,
            url: "#{@url_isoline[dimension]}/0.1/isochrone?#{params.to_query}",
            open_timeout: TIMEOUT_DEFAULT_OPEN,
            read_timeout: TIMEOUT_DEFAULT,
            payload: { accept: :json }
          )
          @cache.write(key, request.body)
        rescue RestClient::ExceptionWithResponse => e
          e.message += " - #{@url_isoline}"
          raise e
        end
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

    def distance_by_way_type(route, precision)
      regrouped_classes = regroup_by_way_type(route, precision)
      available_classes = regrouped_classes.collect{ |g| {way_type: g[:way_type], distance: 0} }.uniq
      available_classes.select{ |item|
        # Sums distance of same way_type
        item[:distance] = regrouped_classes.collect{ |i|
          i[:distance] if i[:way_type] == item[:way_type]
        }.compact.inject(:+).round(1)
      }
    end

    def regroup_by_way_type(route, precision)
      route['legs'].collect{ |leg|
        leg['steps'].reject{ |step|
          step['maneuver']['type'] == 'arrive' # Reject unnecessary steps
        }.collect{ |step|
          classes = step['intersections'].collect{ |i| i['classes'] || [] }.flatten.compact.uniq
          if classes.count == 1 # All intersections have the same classes
            reverse_area_mapping(classes).collect{ |cls| { way_type: cls, distance: step['distance'] } }
          elsif step['intersections'].count == 1 # Only one intersection, use step distance
            reverse_area_mapping(step['intersections'][0]['classes']).collect{ |cls| { way_type: cls, distance: step['distance'] } }
          else
            classes_from_coordinates(step, precision)
          end
        }
      }.flatten
    end

    def reverse_area_mapping(classes)
      return [] if classes.nil?
      standard_classes = classes.select{ |c| @whitelist_classes.include?(c) }

      reversed_classes = @area_mapping.collect{ |m|
        mask = classes.select{ |c| c if m[:mask].include?(c) }
        m[:mapping][m[:mask].collect{ |st| mask.include?(st) }]
      }.compact

      reversed_classes.push(standard_classes).flatten
    end

    def classes_from_coordinates(step, precision)
      if step['geometry'].is_a? String
        coordinates = Polylines::Decoder.decode_polyline(step['geometry'], 10**precision)
      else
        coordinates = step['geometry']['coordinates'].collect(&:reverse)
      end

      intersections = step['intersections'].each{ |i| i['location'].reverse! }
      # Adds as last intersection the last coordinate if not exists
      if !same_coordinates?(intersections.last['location'], coordinates.last, precision)
        intersections << {'location' => coordinates.last}
      end

      from_index = 1
      intersections.reject{ |intersection|
        intersections.index(intersection).zero?
      }.collect{ |intersection|
        distance = 0
        same_coordinates = coordinates.select{ |coordinate|
          same_coordinates?(coordinate, intersection['location'], precision)
        }.flatten
        to_index = coordinates.index(same_coordinates) + 1

        (from_index...to_index).each{ |idx|
          distance += RouterWrapper::Earth.distance_between(coordinates[idx - 1][0], coordinates[idx - 1][1],
            coordinates[idx][0], coordinates[idx][1])
        }

        from_index = to_index
        reverse_area_mapping(intersections[intersections.index(intersection) - 1]['classes']).collect{ |cls|
          { way_type: cls, distance: distance }
        }
      }.flatten
    end

    def same_coordinates?(one, other, precision)
      one.collect{ |l| l.round(precision) } == other.collect{ |l| l.round(precision) }
    end
  end
end

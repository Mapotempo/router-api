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
  class HereTruck < Wrapper

    def initialize(app_id, app_code, mode)
      super()
      @url = 'https://route.nlp.nokia.com/routing'
      @app_id = app_id
      @app_code = app_code
      @mode = mode
    end

    def route(locs, departure, arrival, language, with_geometry)
      params = {
        mode: "fastest;#{@mode};traffic:disabled",
        alternatives: 0,
        resolution: 1,
        representation: 'display',
        routeAttributes: 'summary,shape',
        truckType: @mode,
        #limitedWeight: # Truck routing only, vehicle weight including trailers and shipped goods, in tons..
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

      if request
        r = request['response']['route'][0]
        s = r['summary']

        ret[:features] = [{
          type: 'Feature',
          properties: {
            router: {
              total_distance: s['distance'],
              total_time: s['trafficTime'],
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

    private

    def get(object, params = {})
      url = "#{@url}/#{object}.json"
      params = {app_id: @app_id, app_code: @app_code}.merge(params)

      begin
        response = RestClient.get(url, {params: params})
      rescue => e
        error = JSON.parse(e.response)
        if error['type'] == 'ApplicationError'
          additional_data = error['AdditionalData'] || error['additionalData']
          if additional_data
            if additional_data.include?({'key' => 'error_code', 'value' => 'NGEO_ERROR_ROUTE_NO_START_POINT'})
              raise 'Points are unreachable'
            else
              return
            end
          else
            raise [error['subtype'], error['Details']].join(' ')
          end
        else
          Rails.logger.info [url, params]
          Rails.logger.info error
        end
        raise ['Here', error['type']].join(' ')
      end
      JSON.parse(response)
    end
  end
end

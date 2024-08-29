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
require "redis"
require 'active_support'
require 'active_support/core_ext'
require 'byebug'
require 'dotenv'
require 'tmpdir'

require './wrappers/crow'
require './wrappers/here'
require './wrappers/here8'
require './wrappers/osrm'
require './wrappers/otp'

require './lib/cache_manager'

module RouterWrapper
  Dotenv.load('local.env', 'default.env')
  whitelist_classes = %w[toll motorway track]

  area_mapping = [
    {
      mask: %w[l1 l2],
      mapping: {
        [true, true]   => 'urban_dense',
        [true, false]  => 'urban',
        [false, false] => 'interurban',
        [false, true]  => 'water_body'
      }
    },
    {
      mask: %w[w1 w2 w3],
      mapping: {
        [true, true, true]    => 'trunk',
        [true, true, false]   => 'primary',
        [true, false, true]   => 'secondary',
        [true, false, false]  => 'tertiary',
        [false, true, true]   => 'residential',
        [false, true, false]  => 'minor',
        [false, false, true]  => nil,
        [false, false, false] => nil
      }
    }
  ]

  CACHE = CacheManager.new(ActiveSupport::Cache::NullStore.new)
  CROW = Wrappers::Crow.new(CACHE)

  url_time = 'http://router.project-osrm.org'
  url_distance = url_time
  OSRM = Wrappers::Osrm.new(CACHE, url_time: url_time, url_distance: url_distance, url_isochrone: 'http://localhost:1723', url_isodistance: 'http://localhost:1723', with_summed_by_area: true, licence: 'ODbL', attribution: '© OpenStreetMap contributors')

  OTP_BORDEAUX = Wrappers::Otp.new(CACHE, url: 'http://localhost:7000', router_id: 'idf', licence: 'ODbL', attribution: 'Bordeaux Métropole', area: 'Bordeaux', crs: 'EPSG:2154')

  HERE_TRUCK = Wrappers::Here.new(CACHE, app_id: ENV['HERE_APP_ID'], app_code: ENV['HERE_APP_CODE'], mode: 'truck')
  HERE_CAR = Wrappers::Here.new(CACHE, app_id: ENV['HERE_APP_ID'], app_code: ENV['HERE_APP_CODE'], mode: 'car')
  HERE8_CAR = Wrappers::Here8.new(CACHE, apikey: ENV['HERE8_APIKEY'], mode: 'car', over_400km: false)
  HERE8_TRUCK = Wrappers::Here8.new(CACHE, apikey: ENV['HERE8_APIKEY'], mode: 'truck', over_400km: false)

  PARAMS_LIMIT = { locations: 1_000_000 }.freeze

  REDIS_COUNT = ENV['REDIS_COUNT_HOST'] && Redis.new(host: ENV['REDIS_COUNT_HOST'])

  QUOTAS = [{ daily: 100000, monthly: 1000000, yearly: 10000000 }].freeze # Only taken into account if REDIS_COUNT

  @@c = {
    product_title: 'Router API',
    access_by_api_key: {
      file: './config/access.rb'
    },
    profiles: {
      standard: {
        route_default: :osrm,
        params_limit: PARAMS_LIMIT,
        quotas: QUOTAS, # Only taken into account if REDIS_COUNT
        route_default: :osrm,
        route: {
          osrm: [OSRM],
          crow: [CROW],
          otp: [OTP_BORDEAUX],
          truck: [HERE_TRUCK],
          here_car: [HERE_CAR],
          here8_car: [HERE8_CAR],
          here8_truck: [HERE8_TRUCK],
        },
        matrix: {
          crow: [CROW],
          osrm: [OSRM],
          otp: [OTP_BORDEAUX],
          truck: [HERE_TRUCK],
          here_car: [HERE_CAR],
          here8_car: [HERE8_CAR],
          here8_truck: [HERE8_TRUCK],
        },
        isoline: {
          crow: [CROW],
          osrm: [OSRM],
          otp: [OTP_BORDEAUX],
          truck: [HERE_TRUCK],
          here_car: [HERE_CAR],
          here8_car: [HERE8_CAR],
          here8_truck: [HERE8_TRUCK],
        }
      }
    },
    redis_count: REDIS_COUNT,
  }
end

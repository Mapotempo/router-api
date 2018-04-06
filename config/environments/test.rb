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
require 'active_support'
require 'byebug'
require 'dotenv/load'
require 'tmpdir'

require './wrappers/crow'
require './wrappers/osrm5'
require './wrappers/otp'
require './wrappers/here'

require './lib/cache_manager'

module RouterWrapper
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
  CROW = Wrappers::Crow.new(CACHE, boundary: 'poly/france-marseille.kml')
  OSRM5 = Wrappers::Osrm5.new(CACHE, url_time: 'http://localhost:5000', url_distance: 'http://localhost:5000', url_isochrone: 'http://localhost:1723', url_isodistance: 'http://localhost:1723', track: true, toll: true, motorway: true, area_mapping: area_mapping, whitelist_classes: whitelist_classes, licence: 'ODbL', attribution: '© OpenStreetMap contributors', area: 'Europe', boundary: 'poly/europe.kml')
  OTP_BORDEAUX = Wrappers::Otp.new(CACHE, url: 'http://localhost:8080', router_id: 'bordeaux', licence: 'ODbL', attribution: 'Bordeaux Métropole', area: 'Bordeaux', crs: 'EPSG:2154')
  HERE_TRUCK = Wrappers::Here.new(CACHE, app_id: ENV['HERE_APP_ID'], app_code: ENV['HERE_APP_CODE'], mode: 'truck')

  @@c = {
    product_title: 'Router Wrapper API',
    product_contact_email: 'tech@mapotempo.com',
    product_contact_url: 'https://github.com/Mapotempo/router-wrapper',
    profiles: [{
      api_keys: ['light'],
      services: {
        route_default: :crow,
        route: {
          crow: [CROW],
        },
        matrix: {
          crow: [CROW],
        },
        isoline: {
          crow: [CROW],
        }
      }
    }, {
      api_keys: ['demo'],
      services: {
        route_default: :crow,
        route: {
          crow: [CROW],
          osrm5: [OSRM5],
          otp: [OTP_BORDEAUX],
          here: [HERE_TRUCK],
        },
        matrix: {
          crow: [CROW],
          osrm5: [OSRM5],
          otp: [OTP_BORDEAUX],
          here: [HERE_TRUCK],
        },
        isoline: {
          crow: [CROW],
          osrm5: [OSRM5],
          otp: [OTP_BORDEAUX],
        }
      }
    }]
  }

  @@c[:api_keys] = Hash[@@c[:profiles].collect{ |profile|
    profile[:api_keys].collect{ |api_key|
      [api_key, profile[:services]]
    }
  }.flatten(1)]
end

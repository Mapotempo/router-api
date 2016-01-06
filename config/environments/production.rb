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
require 'active_support'
require 'tmpdir'

require './wrappers/demo'
require './wrappers/osrm'
require './wrappers/otp'
require './wrappers/here'

module RouterWrapper
  CACHE = ActiveSupport::Cache::FileStore.new(File.join(Dir.tmpdir, 'router'), namespace: 'router', expires_in: 60*60*24*1)

  DEMO = Wrappers::Demo.new(CACHE)
  OSRM = Wrappers::Osrm.new(CACHE, url: 'http://router.project-osrm.org', licence: 'ODbL', attribution: '© OpenStreetMap contributors')
  OTP_BORDEAUX = Wrappers::Otp.new(CACHE, url: 'http://localhost:8080', router_id: 'bordeaux', licence: 'ODbL', attribution: 'Bordeaux Métropole', area: 'Bordeaux')
  HERE_APP_ID = nil
  HERE_APP_CODE = nil
  HERE_TRUCK = Wrappers::Here.new(CACHE, app_id: HERE_APP_ID, app_code: HERE_APP_CODE, mode: 'truck')

  @@c = {
    product_title: 'Router Wrapper API',
    product_contact: 'frederic@mapotempo.com',
    services: {
      route_default: 'demo',
      route: {
        demo: [DEMO],
        osrm: [OSRM],
        otp: [OTP_BORDEAUX],
        here: [HERE_TRUCK],
      },
      matrix: {
        demo: [DEMO],
        osrm: [OSRM],
        otp: [OTP_BORDEAUX],
      },
      isoline: {}
    },
    api_keys: ['demo']
  }
end

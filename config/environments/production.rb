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
require './wrappers/osrm'
require './wrappers/ort'
require './wrappers/here'


module RouterWrapper
  OSRM_CAR_EUROPE = Wrappers::Osrm.new('', '')
  OSRM_CAR_URBAN_FRANCE = Wrappers::Osrm.new('', 'france.kml')
  OSRM_CAR_SHORTEST_FRANCE = Wrappers::Osrm.new('', 'france.kml')
  OSRM_PEDESTRIAN_FRANCE = Wrappers::Osrm.new('', 'france.kml')
  OSRM_CYCLE_FRANCE = Wrappers::Osrm.new('', 'france.kml')
  OTP_FRANCE_BORDEAUX = Wrappers::Here.new('', 'france-bordeaux.kml')
  OTP_FRANCE_NANTES = Wrappers::Here.new('', 'france-bordeaux.kml')
  HERE_TRUCK = Wrappers::Here.new('')

  @@c = {
    product_title: 'Router Wrapper API',
    product_contact: 'frederic@mapotempo.com',
    services: {
      route: {
        car: [OSRM_CAR_EUROPE],
        car_urban: [OSRM_CAR_URBAN_FRANCE],
        car_shortest: [OSRM_CAR_SHORTEST_FRANCE],
        pedestrian: [OSRM_PEDESTRIAN_FRANCE],
        cycle: [OSRM_CYCLE_FRANCE],
        public_transport: [OTP_FRANCE_BORDEAUX, OTP_FRANCE_NANTES],
        truck: [HERE_TRUCK],
      },
      matrix: {},
      isoline: {}
    },
    api_keys: ['demo']
  }
end

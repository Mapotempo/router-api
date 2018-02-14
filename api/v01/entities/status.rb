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

Dir['./api/v01/entities/status/*.rb'].each { |file| require file }

module Api
  module V01
    class Status
      def self.failure
        [
          {code: 400, model: Status400, message: 'Some required parameters are missing. E.g. you forgot to send one location'},
          {code: 401, model: Status401, message: 'Your api_key is not valid.'},
          {code: 404, model: Status404, message: 'Transportation mode is not supported. E.g. your api_key does not support this mode. Check capability operation to know authorized modes for your api key.'},
          {code: 405, model: Status405, message: 'Method not allowed. E.g. The api allows get and post method but you sent a put one.'},
          {code: 417, model: Status417, message: 'The given location is out of the supported area. E.g. in public_transport mode, your location is outside area served by city public transport.'},
          {code: 500, model: Status500, message: 'An internal server error occurred.'},
          {code: 204, model: Status204, message: 'The given location is unreachable.'}
        ]
      end
    end
  end
end

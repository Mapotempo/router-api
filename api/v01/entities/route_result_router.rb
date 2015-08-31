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
require './api/v01/entities/entity'
require './api/v01/entities/route_result_feature'


module Api
  module V01
    class RouteResultRouter < Grape::Entity
      def self.entity_name
        'RouteResultRouter'
      end

      expose_not_nil(:version, documentation: { type: String, desc: 'A semver.org compliant version number. Describes the version of the RoutingGeoJSON spec that is implemented by this instance.' })
      expose_not_nil(:licence, documentation: { type: String, desc: 'Default: null. The licence of the data. In case of multiple sources, and then multiple licences, can be an object with one key by source.' })
      expose_not_nil(:attribution, documentation: { type: String, desc: 'Default: null. The attribution of the data. In case of multiple sources, and then multiple attributions, can be an object with one key by source.' })
    end
  end
end

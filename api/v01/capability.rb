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
require 'polylines'

require './api/v01/api_base'
require './api/v01/entities/services_desc'

module Api
  module V01
    class Capability < APIBase
      content_type :xml, 'application/xml'
      content_type :json, 'application/json; charset=UTF-8'
      default_format :json

      resource :capability do
        desc 'Capability of current api', {
          detail: 'Return capability of all operations. For each operation, it will return availables modes (car, truck, public_transport...) and availables options for those modes.',
          nickname: 'capability',
          success: ServicesDesc
        }
        get do
          present RouterWrapper::desc(APIBase.profile(params[:api_key])), with: ServicesDesc
        end
      end
    end
  end
end

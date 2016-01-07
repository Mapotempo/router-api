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
require 'grape'
require 'grape-swagger'
require 'polylines'

require './api/v01/entities/services_desc'

module Api
  module V01
    class Capability < Grape::API
      content_type :xml, 'application/xml'
      content_type :json, 'application/json; charset=UTF-8'
      default_format :json
      version '0.1', using: :path

      resource :capability do
        desc 'Capability of current api', {
          nickname: 'capability',
          entity: ServicesDesc
        }
        get do
          present RouterWrapper::desc, with: ServicesDesc
        end
      end
    end
  end
end

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
      format :json
      version '0.1', using: :path

      rescue_from :all do |error|
        message = {error: error.class.name, detail: error.message}
        if ['development'].include?(ENV['APP_ENV'])
          message[:trace] = error.backtrace
          STDERR.puts error.message
          STDERR.puts error.backtrace
        end
        error!(message, 500)
      end

      resource :capability do
        desc 'Capability of current api', {
          nickname: 'capability',
          entity: Api::V01::ServicesDesc
        }
        get do
          begin
            present RouterWrapper::desc, with: Api::V01::ServicesDesc
          rescue UnreachablePointError => e
            error!(e.message, 400)
          end
        end
      end
    end
  end
end

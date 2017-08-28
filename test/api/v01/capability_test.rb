# Copyright © Mapotempo, 2016
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
require './test/test_helper'

require './api/root'

class Api::V01::CapabilityTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Api::Root
  end

  def test_capability
    get '/0.1/capability', { api_key: 'demo' }

    assert last_response.ok?, last_response.body

    capabilities = JSON.parse(last_response.body)
    capabilities['route'].each do |router|
      if router['mode'] == 'osrm5'
        assert router['support_speed_multiplier']
        assert router['support_approach']
        assert router['support_snap']

        assert !router['support_motorway']
        assert !router['support_toll']
        assert !router['support_trailers']
        assert !router['support_weight']
        assert !router['support_weight_per_axle']
        assert !router['support_height']
        assert !router['support_weight_per_axle']
        assert !router['support_width']
        assert !router['support_length']
        assert !router['support_hazardous_goods']
        assert !router['support_weight_per_axle']
        assert !router['support_toll_costs']
        assert !router['support_currency']
        assert !router['support_strict_restriction']
        assert !router['support_weight_per_axle']
      elsif router['mode'] == 'here'
        assert router['support_speed_multiplier']
        assert router['support_arrival']
        assert router['support_traffic']
        assert router['support_motorway']
        assert router['support_toll']
        assert router['support_trailers']
        assert router['support_weight']
        assert router['support_weight_per_axle']
        assert router['support_height']
        assert router['support_weight_per_axle']
        assert router['support_width']
        assert router['support_length']
        assert router['support_hazardous_goods']
        assert router['support_weight_per_axle']
        assert router['support_toll_costs']
        assert router['support_currency']
        assert router['support_strict_restriction']
        assert router['support_weight_per_axle']

        assert !router['support_max_walk_distance']
        assert !router['support_approach']
        assert !router['support_snap']
        assert !router['support_speed_multiplier_area']
        assert !router['support_speed_multiplicator_area']
      end
    end

  end
end

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

    response = JSON.parse(last_response.body)

    # Here
    (Wrappers::Wrapper::OPTIONS - [
      :speed_multiplier,
      :avoid_area,
      :speed_multiplier_area,
      :departure,
      :arrival,
      :traffic,
      :track,
      :motorway,
      :toll,
      :trailers,
      :weight,
      :weight_per_axle,
      :height,
      :width,
      :length,
      :hazardous_goods,
      :toll_costs,
      :currency,
      :strict_restriction]).each { |option|
        supports = []
        ['route', 'matrix', 'isoline'].each{ |op|
          supports << response[op].select{ |r| r['mode'] == 'here' }.map{ |r| r["support_#{option}"] }
        }
        assert_equal [false], supports.flatten.uniq, "support_#{option} is true for here"
    }

    # OTP
    (Wrappers::Wrapper::OPTIONS - [
      :speed_multiplier,
      :avoid_area,
      :speed_multiplier_area,
      :departure,
      :arrival,
      :traffic,
      :track,
      :motorway,
      :toll,
      :trailers,
      :weight,
      :weight_per_axle,
      :height,
      :width,
      :length,
      :hazardous_goods,
      :toll_costs,
      :currency,
      :approach,
      :snap,
      :strict_restriction,
      :with_summed_by_area]).each { |option|
        supports = []
        ['route', 'matrix', 'isoline'].each{ |op|
          supports << response[op].select{ |r| r['mode'] == 'otp' }.map{ |r| r["support_#{option}"] }
        }
        assert_equal [true], supports.flatten.uniq, "support_#{option} is false for otp"
    }

    # OSRM
    (Wrappers::Wrapper::OPTIONS - [
      :speed_multiplier,
      :avoid_area,
      :speed_multiplier_area,
      :departure,
      :arrival,
      :traffic,
      :snap,
      :trailers,
      :weight,
      :weight_per_axle,
      :height,
      :width,
      :length,
      :hazardous_goods,
      :max_walk_distance,
      :toll_costs,
      :currency,
      :strict_restriction]).each { |option|
        supports = []
        ['route', 'matrix', 'isoline'].each{ |op|
          supports << response[op].select{ |r| r['mode'] == 'osrm5' }.map{ |r| r["support_#{option}"] }
        }
        assert_equal [true], supports.flatten.uniq, "support_#{option} is false for osrm"
    }
  end
end

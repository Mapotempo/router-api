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
require './test/test_helper'

require './wrappers/here'

class Wrappers::HereTest < Minitest::Test

  def test_router
    here = RouterWrapper::HERE_TRUCK
    result = here.route([[49.610710, 18.237305], [47.010226, 2.900391]], nil, nil, 'en', true)
    assert 0 < result[:features].size
  end

  def test_router_disconnected
    here = RouterWrapper::HERE_TRUCK
    result = here.route([[-18.90928, 47.53381], [-16.92609, 145.75843]], nil, nil, 'en', true)
    assert_equal 0, result[:features].size
  end

  def test_router_no_route_point
    here = RouterWrapper::HERE_TRUCK
    assert_raises Wrappers::UnreachablePointError do
      result = here.route([[0, 0], [42.73295, 0.27685]], nil, nil, 'en', true)
    end
  end
end

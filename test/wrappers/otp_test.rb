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

require './wrappers/otp'

class Wrappers::OtpTest < Minitest::Test

  def test_router
    otp = RouterWrapper::OTP_BORDEAUX
    result = otp.route([[44.82641, -0.55674], [44.85284, -0.5393]], nil, nil, 'en', true)
    assert 0 < result[:features].size
  end

  def test_router_no_route
    otp = RouterWrapper::OTP_BORDEAUX
    result = otp.route([[-18.90928, 47.53381], [-16.92609, 145.75843]], nil, nil, 'en', true)
    assert 0 == result[:features].size
  end

  def test_router_square
    osrm = RouterWrapper::OTP_BORDEAUX
    vector = [[49.610710, 18.237305], [47.010226, 2.900391]]
    result = osrm.matrix(vector, vector, nil, nil, 'en')
    assert vector.size, result[:matrix].size
    assert vector.size, result[:matrix][0].size
  end

  def test_router_rectangular
    osrm = RouterWrapper::OTP_BORDEAUX
    src = [[49.610710, 18.237305], [47.010226, 2.900391]]
    dst = [[49.610710, 18.237305]]
    result = osrm.matrix(src, dst, nil, nil, 'en')
    assert dst.size, result[:matrix].size
    assert src.size, result[:matrix][0].size
  end
end

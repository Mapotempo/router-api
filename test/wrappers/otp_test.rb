# Copyright © Mapotempo, 2015-2016
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
    result = otp.route([[44.82641, -0.55674], [44.85284, -0.5393]], :time, nil, nil, 'en', true)
    assert 0 < result[:features].size
  end

  def test_router_no_route
    otp = RouterWrapper::OTP_BORDEAUX
    result = otp.route([[-18.90928, 47.53381], [-16.92609, 145.75843]], :time, nil, nil, 'en', true)
    assert 0 == result[:features].size
  end

  def test_router_with_max_walk_distance
    otp = RouterWrapper::OTP_BORDEAUX
    result_short = otp.route([[44.869571, -0.530927], [44.82641, -0.55674]], :time, nil, nil, 'en', true, max_walk_distance: 200)
    result_long = otp.route([[44.869571, -0.530927], [44.82641, -0.55674]], :time, nil, nil, 'en', true, max_walk_distance: 2000)
    assert result_short[:features].size != result_long[:features].size
  end

  def test_router_square
    osrm = RouterWrapper::OTP_BORDEAUX
    vector = [[44.82641, -0.55674], [44.85284, -0.5393]]
    result = osrm.matrix(vector, vector, :time, nil, nil, 'en')
    assert_equal vector.size, result[:matrix_time].size
    assert_equal vector.size, result[:matrix_time][0].size
  end

  def test_router_rectangular
    osrm = RouterWrapper::OTP_BORDEAUX
    src = [[44.82641, -0.55674], [44.85284, -0.5393]]
    dst = [[44.82641, -0.55674]]
    result = osrm.matrix(src, dst, :time, nil, nil, 'en')
    assert_equal src.size, result[:matrix_time].size
    assert_equal dst.size, result[:matrix_time][0].size
  end

  def test_isoline
    osrm = RouterWrapper::OTP_BORDEAUX
    result = osrm.isoline([44.82641, -0.55674], :time, 160, Time.now, 'en')
    assert 0 < result['features'].size
  end
end

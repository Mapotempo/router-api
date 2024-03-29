# Copyright © Mapotempo, 2021
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

class Api::V01::APIBaseTest < Minitest::Test
  def test_count_locations
    lat, lng = 1, 1
    assert_equal 2, Api::V01::APIBase.count_locations([[[lat, lng], [lat, lng]]])
    assert_equal 2, Api::V01::APIBase.count_locations([[lat, lng], [lat, lng]])
    assert_equal 2, Api::V01::APIBase.count_locations([lat, lng, lat, lng])
    assert_equal 2, Api::V01::APIBase.count_locations('lat,lng,lat,lng')
    assert_equal 2, Api::V01::APIBase.count_locations('lat,lng;lat,lng')
    assert_equal 2, Api::V01::APIBase.count_locations('lat,lng|lat,lng')
    error = assert_raises do
      Api::V01::APIBase.count_locations(nil)
    end
    assert_equal 'count_locations cannot be called with a nil object', error.message
  end

  def test_count_matrix_cells
    assert_equal 2, Api::V01::APIBase.count_matrix_cells(src: 'lat,lng,lat,lng', dst: 'lat,lng')
    assert_equal 144, Api::V01::APIBase.count_matrix_cells(src: 'lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng')
  end

  def test_limit_matrix_side_size
    assert_equal 2, Api::V01::APIBase.limit_matrix_side_size(src: 'lat,lng,lat,lng', dst: 'lat,lng')
    assert_equal 12, Api::V01::APIBase.limit_matrix_side_size(src: 'lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng,lat,lng')
  end

  def test_count_route_legs
    assert_equal 1, Api::V01::APIBase.count_route_legs(loc: '1,1,1,1')
    assert_equal 11, Api::V01::APIBase.count_route_legs(locs: '1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1') # single route
    assert_equal 2, Api::V01::APIBase.count_route_legs(locs: '1,1,1,1|1,1,1,1') # 2 routes
    assert_equal 7, Api::V01::APIBase.count_route_legs(locs: '1,1,1,1|1,1,1,1|1,1,1,1|1,1,1,1|1,1,1,1|1,1,1,1,1,1') # 6 routes
    assert_equal 2, Api::V01::APIBase.count_route_legs(locs: [[[1, 1], [1, 1]], [[1, 1], [1, 1]]]) # 2 routes
    assert_equal 3, Api::V01::APIBase.count_route_legs(locs: [[[1, 1], [1, 1], [1, 1], [1, 1]]]) # single route
    assert_equal 3, Api::V01::APIBase.count_route_legs(locs: [[[1, 1], [1, 1]], [[1, 1], [1, 1], [1, 1]]]) # 2 routes
    assert_equal 3, Api::V01::APIBase.count_route_legs(locs: [[[1, 1], [1, 1]], [[1, 1], [1, 1]], [[1, 1], [1, 1]]]) # 3 routes
  end
end

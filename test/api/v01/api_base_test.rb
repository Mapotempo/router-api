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
    assert 2, Api::V01::APIBase.count_locations([[[lat, lng], [lat, lng]]])
    assert 2, Api::V01::APIBase.count_locations([[lat, lng], [lat, lng]])
    assert 2, Api::V01::APIBase.count_locations([lat, lng, lat, lng])
    assert 2, Api::V01::APIBase.count_locations('lat,lng,lat,lng')
    assert 0, Api::V01::APIBase.count_locations(nil)
  end

  def test_count_matrix_locations
    assert 2, Api::V01::APIBase.count_matrix_locations(src: 'lat,lng,lat,lng', dest: 'lat,lng,lat,lng')
    assert 2, Api::V01::APIBase.count_matrix_locations(src: 'lat,lng,lat,lng')
  end

  def test_count_route_locations
    assert 2, Api::V01::APIBase.count_matrix_locations(loc: 'lat,lng,lat,lng')
    assert 2, Api::V01::APIBase.count_matrix_locations(locs: 'lat,lng,lat,lng')
  end
end

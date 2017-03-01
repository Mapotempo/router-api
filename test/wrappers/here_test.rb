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
    result = here.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true, {motorway: true, toll: true})
    assert 0 < result[:features].size
  end

  def test_router_without_motorway
    here = RouterWrapper::HERE_TRUCK
    result = here.route([[47.096305, 2.491150], [47.010226, 2.900391]], :time, nil, nil, 'en', true)
    assert 0 < result[:features].size
  end

  def test_router_disconnected
    here = RouterWrapper::HERE_TRUCK
    result = here.route([[-18.90928, 47.53381], [-16.92609, 145.75843]], :time, nil, nil, 'en', true, {motorway: true, toll: true})
    assert_equal 0, result[:features].size
  end

  def test_router_no_route_point
    here = RouterWrapper::HERE_TRUCK
    assert_raises Wrappers::UnreachablePointError do
      result = here.route([[0, 0], [42.73295, 0.27685]], :time, nil, nil, 'en', true)
    end
  end

  def test_router_avoid_area
    here = RouterWrapper::HERE_TRUCK
    options = {speed_multiplier_area: {[[52, 14], [42, 5]] => 0}, motorway: true, toll: true}
    result = here.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true, options)
    assert 1900000 < result[:features][0][:properties][:router][:total_distance]
  end

  def test_matrix_square
    here = RouterWrapper::HERE_TRUCK
    vector = [[49.610710, 18.237305], [47.010226, 2.900391]]
    result = here.matrix(vector, vector, :time, nil, nil, 'en')
    assert_equal vector.size, result[:matrix_time].size
    assert_equal vector.size, result[:matrix_time][0].size
  end

  def test_matrix_rectangular
    here = RouterWrapper::HERE_TRUCK
    src = [[49.610710, 18.237305], [47.010226, 2.900391]]
    dst = [[49.610710, 18.237305]]
    result = here.matrix(src, dst, :time, nil, nil, 'en')
    assert_equal src.size, result[:matrix_time].size
    assert_equal dst.size, result[:matrix_time][0].size
  end

  def test_large_matrix_split
    # activate cache because of large matrix
    here = Wrappers::Here.new(ActiveSupport::Cache::FileStore.new(File.join(Dir.tmpdir, 'router'), namespace: 'router', expires_in: 60*10), app_id: RouterWrapper::HERE_APP_ID, app_code: RouterWrapper::HERE_APP_CODE, mode: 'truck')
    # 101 points inside south-west(50.0,10.0) and north-east(51.0,11.0) (small zone to avoid timeout with here)
    vector = (0..100).collect{ |i| [50 + Float(i) / 100, 10 + Float(i) / 100]}
    result = here.matrix(vector, vector, :time, nil, nil, 'en')
    assert_equal vector.size, result[:matrix_time].size
    assert_equal vector.size, result[:matrix_time][0].size
  end

  # def test_matrix_with_null
  #   here = RouterWrapper::HERE_TRUCK
  #   # "startIndex":2 "destinationIndex":1 failed with here
  #   vector = [[49.610710,18.237305], [53.912125,9.881172], [47.010226,2.900391]]
  #   result = here.matrix(vector, vector, :time, nil, nil, 'en')
  #   assert_equal nil, result[:matrix_time][2][1]
  # end
end

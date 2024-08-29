# Copyright © Mapotempo, 2015
# Copyright © Frédéric Rodrigo, 2023
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

require './wrappers/here8'
require './router_wrapper'

class Wrappers::Here8Test < Minitest::Test

  def test_router
    here = RouterWrapper::HERE8_CAR
    result = here.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true, {motorway: true, toll: true})
    assert !result[:features].empty?
    assert !result[:features][0][:geometry].empty?
  end

  def test_router_without_geometry
    here = RouterWrapper::HERE8_CAR
    result = here.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', false, {motorway: true, toll: true})
    assert !result[:features][0].key?(:geometry)
  end

  def test_router_without_motorway
    here = RouterWrapper::HERE8_CAR
    result = here.route([[47.096305, 2.491150], [47.010226, 2.900391]], :time, nil, nil, 'en', true)
    assert !result[:features].empty?
  end

  def test_router_disconnected
    here = RouterWrapper::HERE8_CAR
    result = here.route([[-18.90928, 47.53381], [-16.92609, 145.75843]], :time, nil, nil, 'en', true, {motorway: true, toll: true})
    assert result[:features].empty?
  end

  def test_router_no_route_point
    here = RouterWrapper::HERE8_CAR
    assert_raises RouterWrapper::UnreachablePointError do
      result = here.route([[0, 0.000789], [42.73295, 0.27685]], :time, nil, nil, 'en', true)
    end
  end

  # def test_router_avoid_area
  #   here = RouterWrapper::HERE8_CAR
  #   options = {speed_multiplier_area: {[[48, 4], [46, 4], [46, 5], [58, 5]] => 0}, motorway: true, toll: true}
  #   result = here.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', false, options)
  #   assert 1_600_000 < result[:features][0][:properties][:router][:total_distance]
  # end

  # def test_router_truck_restriction
  #   here = RouterWrapper::HERE8_CAR
  #   options = { strict_restriction: true, hazardous_goods: :explosive }
  #   result = here.route([[43.6064, 3.8662047], [43.630469, 3.87083]], :time, nil, nil, 'en', true, options)
  #   assert result[:features].empty?

  #   options = { strict_restriction: false, hazardous_goods: :explosive }
  #   result = here.route([[43.6064, 3.8662047], [43.630469, 3.87083]], :time, nil, nil, 'en', true, options)
  #   assert !result[:features].empty?
  #   assert result[:features][0][:properties][:router][:total_distance] > 0
  # end

  def test_matrix_square
    here = RouterWrapper::HERE8_CAR
    vector = [[49.610710, 18.237305], [49.010226, 18.300391]]
    result = here.matrix(vector, vector, :time, nil, nil, 'en')
    assert_equal vector.size, result[:matrix_time].size
    assert_equal vector.size, result[:matrix_time][0].size
    assert result[:matrix_time][0].any?{ |m| m }
  end

  def test_matrix_rectangular
    here = RouterWrapper::HERE8_CAR
    src = [[49.610710, 18.237305], [49.010226, 18.300391]]
    dst = [[49.610710, 18.237305]]
    result = here.matrix(src, dst, :time, nil, nil, 'en')
    assert_equal src.size, result[:matrix_time].size
    assert_equal dst.size, result[:matrix_time][0].size
    assert result[:matrix_time][0].any?{ |m| m }
  end

  def test_matrix_traffic
    here = RouterWrapper::HERE8_CAR
    vector = [[49.610710, 18.237305], [49.010226, 18.300391]]
    result = here.matrix(vector, vector, :time, nil, nil, 'en', traffic: true)
    assert_equal vector.size, result[:matrix_time].size
    assert_equal vector.size, result[:matrix_time][0].size
    assert result[:matrix_time][0].any?{ |m| m }
  end

  # def test_matrix_truck_restriction
  #   here = RouterWrapper::HERE8_CAR
  #   src = [[43.6064, 3.8662047], [43.630469, 3.87083]]
  #   dst = [[43.6064, 3.8662047]]

  #   options = { strict_restriction: true, hazardous_goods: :explosive }
  #   result = here.matrix(src, dst, :time, nil, nil, 'en', options)
  #   assert_nil result[:matrix_time][1][0]

  #   options = { strict_restriction: false, hazardous_goods: :explosive }
  #   result = here.matrix(src, dst, :time, nil, nil, 'en', options)
  #   assert result[:matrix_time][1][0] > 0
  # end

  def gaussian(mean, stddev, rand)
    theta = 2 * Math::PI * rand.call
    rho = Math.sqrt(-2 * Math.log(1 - rand.call))
    scale = stddev * rho
    x = mean + scale * Math.cos(theta)
    y = mean + scale * Math.sin(theta)
    return x
  end

  def test_large_matrix_split
    # activate cache because of large matrix
    here = Wrappers::Here8.new(ActiveSupport::Cache::FileStore.new(File.join(Dir.tmpdir, 'router'), namespace: 'router', expires_in: 60*10), apikey: ENV['HERE8_APIKEY'], mode: 'truck', over_400km: false)
    # 101 points inside south-west(50.0,10.0) and north-east(51.0,11.0) (small zone to avoid timeout with here)
    vector = (0..20).collect{ |i|
      [
        gaussian(48.8012, 48.8012 - 48.82, method(:rand)),
        gaussian(2.3841, 2.3841 - 2.2675, method(:rand)),
      ]
    }
    result = here.matrix(vector, vector, :time, nil, nil, 'en', strict_restriction: true)
    assert_equal vector.size, result[:matrix_time].size
    assert_equal vector.size, result[:matrix_time][0].size
    assert_equal 0, result[:matrix_time][0][0]
    assert_equal 0, result[:matrix_time][1][1]
  end

  def test_manage_route_errors
    here = RouterWrapper::HERE8_CAR

    assert_raises RouterWrapper::InvalidArgumentError do
      here.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true, trailers: 3.5)
    end
  end

  # def test_router_with_toll_costs
  #   here = RouterWrapper::HERE8_CAR
  #   result = here.route([[44.92727960202825, -1.091766357421875], [43.29959713447473,3.41400146484375]], :time, nil, nil, 'en', false, {motorway: true, toll: true, toll_costs: true, weight: 3.4, height: 3, width: 2.5, length: 10})
  #   assert result[:features][0][:properties][:router][:total_toll_costs]
  # end

  # def test_matrix_with_null
  #   here = RouterWrapper::HERE8_CAR
  #   # "startIndex":2 "destinationIndex":1 failed with here
  #   vector = [[49.610710,18.237305], [53.912125,9.881172], [47.010226,2.900391]]
  #   result = here.matrix(vector, vector, :time, nil, nil, 'en')
  #   assert_equal nil, result[:matrix_time][2][1]
  # end

  # def test_isoline
  #   here = RouterWrapper::HERE_CAR
  #   result = here.isoline([49.610710, 18.237305], :time, 300, Time.now.iso8601, 'en', {motorway: true, toll: true})
  #   assert !result[:features].empty?
  #   assert !result[:features][0][:geometry].empty?
  # end

  def test_should_remove_empty_values
    here = RouterWrapper::HERE8_CAR
    vector = [[49.610710, 18.02], [49.010226, 18.300391]]

    assert here.matrix(vector, vector, :time, nil, nil, 'en', hazardous_goods: nil)
  end

  def test_route_float_to_integer_params
    here = RouterWrapper::HERE8_CAR
    options = { weight: 12.0, weight_per_axle: 5.0, height: 3.8, width: 2.6, length: 17.5 }
    options_multiplier = { weight: 1000, weight_per_axle: 1000, height: 100, width: 100, length: 100 }
    equivalent_options = { weight: 'vehicle[grossWeight]', weight_per_axle: 'vehicle[weightPerAxle]', height: 'vehicle[height]', width: 'vehicle[width]', length: 'vehicle[length]'}
    params = here.build_route_params(:time, nil, nil, 'en', false, options)
    options.each{ |key, value|
      assert params[equivalent_options[key].to_sym].is_a? Integer
      assert_equal value * options_multiplier[key], params[equivalent_options[key].to_sym]
    }
  end

  def test_matrix_float_to_integer_params
    here = RouterWrapper::HERE8_CAR
    options = { weight: 12.0, weight_per_axle: 5.0, height: 3.8, width: 2.6, length: 17.5 }
    options_multiplier = { weight: 1000, weight_per_axle: 1000, height: 100, width: 100, length: 100 }
    equivalent_options = { weight: :grossWeight, weight_per_axle: :weightPerAxle, height: :height, width: :width, length: :length }
    params = here.build_matrix_params(5, :time, nil, nil, 'en', options)
    options.each{ |key, value|
      assert params[:vehicle][equivalent_options[key]].is_a? Integer
      assert_equal value * options_multiplier[key], params[:vehicle][equivalent_options[key]]
    }
  end
end

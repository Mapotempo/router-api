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

require './wrappers/osrm5'

class Wrappers::Osrm5Test < Minitest::Test

  def _test_router
    osrm = RouterWrapper::OSRM5
    result = osrm.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true)
    assert 0 < result[:features].size
  end

  def test_router_no_route
    osrm = RouterWrapper::OSRM5
    result = osrm.route([[46.71350244599995, -2.3565673828124996], [45.9874205909687, -1.3623046875]], :time, nil, nil, 'en', true)
    assert_equal 0, result[:features].size
  end

  def test_router_with_summed_by_area_true
    osrm = RouterWrapper::OSRM5
    # With only one mapped way type (w2), it should return the interurban & secondary distance
    result = osrm.route([[44.82603994818902, -0.6808733940124512], [44.825240952347244, -0.6830835342407227]], :distance, nil, nil, 'en', true, with_summed_by_area: true)
    assert_equal [{way_type: 'interurban', distance: 195.7}, {way_type: 'secondary', distance: 195.7}], result[:features][0][:properties][:router][:summed_by_area]

    # It should regroup same way type as one : ['w2', 'w2'] => ['w2']
    result = osrm.route([[44.82559098998385, -0.679854154586792], [44.82682371430229, -0.6844997406005859]], :distance, nil, nil, 'en', true, with_summed_by_area: true)
    assert_equal [{way_type: 'urban', distance: 65.3}, {way_type: 'residential', distance: 407.9}, {way_type: 'interurban', distance: 419.4}, {way_type: 'secondary', distance: 76.8}], result[:features][0][:properties][:router][:summed_by_area], result[:features][0][:properties][:router][:summed_by_area]

    # With 2 blocks of different way type ['motorway', 'l1'] & ['w2', 'l1']
    # it should calculate the right distance (652) for ['w2', 'l1'] and do not revert ['motorway']
    result = osrm.route([[44.77936764497835, -0.6411123275756836], [44.779672267772845, -0.647892951965332]], :distance, nil, nil, 'en', true, with_summed_by_area: true)
    assert_equal [{way_type: 'urban', distance: 652.5}, {way_type: 'motorway', distance: 517.9}, {way_type: 'secondary', distance: 134.6}], result[:features][0][:properties][:router][:summed_by_area]
    assert_in_epsilon result[:features][0][:properties][:router][:total_distance], result[:features][0][:properties][:router][:summed_by_area].collect{ |c| c[:distance] if c[:way_type] == 'urban' }.first, 0.001
  end

  # Should handle coordinates in step['geometry']
  def test_router_with_summed_by_area_true_handle_geojson_option
    osrm = RouterWrapper::OSRM5
    result = osrm.route([[44.77936764497835, -0.6411123275756836], [44.779672267772845, -0.647892951965332]], :distance, nil, nil, 'en', true, with_summed_by_area: true, format: 'geojson')
    # [{:way_type=>"urban", :distance=>652.3}, {:way_type=>"motorway", :distance=>517.7}, {:way_type=>"secondary", :distance=>134.6}]
    assert_equal 3, result[:features][0][:properties][:router][:summed_by_area].count
  end

  def test_reverse_area_mapping
    osrm = RouterWrapper::OSRM5
    assert_equal %w[urban], osrm.reverse_area_mapping(['l1'])
    assert_equal %w[urban_dense], osrm.reverse_area_mapping(%w[l1 l2])
    assert_equal %w[water_body], osrm.reverse_area_mapping(['l2'])
    assert_equal %w[interurban tertiary], osrm.reverse_area_mapping(['w1'])
    assert_equal %w[interurban primary], osrm.reverse_area_mapping(%w[w1 w2])
    assert_equal %w[interurban trunk], osrm.reverse_area_mapping(%w[w1 w2 w3])
    assert_equal %w[interurban minor], osrm.reverse_area_mapping(['w2'])
    assert_equal %w[interurban residential], osrm.reverse_area_mapping(%w[w2 w3])
    assert_equal %w[interurban], osrm.reverse_area_mapping(['w3'])
    assert_equal %w[interurban], osrm.reverse_area_mapping([])
    assert_equal %w[interurban motorway], osrm.reverse_area_mapping(['motorway'])
    assert_equal %w[urban motorway], osrm.reverse_area_mapping(%w[l1 motorway])
    assert_equal %w[interurban trunk motorway], osrm.reverse_area_mapping(%w[w1 w2 w3 motorway])
    assert_equal %w[urban minor], osrm.reverse_area_mapping(%w[l1 w2])
  end

  def test_matrix_square
    osrm = RouterWrapper::OSRM5
    vector = [[49.610710, 18.237305], [47.010226, 2.900391]]
    result = osrm.matrix(vector, vector, :time, nil, nil, 'en')
    assert_equal vector.size, result[:matrix_time].size
    assert_equal vector.size, result[:matrix_time][0].size
  end

  def test_matrix_square_with_motorway_options
    osrm = RouterWrapper::OSRM5
    src = [[44.595845819060344, -1.1151123046875], [44.549377532663684, -0.25062561035156244]]
    dst = [[44.595845819060344, -1.1151123046875], [44.549377532663684, -0.25062561035156244]]
    result_for_motorway = {}
    [true, false].each do |boolean|
      result = osrm.matrix(src, dst, :time, nil, nil, 'en', motorway: boolean)
      result_for_motorway[boolean] = result
    end
    assert result_for_motorway[true][:matrix_time][0][1] < result_for_motorway[false][:matrix_time][0][1]
    assert result_for_motorway[true][:matrix_time][1][0] < result_for_motorway[false][:matrix_time][1][0]
  end

  def test_matrix_rectangular_time
    osrm = RouterWrapper::OSRM5
    src = [[49.610710, 18.237305], [47.010226, 2.900391]]
    dst = [[49.610710, 18.237305]]
    result = osrm.matrix(src, dst, :time, nil, nil, 'en')
    assert_equal src.size, result[:matrix_time].size
    assert_equal dst.size, result[:matrix_time][0].size
  end

  def test_matrix_1x1
    osrm = RouterWrapper::OSRM5
    src = [[49.610710, 18.237305]]
    dst = [[49.610710, 18.237305]]
    result = osrm.matrix(src, dst, :time_distance, nil, nil, 'en')
    assert_equal src.size, result[:matrix_time].size
    assert_equal dst.size, result[:matrix_time][0].size
    assert_equal src.size, result[:matrix_distance].size
    assert_equal dst.size, result[:matrix_distance][0].size
  end

  def test_matrix_rectangular_time_distance
    osrm = RouterWrapper::OSRM5
    src = [[49.610710, 18.237305], [47.010226, 2.900391]]
    dst = [[49.610710, 18.237305]]
    result = osrm.matrix(src, dst, :time_distance, nil, nil, 'en')
    assert_equal src.size, result[:matrix_time].size
    assert_equal src.size, result[:matrix_distance].size
    assert_equal dst.size, result[:matrix_time][0].size
    assert_equal dst.size, result[:matrix_distance][0].size
  end

  def test_isoline
    osrm = RouterWrapper::OSRM5
    result = osrm.isoline([49.610710, 18.237305], :time, 100, nil, 'en')
    assert 0 < result['features'].size
  end

  def test_geom_geojson
    osrm = RouterWrapper::OSRM5
    result = osrm.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true, format: 'geojson')
    assert result[:features][0][:geometry][:coordinates]
    assert !result[:features][0][:geometry][:polylines]
  end

  def test_geom_polylines
    osrm = RouterWrapper::OSRM5
    result = osrm.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true, format: 'json')
    assert !result[:features][0][:geometry][:coordinates]
    assert result[:features][0][:geometry][:polylines]

    result = osrm.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true, format: 'json', precision: 4)
    assert result[:features][0][:geometry][:coordinates]
    assert !result[:features][0][:geometry][:polylines]
  end
end

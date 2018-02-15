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

class Api::V01::MatrixTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Api::Root
  end

  def test_matrix_square
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', src: '43.2804,5.3806,43.291576,5.355835'}
      assert last_response.ok?, last_response.body
    }
  end

  def test_matrix_square_with_motorway_options
    src = '44.595845819060344,-1.1151123046875,44.549377532663684,-0.25062561035156244'
    dst = '44.595845819060344,-1.1151123046875,44.549377532663684,-0.25062561035156244'
    options = { api_key: 'demo', src: src, dst: dst, dimension: 'time', mode: 'osrm5' }
    result_for_motorway = {}
    [true, false].each do |boolean|
      get '/0.1/matrix', options.merge(motorway: boolean)
      result_for_motorway[boolean] = JSON.parse(last_response.body)['matrix_time']
    end
    assert result_for_motorway[true][0][1] < result_for_motorway[false][0][1]
    assert result_for_motorway[true][1][0] < result_for_motorway[false][1][0]
  end

  def test_matrix_rectangular_with_mod
    src = '44.595845819060344,-1.1151123046875'
    dst = '44.595845819060344,-1.1151123046875,44.549377532663684,-0.25062561035156244'
    options = { api_key: 'demo', src: src, dst: dst, dimension: 'time', mode: 'osrm5' }
    get '/0.1/matrix', options
    assert last_response.ok?, last_response.body
  end

  def test_matrix_rectangular
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', src: '43.2804,5.3806,43.291576,5.355835', dst: '43.290014,5.425873'}
      assert last_response.ok?, last_response.body
    }
  end

  def test_route_none_loc
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo'}
      assert !last_response.ok?, last_response.body
    }
  end

  def test_matrix_odd_loc
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', src: '43.2804,5.3806,43.291576'}
      assert !last_response.ok?, last_response.body
    }
  end

  def test_matrix_outside_area
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', src: '1,1,2,2'}
      assert_equal 417, last_response.status, 'Bad response: ' + last_response.body
    }
  end

  def test_matrix_not_all_outside_area
    [:get, :post].each{ |method|
      # 43.911775,5.203688 outside france-marseille.kml
      send method, '/0.1/matrix', {api_key: 'demo', src: '43.947855,4.807592,43.175515,5.607192,43.911775,5.203688'}
      assert last_response.ok?, last_response.body
    }
  end

  def test_post_matrix_with_empty_dst
    post '/0.1/matrix', api_key: 'demo', src: '43.2804,5.3806,43.291576,5.355835,43.2810,5.3810', dst: ''
    assert_equal 200, last_response.status
  end

  def test_matrix_with_duplicate
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', mode: 'osrm5', src: '43.2804,5.3806,43.291576,5.355835,43.2804,5.3806'}
      assert last_response.ok?, last_response.body
      json = JSON.parse(last_response.body)
      assert_equal 3, json['matrix_time'].size
      assert_equal 3, json['matrix_time'][0].size
    }
  end

  def test_matrix_with_not_supported_transportation_mode
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', mode: 'unknown', src: '1,1,2,2'}
      assert_equal 404, last_response.status, 'Bad response: ' + last_response.body
    }
  end

  def test_matrix_with_not_supported_transportation_mode
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', mode: 'unknown', src: '1,1,2,2'}
      assert_equal 404, last_response.status, 'Bad response: ' + last_response.body
    }
  end

  def test_routes_out_of_supported_area_or_not_supported_dimension_error
    get '/0.1/matrix', api_key: 'demo', src: '-5.101887070062321,-37.353515625', dst: '-5.8236866460048295,-35.26611328125', mode: 'osrm5'
    assert_equal 417, last_response.status, 'Bad response: ' + last_response.body
  end

  def test_routes_here_invalid_argument_error
    get '/0.1/matrix', api_key: 'demo', src: '49.610710,18.237305', dst: '47.010226, 2.900391', mode: 'here', trailers: '10'
    assert_equal 400, last_response.status, 'Bad response: ' + last_response.body
  end
end

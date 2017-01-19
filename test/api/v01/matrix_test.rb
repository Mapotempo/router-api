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

  def test_matrix_with_duplicate
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', mode: 'osrm5', src: '43.2804,5.3806,43.291576,5.355835,43.2804,5.3806'}
      assert last_response.ok?, last_response.body
      json = JSON.parse(last_response.body)
      assert_equal 3, json['matrix_time'].size
      assert_equal 3, json['matrix_time'][0].size
    }
  end

  def test_matrix_rectangular_with_duplicate
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', mode: 'osrm5', src: '43.2804,5.3806,43.291576,5.355835,43.2804,5.3806', dst: '43.290014,5.425873,43.290014,5.425873'}
      assert last_response.ok?, last_response.body
      json = JSON.parse(last_response.body)
      assert_equal 3, json['matrix_time'].size
      assert_equal 2, json['matrix_time'][0].size
    }
  end
end

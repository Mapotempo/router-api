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

require './api/root'

class Api::V01::RouteTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Api::Root
  end

  def test_route
    get '/0.1/route', {api_key: 'demo', loc: '43.2804,5.3806,43.291576,5.355835'}
    assert last_response.ok?, last_response.body
  end

  def test_route_same_start_end_geojson
    get '/0.1/route.geojson', {api_key: 'demo', loc: '43.2804,5.3806,43.2804,5.3806'}
    assert last_response.ok?, last_response.body
    f = JSON.parse(last_response.body)['features'][0]
    assert_equal 0, f['properties']['router']['total_distance']
    assert_equal 0, f['properties']['router']['total_time']
    assert_equal [[5.3806, 43.2804], [5.3806, 43.2804]], f['geometry']['coordinates']
  end

  def test_route_none_loc
    get '/0.1/route', {api_key: 'demo'}
    assert !last_response.ok?, last_response.body
  end

  def test_route_missing_loc
    get '/0.1/route', {api_key: 'demo', loc: '43.2804,5.3806'}
    assert !last_response.ok?, last_response.body
  end

  def test_route_odd_loc
    get '/0.1/route', {api_key: 'demo', loc: '43.2804,5.3806,43.291576'}
    assert !last_response.ok?, last_response.body
  end

  def test_route_outside_area
    get '/0.1/route', {api_key: 'demo', loc: '1,1,2,2'}
    assert_equal 417, last_response.status, 'Bad response: ' + last_response.body
  end

  def test_route_speed_multiplier_area
    get '/0.1/route', {api_key: 'demo', loc: '43.2804,5.3806,43.291576,5.355835', speed_multiplier_area: '0', area: '52,14,42,5'}
    assert last_response.ok?, last_response.body
  end

  def test_routes
    [:get, :post].each{ |method|
      send method, '/0.1/routes', {api_key: 'demo', locs: '43.2804,5.3806,43.291576,5.355835;42.2804,4.3806,42.291576,4.355835'}
      assert last_response.ok?, last_response.body
      f = JSON.parse(last_response.body)['features']
      assert_equal 2, f.size
    }
  end

  def test_routes_none_locs
    [:get, :post].each{ |method|
      send method, '/0.1/routes', {api_key: 'demo'}
      assert !last_response.ok?, last_response.body
    }
  end

  def test_routes_missing_locs
    [:get, :post].each{ |method|
      send method, '/0.1/routes', {api_key: 'demo', locs: '43.2804,5.3806'}
      assert !last_response.ok?, last_response.body
    }
  end

  def test_routes_odd_locs
    [:get, :post].each{ |method|
      send method, '/0.1/routes', {api_key: 'demo', locs: '43.2804,5.3806,43.291576'}
      assert !last_response.ok?, last_response.body
    }
  end
end

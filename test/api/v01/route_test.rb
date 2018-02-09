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
    assert !JSON.parse(last_response.body)['features'][0]['geometry'].empty?
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

  def test_route_should_return_summed_by_area
    get '/0.1/route', api_key: 'demo', loc: '44.82603994818902,-0.6808733940124512,44.825240952347244,-0.6830835342407227', mode: 'osrm5', with_summed_by_area: true
    assert_equal [{'distance' => 195.7, 'way_type' => 'interurban'}, {'distance' => 195.7, 'way_type' => 'secondary'}], JSON.parse(last_response.body)['features'][0]['properties']['router']['summed_by_area']
  end

  def test_routes
    features = []
    [:get, :post].each{ |method|
      send method, '/0.1/routes', {api_key: 'demo', locs: '43.2804,5.3806,43.291576,5.355835;43.330672,5.375404,43.267706,5.402184'}
      assert last_response.ok?, last_response.body
      f = JSON.parse(last_response.body)['features']
      assert_equal 2, f.size
      assert f[0]['geometry']
      assert f[1]['geometry']
      features << f
    }

    assert_equal features[0], features[1]
  end

  def test_routes_out_of_supported_area_or_not_supported_dimension_error
    get '/0.1/routes', api_key: 'demo', locs: '-5.101887070062321,-37.353515625,-5.8236866460048295,-35.26611328125', mode: 'osrm5'
    assert_equal 417, last_response.status, 'Bad response: ' + last_response.body
  end

  def test_routes_here_invalid_argument_error
    get '/0.1/routes', api_key: 'demo', locs: '49.610710,18.237305,47.010226, 2.900391', mode: 'here', trailers: '10'
    assert_equal 400, last_response.status, 'Bad response: ' + last_response.body
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

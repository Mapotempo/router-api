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

class Api::V01::IsolineTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Api::Root
  end

  def test_isoline_with_approach
    get '/0.1/isoline', api_key: 'demo', loc: '43.2804,5.3806', size: 33, departure: Time.now, approach: :curb, mode: 'osrm'
    assert last_response.ok?, last_response.body
  end

  def test_isoline
    [:get, :post].each{ |method|
      send method, '/0.1/isoline', {api_key: 'demo', loc: '43.2804,5.3806', size: 33, departure: Time.now}
      assert last_response.ok?, last_response.body
      assert !JSON.parse(last_response.body)['features'][0]['geometry'].empty?
    }
  end

  def test_isoline_none_loc
    [:get, :post].each{ |method|
      send method, '/0.1/isoline', {api_key: 'demo'}
      assert !last_response.ok?, last_response.body
    }
  end

  def test_isoline_outside_area
    [:get, :post].each{ |method|
      send method, '/0.1/isoline', {api_key: 'demo', loc: '1,1', size: 1, departure: Time.now}
      assert_equal 417, last_response.status, 'Bad response: ' + last_response.body
    }
  end

  def test_isoline_invalid_query_string_malformed
    get '/0.1/isoline', api_key: 'demo', loc: '48.726675,-0.000079', size: 1, mode: 'osrm'
    assert last_response.ok?
  end

  def test_count_isolines
    [:get, :post].each_with_index do |method, indx|
      send method, '/0.1/isoline', {api_key: 'demo', loc: '43.2804,5.3806', size: 1}
      keys = RouterWrapper.config[:redis_count].keys("router:isoline:#{Time.now.utc.to_s[0..9]}_key:demo_ip*")
      assert_equal 1, keys.size
      assert_equal({'hits' => (indx + 1).to_s, 'transactions' => (indx + 1).to_s}, RouterWrapper.config[:redis_count].hgetall(keys.first))
    end
  end

  def test_use_quotas
    loc = '43.2804,5.3806'

    post '/0.1/isoline', {api_key: 'demo_quotas', loc: loc, size: 1}
    assert last_response.ok?, last_response.body

    post '/0.1/isoline', {api_key: 'demo_quotas', loc: loc, size: 1}
    assert_equal 429, last_response.status

    assert_includes JSON.parse(last_response.body)['message'], 'Too many daily requests'
    assert_equal ['application/json; charset=UTF-8', 1, 0, Time.now.utc.to_date.next_day.to_time.to_i], last_response.headers.select{ |key|
      key =~ /(Content-Type|X-RateLimit-Limit|X-RateLimit-Remaining|X-RateLimit-Reset)/
    }.values
  end

  def test_demo_nil_quotas
    # assert override 10 by nil (unlimited)
    11.times do
      post '/0.1/isoline', { api_key: 'demo_nil_quotas', loc: '43.2804,5.3806', size: 1 }
      assert last_response.ok?, last_response.body
    end
  end
end

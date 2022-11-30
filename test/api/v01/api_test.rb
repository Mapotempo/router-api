# Copyright © Mapotempo, 2020
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

class Api::V01::ApiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Api::Root
  end

  def test_should_not_access
    get '/0.1/route', {loc: '43.2804,5.3806,43.291576,5.355835'}
    assert_equal 401, last_response.status
    assert_equal '401 Unauthorized', JSON.parse(last_response.body)['error']
  end

  def test_should_not_access_if_expired
    get '/0.1/route', {api_key: 'expired', loc: '43.2804,5.3806,43.291576,5.355835'}
    assert_equal 402, last_response.status
    assert_equal '402 Subscription expired', JSON.parse(last_response.body)['error']
  end

  def test_metrics
    clear_router_redis_count
    post '/0.1/routes', { api_key: 'demo', locs: '43.2805,5.3806,43.2804,5.3806,43.330672,5.375404' }

    assert last_response.ok?, last_response.body

    get '0.1/metrics.json', { api_key: 'demo'}
    assert_equal 401, last_response.status

    get '0.1/metrics.json', { api_key: 'metrics'}
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body).first

    assert_equal Date.today.strftime('%Y-%m-%d'), json['count_date']
    assert_equal '1', json['count_hits']
    assert_equal '2', json['count_transactions']
    assert_equal '127.0.0.1', json['count_ip']
    assert_equal 'demo', json['count_key']
    assert_equal 'router', json['count_service']
    assert_equal 'route', json['count_endpoint']

    post '/0.1/matrix', {api_key: 'demo', src: '43.2804,5.3806,43.2804,5.3806' }

    get '0.1/metrics.json', { api_key: 'metrics'}
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body)
    assert_equal 2, json.count
    assert_equal '1', json[1]['count_hits']
    assert_equal '4', json[1]['count_transactions']
  end
end

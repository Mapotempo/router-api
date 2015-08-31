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
    get '/0.1/route', {api_key: 'demo', loc: '12.5,78,4,45'}
    assert last_response.ok?, last_response.body
  end

  def test_route_missing_loc
    assert_raises do
      get '/0.1/route', {api_key: 'demo', loc: '12.5,78,4'}
    end
  end

  def test_route_odd_loc
    assert_raises do
      get '/0.1/route', {api_key: 'demo', loc: '12.5,78,4,7,8'}
    end
  end
end

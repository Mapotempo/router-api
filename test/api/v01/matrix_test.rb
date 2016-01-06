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
    get '/0.1/matrix', {api_key: 'demo', src: '1,0,0,1'}
    assert last_response.ok?, last_response.body
  end

  def test_matrix_rectangular
    get '/0.1/matrix', {api_key: 'demo', src: '1,0,0,1', dst: '2,3'}
    assert last_response.ok?, last_response.body
  end

  def test_matrix_odd_loc
    get '/0.1/matrix', {api_key: 'demo', src: '1,2,3'}
    assert !last_response.ok?, last_response.body
  end
end

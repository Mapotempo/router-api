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
require './wrappers/crow'

class Wrappers::CrowTest < Minitest::Test

  def test_route
    crow = RouterWrapper::CROW
    result = crow.route([[49.610710, 18.237305], [47.010226, 2.900391]], :time, nil, nil, 'en', true, {motorway: true, toll: true})
    assert !result[:features].empty?
    assert !result[:features][0][:geometry].empty?
  end

  def test_matrix
    crow = RouterWrapper::CROW
    result = crow.matrix([[49.610710, 18.237305]], [[47.010226, 2.900391]], :time, nil, nil, 'en', {motorway: true, toll: true})
    assert !result[:matrix_time].empty?
  end

  def test_isoline
    crow = RouterWrapper::CROW
    result = crow.isoline([49.610710, 18.237305], :time, 2, nil, 'en', {motorway: true, toll: true})
    assert !result[:features].empty?
    assert !result[:features][0][:geometry].empty?
  end
end

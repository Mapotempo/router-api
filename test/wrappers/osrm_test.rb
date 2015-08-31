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

require './wrappers/osrm'

class Wrappers::OsrmTest < Minitest::Test

  def test_router
    osrm = RouterWrapper::OSRM
    result = osrm.route([[49.610710, 18.237305], [47.010226, 2.900391]], nil, nil, 'en', true)
    assert 0 < result[:features].size
  end

  def test_router_impassable
    osrm = RouterWrapper::OSRM
    result = osrm.route([[71.187754, -46.054687], [-25.165173, 135.351562]], nil, nil, 'en', true)
    assert 0 == result[:features].size
  end
end

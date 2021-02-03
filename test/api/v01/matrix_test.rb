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
    options = { api_key: 'demo', src: src, dst: dst, dimension: 'time', mode: 'osrm' }
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
    options = { api_key: 'demo', src: src, dst: dst, dimension: 'time', mode: 'osrm' }
    get '/0.1/matrix', options
    assert last_response.ok?, last_response.body
  end

  def test_matrix_rectangular
    [:get, :post].each{ |method|
      send method, '/0.1/matrix', {api_key: 'demo', src: '43.2804,5.3806,43.291576,5.355835', dst: '43.290014,5.425873'}
      assert last_response.ok?, last_response.body
    }
  end

  def test_matrix_invalid_query_string_malformed
    %w[osrm here].each do |mode|
      get '/0.1/matrix', api_key: 'demo', src: '48.726675,-0.000079', dst: '48.84738,0.029615', mode: mode
      assert last_response.ok?
    end
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
      send method, '/0.1/matrix', {api_key: 'demo', mode: 'osrm', src: '43.2804,5.3806,43.291576,5.355835,43.2804,5.3806'}
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
    get '/0.1/matrix', api_key: 'demo', src: '-5.101887070062321,-37.353515625', dst: '-5.8236866460048295,-35.26611328125', mode: 'osrm'
    assert_equal 417, last_response.status, 'Bad response: ' + last_response.body
  end

  def test_routes_here_invalid_argument_error
    get '/0.1/matrix', api_key: 'demo', src: '49.610710,18.237305', dst: '47.010226, 2.900391', mode: 'here', trailers: '10'
    assert_equal 400, last_response.status, 'Bad response: ' + last_response.body
  end

  # Matrix 100X15 max
  def test_here_matrix_should_be_fifteen_per_hundred_at_max
    RouterWrapper::HERE_TRUCK.stub(:get, lambda { |_url_base, _object, params|

      # can be the rest of destinations number or 100
      assert [100, @dest_number % 100].include?(params.keys.select { |key| key =~ /^destination/ }.count)

      max_start = RouterWrapper::HERE_TRUCK.send(:max_srcs, @distance_km)
      # can be the rest of starts number or max_start
      assert [max_start, @start_number % 5].include?(params.keys.select { |key| key =~ /^start/ }.count)

      {"response"=>{"matrixEntry"=>[{"startIndex"=>0, "destinationIndex"=>0, "summary"=>{"travelTime"=>0, "costFactor"=>1}}, {"startIndex"=>0, "destinationIndex"=>1, "summary"=>{"travelTime"=>1356, "costFactor"=>1750}}]}}
    }) do
      centroid = { lat: 43.851084, lng: -1.385374 }
      [200, 1000, 2000].each do |km|
        @distance_km = km

        @start_number = 32
        src = []
        @start_number.times do |row|
          loop do
            src[row] = random_location(centroid, 4)
            break if src.uniq.count == src.count
          end
        end

        @dest_number = 201
        dst = []
        @dest_number.times do |col|
          loop do
            # Pythagore to get square diagonal of distance_km
            distance_for_diagonal = ((@distance_km / Math.sqrt(2)) / 2).floor
            dst[col] = random_location(centroid, distance_for_diagonal)

            break if dst.uniq.count == dst.count
          end
        end

        post '/0.1/matrix', api_key: 'demo', mode: 'here', src: src.flatten.join(','), dst: dst.flatten.join(',')

        assert_equal 200, last_response.status, last_response.body
      end
    end
  end

  def test_param_matrix_dont_exceed_limit
    [:get, :post].each do |method|
      send method, '/0.1/matrix', api_key: 'demo', src: '43.2804,5.3806,43.291576,5.355835', dst: '43.2804,5.3806,43.291577,5.355836'
      assert 200, last_response.status
      send method, '/0.1/matrix', api_key: 'demo', src: '43.2804,5.3806,43.291576,5.355835'
      assert_includes last_response.body, 'matrix_time'
    end
  end

  def test_param_matrix_exceed_limit
    [:get, :post].each do |method|
      send method, '/0.1/matrix', api_key: 'demo_limit', src: '43.2804,5.3806,43.291576,5.355835', dst: '43.2804,5.3806,43.291577,5.355836'
      assert 413, last_response.status
      send method, '/0.1/matrix', api_key: 'demo_limit', src: '43.2804,5.3806,43.291576,5.355835'
      assert_includes last_response.body, 'Exceeded'
    end
  end

  def test_count_matrix
    [:get, :post].each_with_index do |method, indx|
      src = '43.2804,5.3806,43.2804,5.3806'
      dst = '43.2804,5.3806'
      send method, '/0.1/matrix', {api_key: 'demo', src: src, dst: dst}
      keys = RouterWrapper.config[:redis_count].keys("router:matrix:#{Time.now.utc.to_s[0..9]}_key:demo_ip*")
      assert_equal 1, keys.size
      transactions = Api::V01::APIBase.count_matrix_locations(src: src, dst: dst)
      assert_equal({'hits' => (indx + 1).to_s, 'transactions' => ((indx + 1) * transactions).to_s}, RouterWrapper.config[:redis_count].hgetall(keys.first))
    end
  end

  def test_use_quotas
    src = '43.2804,5.3806,43.2804,5.3806'
    dst = '43.2804,5.3806'

    post '/0.1/matrix', {api_key: 'demo_quotas', src: src, dst: dst}
    assert last_response.ok?, last_response.body

    post '/0.1/matrix', {api_key: 'demo_quotas', src: src, dst: dst}
    assert_equal 429, last_response.status

    assert_includes JSON.parse(last_response.body)['message'], 'Too many daily requests'
    assert_equal ['application/json; charset=UTF-8', 2, 0, Time.now.utc.to_date.next_day.to_time.to_i], last_response.headers.select{ |key|
      key =~ /(Content-Type|X-RateLimit-Limit|X-RateLimit-Remaining|X-RateLimit-Reset)/
    }.values
  end
end

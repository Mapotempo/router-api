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
require 'simplecov'
SimpleCov.start

ENV['APP_ENV'] ||= 'test'
require File.expand_path('../../config/environments/' + ENV['APP_ENV'], __FILE__)
Dir[File.dirname(__FILE__) + '/../config/initializers/*.rb'].each {|file| require file }
require './router_wrapper'
require './api/root'

require 'minitest/reporters'
require 'minitest/focus'
require 'byebug'
Minitest::Reporters.use!

require 'grape'
require 'grape-swagger'
require 'grape-entity'

require 'minitest/autorun'
require 'rack/test'

##
# max_radius in km
def random_point_in_disk(max_radius)
  radius = max_radius * 1000 # to meter

  # 0 to 2 Pi excluding 2 Pi because that's just 0.
  radians = Random.rand(2 * Math::PI)

  # Math.cos/sin work in radians, not degrees.
  x = radius * Math.cos(radians)
  y = radius * Math.sin(radians)

  [x, y]
end

##
# max_radius in km
def random_location(centroid, max_radius)
  earth_radius = 6371 # km
  one_degree = earth_radius * 2 * Math::PI / 360 * 1000 # 1 degree latitude in meters

  dx, dy = random_point_in_disk(max_radius)
  random_lat = centroid[:lat] + dy / one_degree
  random_lng = centroid[:lng] + dx / (one_degree * Math.cos(centroid[:lat] * Math::PI / 180))
  [random_lat.round(5), random_lng.round(5)] # meter precision
end

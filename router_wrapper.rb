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
require 'i18n'

module RouterWrapper
  def self.config
    @@c
  end

  def self.desc()
    Hash[config[:services].select{ |s, v| [:route, :matrix, :isoline].include?(s) }.collect do |service_key, service_value|
      l = service_value.collect do |router_key, router_value|
        {
          mode: router_key,
          name: I18n.translate('router.' + router_key.to_s + '.name', default: (I18n.translate('router.' + router_key.to_s + '.name', locale: :en))),
          area: router_value.collect(&:area).compact
        }
      end
      [service_key, l.flatten]
    end]
  end

  def self.wrapper_route(params)
    router = config[:services][:route][params[:mode].to_sym].find{ |router|
      router.route?(params[:loc][0], params[:loc][-1])
    }
    if !router
      raise OutOfSupportedAreaError
    else
      options = { speed_multiplicator: (params[:speed_multiplicator] || 1) }
      router.route(params[:loc], params[:departure], params[:arrival], params[:language], params[:geometry], options)
    end
  end

  def self.wrapper_matrix(params)
    top, bottom = (params[:src] + params[:dst]).minmax_by{ |loc| loc[0] }
    left, right = (params[:src] + params[:dst]).minmax_by{ |loc| loc[1] }
    top_left = [top, left]
    bottom_right = [bottom, right]
    router = config[:services][:route][params[:mode].to_sym].find{ |router|
      router.matrix?(top_left, bottom_right)
    }
    if !router
      raise OutOfSupportedAreaError
    else
      options = { speed_multiplicator: (params[:speed_multiplicator] || 1) }
      router.matrix(params[:src], params[:dst], params[:departure], params[:arrival], params[:language], options)
    end
  end

  def self.wrapper_isoline(params)
    router = config[:services][:route][params[:mode].to_sym].find{ |router|
      router.isoline?(params[:loc])
    }
    if !router
      raise OutOfSupportedAreaError
    else
      options = { speed_multiplicator: (params[:speed_multiplicator] || 1) }
      params[:departure] ||= Time.now
      router.isoline(params[:loc], params[:size], params[:departure], params[:language], options)
    end
  end

  class OutOfSupportedAreaError < StandardError
  end
end

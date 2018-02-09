# Copyright © Mapotempo, 2015-2016
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

  def self.desc(services)
    Hash[services.select{ |s, v| [:route, :matrix, :isoline].include?(s) }.collect do |service_key, service_value|
      l = service_value.collect do |router_key, router_values|
        unless router_values.empty?
          h = {
            mode: router_key,
            name: I18n.translate('router.' + router_key.to_s + '.name', default: (I18n.translate('router.' + router_key.to_s + '.name', locale: :en))),
            dimensions: router_values.collect{ |r| r.send(service_key.to_s + '_dimension') }.flatten.uniq,
            area: router_values.collect(&:area).compact
          }
          Wrappers::Wrapper::OPTIONS.each do |s|
            h.merge!("support_#{s}".to_sym => router_values.all?(&"#{s}?".to_sym))
          end
          h
        end
      end.compact
      [service_key, l.flatten]
    end]
  end

  def self.wrapper_route(services, params)
    modes = services[:route][params[:mode]]
    raise NotSupportedTransportationMode unless modes

    router = modes.find{ |router|
      router.route?(params[:loc][0], params[:loc][-1], params[:dimension])
    }
    raise OutOfSupportedAreaOrNotSupportedDimensionError unless router

    if params[:loc].size == 2 && params[:loc][0] == params[:loc][1]
      feature = {
        type: 'Feature',
        properties: {
          router: {
            total_distance: 0,
            total_time: 0,
            start_point: params[:loc][0].reverse,
            end_point: params[:loc][1].reverse
          }
        }
      }
      feature[:geometry] = {
        type: 'LineString',
        coordinates: [params[:loc][0].reverse, params[:loc][1].reverse]
      } if params[:geometry]
      {
        type: 'FeatureCollection',
        router: {
          licence: nil,
          attribution: nil,
        },
        features: [feature]
      }
    else
      router.route(params[:loc], params[:dimension], params[:departure], params[:arrival], params[:language], params[:geometry], options(params))
    end
  end

  def self.wrapper_matrix(services, params)
    modes = services[:matrix][params[:mode]]
    raise NotSupportedTransportationMode unless modes

    point_uniq(params[:src], params[:dst], params[:dimension]) { |src, dst|
      routers = if modes.size == 1
        top, bottom = (src + dst).minmax_by{ |loc| loc[0] }
        left, right = (src + dst).minmax_by{ |loc| loc[1] }
        [modes.find{ |router|
          router.matrix?(top, left, params[:dimension]) && router.matrix?(bottom, right, params[:dimension])
        }].compact
      else
        # check all combinations in matrix, could be long...
        src.collect{ |src|
          dst.collect{ |dst|
            modes.find{ |router|
              router.matrix?(src, dst, params[:dimension])
            }
          }
        }.flatten.compact.uniq
      end
      raise OutOfSupportedAreaOrNotSupportedDimensionError if routers.size == 0

      if routers.size == 1
        routers[0].matrix(src, dst, params[:dimension], params[:departure], params[:arrival], params[:language], options(params))
      else
        ret = {
            router: {
                licence: [],
                attribution: [],
            }
        }
        params[:dimension].to_s.split('_').each{ |dim|
          ret[('matrix_' + dim).to_sym] = Array.new(src.size) { Array.new(dst.size) }
        }
        routers.each{ |router|
          partial = router.matrix(src, dst, params[:dimension], params[:departure], params[:arrival], params[:language], options(params))
          if partial
            ret[:router][:licence] << partial[:router][:licence]
            ret[:router][:attribution] << partial[:router][:attribution]
            params[:dimension].to_s.split('_').each{ |dim|
              matrix_dim = ('matrix_' + dim).to_sym
              src.each_with_index{ |src, m|
                dst.each_with_index{ |dst, n|
                  if partial[matrix_dim][m][n] && (!ret[matrix_dim][m][n] || partial[matrix_dim][m][n] < ret[matrix_dim][m][n])
                    ret[matrix_dim][m][n] = partial[matrix_dim][m][n]
                  end
                }
              }
            }
          end
        }
        ret
      end
    }
  end

  def self.wrapper_isoline(services, params)
    modes = services[:isoline][params[:mode]]
    raise NotSupportedTransportationMode unless modes

    router = modes.find{ |router|
      router.isoline?(params[:loc], params[:dimension])
    }

    raise OutOfSupportedAreaOrNotSupportedDimensionError unless router

    router.isoline(params[:loc], params[:dimension], params[:size], params[:departure], params[:language], options(params))
  end

  class RouterWrapperError < StandardError
  end

  class NotSupportedTransportationMode < RouterWrapperError
  end

  class OutOfSupportedAreaOrNotSupportedDimensionError < RouterWrapperError
  end

  class InvalidArgumentError < RouterWrapperError
  end

  private

  def self.speed_multiplier_area(params)
    Hash[params[:area].zip(params[:speed_multiplier_area])] if params[:area]
  end

  def self.point_uniq(src, dst, dimension)
    src_uniq = src.each_with_index.group_by(&:first).to_a.sort_by(&:first)
    dst_uniq = dst.each_with_index.group_by(&:first).to_a.sort_by(&:first)

    ret = yield(src_uniq.collect(&:first), dst_uniq.collect(&:first))

    dimension.to_s.split('_').each{ |dim|
      matrix_dim = ('matrix_' + dim).to_sym
      matrix = Array.new(src.size) { Array.new(dst.size) }
      src_uniq.each_with_index{ |a, src_uniq_index|
        src_point, src_indices = a
        src_indices.each{ |_, src_index|
          dst_uniq.each_with_index{ |b, dst_uniq_index|
            dst_point, dst_indices = b
            dst_indices.each{ |_, dst_index|
              matrix[src_index][dst_index] = ret[matrix_dim][src_uniq_index][dst_uniq_index]
            }
          }
        }
      }
      ret[matrix_dim] = matrix
    }

    ret
  end

  def self.options(params)
    hash = {
      speed_multiplier: params[:speed_multiplier] || 1,
      speed_multiplier_area: speed_multiplier_area(params),
      format: params[:format],
      precision: params[:precision],
      with_summed_by_area: params[:with_summed_by_area]
    }
    (Wrappers::Wrapper::OPTIONS -
      [:speed_multiplier, :avoid_area, :speed_multiplier_area, :departure, :arrival]).each{ |k|
      hash[k] = params[k]
    }
    hash
  end
end

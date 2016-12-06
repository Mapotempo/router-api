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
require 'grape'
require 'grape-swagger'
require 'grape-entity'
require 'grape_logging'

require './api/v01/api'

module Api
  class ApiV01 < Grape::API
    version '0.1', using: :path

    mount V01::Api

    documentation_class = add_swagger_documentation hide_documentation_path: true, markdown: GrapeSwagger::Markdown::KramdownAdapter.new, info: {
      title: ::RouterWrapper::config[:product_title],
      description: ('
## Technical access

### Swagger descriptor

This REST API is described with Swagger. The Swagger descriptor defines the request end-points, the parameters and the return values. The API can be addressed by HTTP request or with a generated client using the Swagger descriptor.

### API key

All access to the API are subject to an `api_key` parameter in order to authenticate the user.

### Return

The API supports several return formats: `geojson`, `json` and `xml` which depend of the requested extension used in url.

## Examples

### Routing

[Find your route on a map](http://router.mapotempo.com/route.html)

### Isolines

[Build your isoline on a map](http://router.mapotempo.com/isoline.html)
'),
      contact: ::RouterWrapper::config[:product_contact]
    }
  end
end

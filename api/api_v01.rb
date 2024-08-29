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

    content_type :json, 'application/json; charset=UTF-8'
    content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
    content_type :xml, 'application/xml'
    content_type :csv, 'text/csv; charset=UTF-8'

    mount V01::Api

    documentation_class = add_swagger_documentation(
      hide_documentation_path: true,
      security_definitions: {
        api_key_query_param: {
          type: 'apiKey',
          name: 'api_key',
          in: 'query'
        }
      },
      security: [{
        api_key_query_param: [],
      }],
      consumes: [
        'application/json; charset=UTF-8',
        'application/xml',
      ],
      produces: [
        'application/json; charset=UTF-8',
        'application/xml',
      ],
      doc_version: nil,
      info: {
        title: ::RouterWrapper::config[:product_title],
        contact_email: ::RouterWrapper::config[:product_contact_email],
        contact_url: ::RouterWrapper::config[:product_contact_url],
        license: 'GNU Affero General Public License 3',
        license_url: 'https://raw.githubusercontent.com/cartoroute/router-api/master/LICENSE',
        description: '
## Technical access

### Swagger descriptor

This REST API is described with Swagger. The Swagger descriptor defines the request end-points, the parameters and the return values. The API can be addressed by HTTP request or with a generated client using the Swagger descriptor.

### Parameters compatibility

Use **capability operations** to know the availabled parameter options (toll, motorway, etc.) for each mode (car, truck, etc.)

For car mode only, the following route options are the one allowed:

|Tracks|Motorways|Tolls|
|---|---|---|
|true|true|true|
|true|false|true|
|true|false|false|
|false|true|true|

### API key

All access to the API are subject to an `api_key` parameter in order to authenticate the user.

### Return

The API supports several return formats: `geojson`, `json` and `xml` which depend of the requested extension used in url.

## Examples

### Routing

[Find your route on a map](/route.html)

### Isolines

[Build your isoline on a map](/isoline.html)'
      }
    )
  end
end

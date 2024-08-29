// Copyright © Mapotempo, 2018
//
// This file is part of Mapotempo.
//
// Mapotempo is free software. You can redistribute it and/or
// modify since you respect the terms of the GNU Affero General
// Public License as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Mapotempo is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Mapotempo. If not, see:
// <http://www.gnu.org/licenses/agpl.html>
//

"use strict"

L.mapotempo = (function() {

  function formatMapTiles(layers) {
    const mapTiles = layers.reduce(function(obj, layer) {
      const tileLayer = L.tileLayer(layer.url, layer.options)
      if (layer.overlay) {
        obj.overlays[layer.name] = tileLayer;
      } else {
        obj.layers[layer.name] = tileLayer;
        if (layer.default) {
          obj.default = tileLayer;
        }
      }
      return obj
    }, { layers: {}, overlays: {}, default: null });

    // If no default layer set the first layer is used by default
    if (mapTiles.default === null) {
      mapTiles.default = mapTiles.layers[Object.keys(mapTiles.layers)[0]];
    }
    return mapTiles;
  }

  return new (function Mapotempo() {
    this._map;

    // Map initialization
    this.map = function(id, option) {
      this._map = new L.Map(id, option);

      // Get leaflet tile layers depending on api_key
      const mapTiles = formatMapTiles([{"name":"OpenStreetMap","url":"https://a.tile.openstreetmap.org/{z}/{x}/{y}.png","options":{"zoom":18,"attribution":"Map data \u0026copy; \u003ca href=\"https://openstreetmap.org\"\u003eOpenStreetMap\u003c/a\u003e contributors"}}])

      // Apply default tile layer
      mapTiles.default.addTo(this._map);

      // Add layer control
      if (Object.keys(mapTiles.layers).length > 1 || Object.keys(mapTiles.overlays).length > 0) {
        L.control.layers(mapTiles.layers, mapTiles.overlays).addTo(this._map);
      }
      // return reference on generated map
      return this._map;
    };
  })();
})();

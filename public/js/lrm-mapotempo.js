(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
function corslite(url, callback, cors) {
    var sent = false;

    if (typeof window.XMLHttpRequest === 'undefined') {
        return callback(Error('Browser not supported'));
    }

    if (typeof cors === 'undefined') {
        var m = url.match(/^\s*https?:\/\/[^\/]*/);
        cors = m && (m[0] !== location.protocol + '//' + location.domain +
                (location.port ? ':' + location.port : ''));
    }

    var x = new window.XMLHttpRequest();

    function isSuccessful(status) {
        return status >= 200 && status < 300 || status === 304;
    }

    if (cors && !('withCredentials' in x)) {
        // IE8-9
        x = new window.XDomainRequest();

        // Ensure callback is never called synchronously, i.e., before
        // x.send() returns (this has been observed in the wild).
        // See https://github.com/mapbox/mapbox.js/issues/472
        var original = callback;
        callback = function() {
            if (sent) {
                original.apply(this, arguments);
            } else {
                var that = this, args = arguments;
                setTimeout(function() {
                    original.apply(that, args);
                }, 0);
            }
        }
    }

    function loaded() {
        if (
            // XDomainRequest
            x.status === undefined ||
            // modern browsers
            isSuccessful(x.status)) callback.call(x, null, x);
        else callback.call(x, x, null);
    }

    // Both `onreadystatechange` and `onload` can fire. `onreadystatechange`
    // has [been supported for longer](http://stackoverflow.com/a/9181508/229001).
    if ('onload' in x) {
        x.onload = loaded;
    } else {
        x.onreadystatechange = function readystate() {
            if (x.readyState === 4) {
                loaded();
            }
        };
    }

    // Call the callback with the XMLHttpRequest object as an error and prevent
    // it from ever being called again by reassigning it to `noop`
    x.onerror = function error(evt) {
        // XDomainRequest provides no evt parameter
        callback.call(this, evt || true, null);
        callback = function() { };
    };

    // IE9 must have onprogress be set to a unique function.
    x.onprogress = function() { };

    x.ontimeout = function(evt) {
        callback.call(this, evt, null);
        callback = function() { };
    };

    x.onabort = function(evt) {
        callback.call(this, evt, null);
        callback = function() { };
    };

    // GET is the only supported HTTP Verb by XDomainRequest and is the
    // only one supported here.
    x.open('GET', url, true);

    // Send the request. Sending data is not supported.
    x.send(null);
    sent = true;

    return x;
}

if (typeof module !== 'undefined') module.exports = corslite;

},{}],2:[function(require,module,exports){
var polyline = {};

// Based off of [the offical Google document](https://developers.google.com/maps/documentation/utilities/polylinealgorithm)
//
// Some parts from [this implementation](http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/PolylineEncoder.js)
// by [Mark McClure](http://facstaff.unca.edu/mcmcclur/)

function encode(coordinate, factor) {
    coordinate = Math.round(coordinate * factor);
    coordinate <<= 1;
    if (coordinate < 0) {
        coordinate = ~coordinate;
    }
    var output = '';
    while (coordinate >= 0x20) {
        output += String.fromCharCode((0x20 | (coordinate & 0x1f)) + 63);
        coordinate >>= 5;
    }
    output += String.fromCharCode(coordinate + 63);
    return output;
}

// This is adapted from the implementation in Project-OSRM
// https://github.com/DennisOSRM/Project-OSRM-Web/blob/master/WebContent/routing/OSRM.RoutingGeometry.js
polyline.decode = function(str, precision) {
    var index = 0,
        lat = 0,
        lng = 0,
        coordinates = [],
        shift = 0,
        result = 0,
        byte = null,
        latitude_change,
        longitude_change,
        factor = Math.pow(10, precision || 5);

    // Coordinates have variable length when encoded, so just keep
    // track of whether we've hit the end of the string. In each
    // loop iteration, a single coordinate is decoded.
    while (index < str.length) {

        // Reset shift, result, and byte
        byte = null;
        shift = 0;
        result = 0;

        do {
            byte = str.charCodeAt(index++) - 63;
            result |= (byte & 0x1f) << shift;
            shift += 5;
        } while (byte >= 0x20);

        latitude_change = ((result & 1) ? ~(result >> 1) : (result >> 1));

        shift = result = 0;

        do {
            byte = str.charCodeAt(index++) - 63;
            result |= (byte & 0x1f) << shift;
            shift += 5;
        } while (byte >= 0x20);

        longitude_change = ((result & 1) ? ~(result >> 1) : (result >> 1));

        lat += latitude_change;
        lng += longitude_change;

        coordinates.push([lat / factor, lng / factor]);
    }

    return coordinates;
};

polyline.encode = function(coordinates, precision) {
    if (!coordinates.length) return '';

    var factor = Math.pow(10, precision || 5),
        output = encode(coordinates[0][0], factor) + encode(coordinates[0][1], factor);

    for (var i = 1; i < coordinates.length; i++) {
        var a = coordinates[i], b = coordinates[i - 1];
        output += encode(a[0] - b[0], factor);
        output += encode(a[1] - b[1], factor);
    }

    return output;
};

if (typeof module !== undefined) module.exports = polyline;

},{}],3:[function(require,module,exports){
(function (global){
(function() {
  'use strict';

  var L = (typeof window !== "undefined" ? window['L'] : typeof global !== "undefined" ? global['L'] : null),
    corslite = require('corslite'),
    polyline = require('polyline');

  /* jshint camelcase: false */

  L.Routing = L.Routing || {};
  // L.extend(L.Routing, require('./L.Routing.Waypoint'));

  L.Routing.MT = L.Class.extend({
    options: {
      timeout: 30 * 1000,
      polylinePrecision: 5
    },

    initialize: function(options) {
      L.Util.setOptions(this, options);
      this._hints = {
        locations: {}
      };
    },

    route: function(waypoints, callback, context, options) {
      var timedOut = false,
        wps = [],
        url,
        timer,
        wp,
        i;

      url = this.buildRouteUrl(waypoints);

      timer = setTimeout(function() {
        timedOut = true;
        callback.call(context || callback, {
          status: -1,
          message: 'Request timed out.'
        });
      }, this.options.timeout);

      // Create a copy of the waypoints, since they
      // might otherwise be asynchronously modified while
      // the request is being processed.
      for (i = 0; i < waypoints.length; i++) {
        wp = waypoints[i];
        wps.push(new L.Routing.Waypoint(wp.latLng, wp.name, wp.options));
      }

      corslite(url, L.bind(function(err, resp) {
        var data,
          errorMessage,
          statusCode;

        clearTimeout(timer);
        if (!timedOut) {
          errorMessage = 'HTTP request failed: ' + err;
          statusCode = -1;

          if (!err) {
            try {
              data = JSON.parse(resp.responseText);
              try {
                return this._routeDone(data, wps, options, callback, context);
              } catch (ex) {
                statusCode = -3;
                errorMessage = ex.toString();
              }
            } catch (ex) {
              statusCode = -2;
              errorMessage = 'Error parsing response: ' + ex.toString();
            }
          }

          callback.call(context || callback, {
            status: statusCode,
            message: errorMessage
          });
        }
      }, this));

      return this;
    },

    _routeDone: function(response, inputWaypoints, options, callback, context) {
      var alts = [],
          actualWaypoints,
          i,
          route;

      context = context || callback;

      for (i=0; i<response.features.length; i++) {
        route = this._convertRoute(response.features[i]);
        route.inputWaypoints = inputWaypoints;
        route.waypoints = actualWaypoints;
        alts.push(route);
      }

      callback.call(context, null, alts);
    },

    _convertRoute: function(responseRoute) {
      var result = {
          name: '', // TODO
          summary: {
            totalDistance: responseRoute.properties.router.total_distance,
            totalTime: responseRoute.properties.router.total_time
          }
        },
        coordinates = [],
        instructions = [],
        i;

      var coordinates = responseRoute.geometry.coordinates;
      var result, i;

      for (i=coordinates.length - 1; i>=0; i--) {
        coordinates[i] = L.latLng([coordinates[i][1], coordinates[i][0]]);
      }

      result.coordinates = Array.prototype.concat.apply([], coordinates);
      result.instructions = instructions;

      return result;
    },

    buildRouteUrl: function(waypoints) {
      var wp, locs = [];
      for (var i=0; i<waypoints.length; i++) {
        wp = waypoints[i];
        locs.push([wp.latLng.lat, wp.latLng.lng].join(','));
      }
      return this.options.serviceUrl + '/route.geojson?api_key=' + this.options.apiKey +
        '&mode=' + this.options.mode + '&dimension=' + this.options.dimension +
        '&geometry=true&loc=' + locs.join(',')
    }
  });

  L.Routing.mt = function(options) {
    return new L.Routing.MT(options);
  };

  module.exports = L.Routing;
})();

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"corslite":1,"polyline":2}]},{},[3]);

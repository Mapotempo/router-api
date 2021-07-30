function getApiKey() {
  return document.location.search.split('api_key=')[1] || 'demo';
}

var options = {
  betaUrl: "https://geocode.beta.mapotempo.com/0.1/geocode.json",
  prodUrl: "https://geocode.mapotempo.com/0.1/geocode.json",
  serviceUrl: "0.1",
  apiKey: getApiKey()
};

var map = L.mapotempo.map('map').setView([44.837778, -0.579197], 13);

var markers = [];
var markersGroup = L.layerGroup();

var geocodeHandler = function geocodeHandler(resp) {
  markers.length = 0;
  markersGroup.clearLayers();
  if (resp.features.length) {
    feat = resp.features[0];
    markers.push(L.marker(feat.geometry.coordinates.reverse()));
    if (markers.length) {
      markersGroup = L.layerGroup(markers);
      markersGroup.addTo(map);
      var bounds = new L.LatLngBounds([markers[0].getLatLng()]);
      L.Icon.Default.extend({});
      markers[0]
        .setIcon(new L.divIcon({
          html: '',
          iconSize: new L.Point(14, 14),
          className: 'focus-geocoder'
        }))
        .setZIndexOffset(1000)
      map.fitBounds(bounds, {
        padding: [30, 30],
        maxZoom: 15
      });
      setTimeout(function() {
        markersGroup.removeLayer(markers[0]);
      }, 2000);
    }
  } else {
    alert("No result");
  }
};

$('#geocoder-reverse-form').on('submit', function(e) {
  e.preventDefault();
  var country = $('#country-reverse').val();
  var query = $('#q-reverse').val();
  if (country == "" || country == "") return;

  $.ajax({
    url: options.betaUrl + "?api_key=" + options.apiKey,
    method: 'GET',
    data: {
      country: country,
      query: query
    },
    context: document.body
  }).done(function(resp) {
    geocodeHandler(resp);
  });
});

$('#geocoder-form').on('submit', function(e) {
  e.preventDefault();
  coordinates = $("#q").val().split(',');
  geocodeHandler({features: [{geometry: {coordinates: coordinates.reverse()}}]});
});

$("#q-reverse").autocomplete({
  source: function(request, response) {
    $.ajax({
      url: options.betaUrl + "?api_key=" + options.apiKey,
      dataType: "json",
      method: 'PATCH',
      data: {
        country: $('#country-reverse').val(),
        query: request.term
      },
      context: document.body,
      success: function(data) {
        response(data.features.map(function(feature) {
          return feature.properties.geocoding;
        }));
      }
    });
  },
  minLength: 3,
  delay: 500,
  select: function(e, ui) {
    $.ajax({
      url:options.betaUrl + "?api_key=" + options.apiKey,
      method: 'GET',
      data: {
        country: $('#country-reverse').val(),
        query: ui.item.value
      },
      success: function(data) {
        return data.features.map(function(feature) {
          return feature.properties.geocoding;
        });
      },
      context: document.body
    }).done(function(resp) {
      geocodeHandler(resp);
    });
  }
});

$.ajax({
  url: options.serviceUrl + '/capability',
  type: 'GET',
  dataType: 'json',
  data: { api_key: options.apiKey },
  success: function(data, textStatus, jqXHR) {
    init(data);
  }
});

$(function() {
  $('#map').css('height', window.innerHeight - 80);
});

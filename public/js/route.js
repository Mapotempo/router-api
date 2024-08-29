function init(data) {
  var routing;
  var waypoints = [];

  function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  }

  function getMode() {
    return $('#router-mode').val();
  }

  function getDimension() {
    return $('#router-dimension').val();
  }

  function getMotorway() {
    return $('#motorway').is(':checked');
  }

  function getToll() {
    return $('#toll').is(':checked');
  }

  function getLowEmissionZone() {
    return $('#low_emission_zone').is(':checked');
  }

  function resetMap() {
    map.removeControl(routing);
  }

  function initMap() {
    routing = L.Routing.control({
      router: L.Routing.mt($.extend(options, {
        mode: getMode(),
        dimension: getDimension(),
        motorway: getMotorway(),
        toll: getToll(),
        low_emission_zone: getLowEmissionZone(),
      })),
      waypoints: waypoints,
      routeWhileDragging: true
    }).addTo(map);
  }

  function initDimensions(mode) {
    var select = $('#router-dimension');
    select.find('option').remove();
    $.each(data.route, function(i, item) {
      if (item.mode == mode) {
        $.each(item.dimensions, function(k, v) {
          select.append(
            $('<option>').val(v).html(capitalizeFirstLetter(v))
          )
        });
      }
    });
    if(!routing) {
      initMap();
    }
  }

  function createButton(label, container) {
    var btn = L.DomUtil.create('button', '', container);
    btn.setAttribute('type', 'button');
    btn.innerHTML = label;
    return btn;
  }

  $.each(data.route, function(i, item) {
    $('#router-mode').append(
      $('<option>').val(item.mode).html(item.name)
    )
  });

  $('#router-mode').change(function(e) {
    initDimensions(getMode());
  });

  initDimensions(getMode());

  $('select').select2({ minimumResultsForSearch: -1 });
  $('select, input').change(function(e) {
    resetMap();
    initMap();
  });

  routing.getPlan().on('waypointschanged', function(e) {
    waypoints = e.waypoints;
  });

  routing.getPlan().on('waypointdragend', function(e) {
    waypoints = routing.getPlan()._waypoints;
  });

  map.on('click', function(e) {
    var container = L.DomUtil.create('div');
        startBtn = createButton('Start from this location', container),
        destBtn = createButton('Go to this location', container);

    L.popup().setContent(container).setLatLng(e.latlng).openOn(map);

    L.DomEvent.on(startBtn, 'click', function() {
      routing.spliceWaypoints(0, 1, e.latlng);
      waypoints = routing.getPlan()._waypoints;
      map.closePopup();
    });

    L.DomEvent.on(destBtn, 'click', function() {
      routing.spliceWaypoints(routing.getWaypoints().length - 1, 1, e.latlng);
      waypoints = routing.getPlan()._waypoints;
      map.closePopup();
    });
  });
}

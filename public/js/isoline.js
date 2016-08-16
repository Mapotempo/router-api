(function(options) {

  function init(data) {

    var map, line, marker, localization;
    var requests = [];

    function getMode() {
      return $('#router-mode');
    }

    function getDimension() {
      return $('#router-dimension');
    }

    function getSize() {
      return $('#isoline-value');
    }

    function getLoading() {
      return $('#loading');
    }

    function getClearBtn() {
      return $('#clear-btn');
    }

    function getDimensionLabel() {
      return $('#dimension-label');
    }

    function toggleUI(enabled) {
      $.each([getMode(), getDimension(), getSize()], function(i, element) {
        $(element).prop('disabled', !enabled);
      })
    }

    $.each(data.isoline, function(i, item) {
      getMode().append(
        $('<option>').val(item.mode).html(item.name)
      )
    });

    function initDimensions() {
      function capitalizeFirstLetter(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
      }
      function setLabel(mode) {
        switch(mode) {
          case 'time':
            getDimensionLabel().html('Seconds');
            break;
          case 'distance':
            getDimensionLabel().html('Meters');
            break;
        }
      }
      var mode = getMode().val();
      var select = getDimension();
      select.find('option').remove();
      $.each(data.isoline, function(i, item) {
        if (item.mode == mode) {
          $.each(item.dimensions, function(k, v) {
            select.append(
              $('<option>').val(v).html(capitalizeFirstLetter(v))
            )
          });
        }
      });
      select.trigger('change');
      setLabel(select.val());
      select.change(function(e) {
        createIsoline();
        setLabel(select.val());
      });
    }

    function initMap() {
      map = L.map('map').setView(L.latLng(44.823360, -0.651695), 10);
      L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png').addTo(map);
    }

    getSize().change(function(e) {
      createIsoline();
    });

    getMode().change(function(e) {
      createIsoline();
    });

    function resetMap() {
      localization = null;
      if (marker) map.removeLayer(marker);
      if (line) map.removeLayer(line);
      toggleUI(true);
      getLoading().hide();
      $.each(requests, function(i, request) {
        request.abort();
      });
    }

    getClearBtn().click(function(e) {
      resetMap();
    });

    initDimensions();
    initMap();
    $('select').select2({ minimumResultsForSearch: -1 });

    function createIsoline() {
      if (!localization) return;

      if (marker) map.removeLayer(marker);
      marker = L.marker([localization.lat, localization.lng]).addTo(map);
      if (line) map.removeLayer(line);

      var size = parseInt(getSize().val());
      if (isNaN(size)) size = 1000;

      requests.push($.ajax({
        url: options.serviceUrl + '/isoline',
        type: 'GET',
        dataType: 'json',
        data: {
          api_key: options.apiKey,
          loc: [localization.lat, localization.lng].join(","),
          mode: getMode().val(),
          dimension: getDimension().val(),
          size: size
        },
        beforeSend: function(jqXHR, settings) {
          toggleUI(false);
          getLoading().show();
        },
        success: function(data, textStatus, jqXHR) {
          line = L.geoJson(data).addTo(map);
          getLoading().hide();
          toggleUI(true);
        },
        error: function(jqXHR, textStatus, errorThrown) {
          resetMap();
        }
      }));
    }

    map.on('click', function(e) {
      resetMap();
      localization = e.latlng;
      createIsoline();
    });
  }

  $.ajax({
    url: options.serviceUrl + '/capability',
    type: 'GET',
    dataType: 'json',
    data: { api_key: options.apiKey },
    success: function(data, textStatus, jqXHR) {
      init(data);
    }
  });

})({
  serviceUrl: 'https://router.mapotempo.com/0.1',
  apiKey: 'demo'
});

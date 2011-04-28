function init_map(lat, lng, locations) {
	var myOptions = {
		zoom: 14,
      		center: new google.maps.LatLng(lat, lng),
      		mapTypeId: google.maps.MapTypeId.ROADMAP
	};

	var map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);

	//locations: [['regal cinema', 40.71, -74.01, 1], [name, latitude, longitude, z-axis-location], ...]);
	setMarkers(map, locations);
}

function setMarkers(map, locations) {
  // Add markers to the map
  for (var i = 0; i < locations.length; i++) {
    var theater = locations[i];
    var myLatLng = new google.maps.LatLng(theater[1], theater[2]);
    var marker = new google.maps.Marker({
        position: myLatLng,
        map: map,
        //shadow: shadow,
        //icon: image,
        //shape: shape,
        title: theater[0],
        zIndex: theater[3]
    });
  }
}

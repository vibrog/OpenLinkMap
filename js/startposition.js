/*
OpenLinkMap Copyright (C) 2010 Alexander Matheisen
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it under certain conditions.
See olm.openstreetmap.de/info for details.
*/


// set start position by given coordinate or, if possible, by geolocation api
function Startposition(map)
{
    // called when geolocation api caused an errors
	this.geolocationError = function(error)
	{
		if((error.code >= 0) && (error.code <= 3))
			this.setPositionByIp();

		return true;
	}


	// set position by geolocation api
	this.setGeolocatedPosition = function(position)
	{
		// consider accuracy
		var center = getMapLatLon(position.coords.latitude, position.coords.longitude);
		var radius = position.coords.accuracy/2;
		var bounds = new OpenLayers.Bounds(center.lon - radius, center.lat - radius, center.lon + radius, center.lat + radius);
		this.map.zoomToExtent(bounds, true);
	}


	// set position by user's ip address
	this.setPositionByIp = function()
	{
		var self = this;
		var handler = function(request)
			{
				var response = request.responseText;
				// extract coordinates and show position
				if ((response.length > 0) && (response != "NULL"))
				{
					response = response.split(",");
					self.map.panTo(getMapLatLon(response[1], response[0]));
					self.map.zoomTo(10);
					return true;
				}
				else
					return false;
			}

		requestApi("ippos", "", handler);
	}


	this.map = map;

	// if no position set
	if (!this.map.getCenter())
	{
		// position to zoom on if no permalink is given and geolocation isn't supported
		var lat = 51.58248;
		var lon = 15.6501;
		var zoom = 3;
		this.map.setCenter(getMapLatLon(lat, lon), zoom);

		// if geolocation is available
		if ((navigator.geolocation) && (typeof navigator.geolocation.getCurrentPosition != 'undefined'))
		{
			var self = this;
			// call function to jump to geolocated position
			navigator.geolocation.getCurrentPosition(
				function(position)
				{
					self.setGeolocatedPosition(position);
				},
				function(error)
				{
					self.geolocationError(error);
				}
			);
		}
		// set position by user's ip address
		else
			this.setPositionByIp();
	}

	// if position already set, create popup
	else
	{
		if (params['id'] && params['type'])
		{
			var popupPosition = new OpenLayers.LonLat(params['lon'], params['lat']);
			createPopup(params['id'], params['type'], params['lat'], params['lon']);
			this.map.panTo(map.getCenter());
			if (params['ext'])
				showMoreInfo(params['id'], params['type'], lat, lon);
		}
	}

	// load markers without moving the map first
	map.setCenter(map.getCenter());
	// show zoom status without zooming in first
	mapZoomed(null);
}

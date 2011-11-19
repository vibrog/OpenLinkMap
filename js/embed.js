/*
OpenLinkMap Copyright (C) 2010 Alexander Matheisen
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it under certain conditions.
See olm.openstreetmap.de/info for details.
*/


// main function, creates map and layers, controls other functions
function createMap()
{
	root = "http://beta.openlinkmap.org/";
	loading = "<img class='loading' src='"+root+"/img/loading.gif'><br>"+translations['loading'];


	// get time offset to utc
	var now = new Date();
	offset = -(now.getTimezoneOffset() / 60);

	// projections
	wgs84 = new OpenLayers.Projection("EPSG:4326");
	google = new OpenLayers.Projection("EPSG:900913");

	// set language of openlayers
	OpenLayers.Lang.setCode(params['lang']);

	// creating a map
	map = new OpenLayers.Map('mapFrame',
	{
		controls: [],
		projection: google,
		displayProjection: wgs84,
		maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34),
		numZoomLevels: 19,
		maxResolution: 156543.0339,
		units: 'meters'
	});

	// adding some controls
	map.addControl(new OpenLayers.Control.Attribution());
	map.addControl(new OpenLayers.Control.PanZoomBar());
	map.addControl(new OpenLayers.Control.ScaleLine({geodesic:true, maxWidth:200, bottomOutUnits:"", bottomInUnits:""}));
	map.addControl(new OpenLayers.Control.LayerSwitcher());
	map.addControl(new OpenLayers.Control.Navigation({dragPanOptions: {enableKinetic: true}}));

	// adding map layers
	var mapnikMap = new OpenLayers.Layer.OSM.Mapnik("Mapnik",
	{
		transitionEffect: 'resize',
		attribution: 'Map data &copy; <a href="http://www.openstreetmap.org/">OpenStreetMap</a> and contributors <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>'
	});

	// adding hillshading map
	var hillMap = new OpenLayers.Layer.XYZ(translations['hillshading'], "http://toolserver.org/~cmarqu/hill/${z}/${x}/${y}.png",
	{
		sphericalMercator: true,
		opacity: 1,
		visibility: false,
		numZoomLevels: 17,
		transparent: true,
		noOpaq: true,
		isBaseLayer: false,
		attribution: '<a href="http://nasa.gov/">NASA SRTM</a>'
	});

	// adding layers to map
	map.addLayers([mapnikMap, hillMap]);

	// register moving of map
	map.events.register('zoomend', map, mapZoomed);
	// register events of loading marker
	objectsLayer.events.register('loadstart', map, loadStart);
	objectsLayer.events.register('loadend', map, loadEnd);

	// setting start position
	var startposition = new Startposition(map);
}


// shorter than document.get... everywhere
function gEBI(id)
{
	return document.getElementById(id);
}


// returns the current map bbox
function getBounds()
{
	return map.getExtent().transform(map.getProjectionObject(), wgs84).toArray();
}


// returns a new openlayers position, transformed from 4326/WGS84 to map's projection
function getMapLatLon(lat, lon)
{
	return new OpenLayers.LonLat(lon, lat).transform(wgs84, map.getProjectionObject());
}


// event released when map was moved
function mapZoomed(event)
{
	// show message if marker are shown up to this zoom
	if (map.getZoom() < 14)
		setMessageBarInfo(translations['showMarker'], "messageBar", 'messageBarTrue');
	else
		setMessageBarInfo("", "messageBar", 'messageBarFalse');
}


// called when started to load marker
function loadStart(event)
{
	setMessageBarInfo(translations['markerLoading'], "messageBar", "messageBarTrue");
}


// called when marker are loaded
function loadEnd(event)
{
	setMessageBarInfo("", "messageBar", "messageBarFalse");
}


// displays a mesage in the message bar
function setMessageBarInfo(html, element, className)
{
	var messagebar = gEBI(element);

	messagebar.innerHTML = html;
	messagebar.className = className;
}


// updates map's center
function updateMap()
{
	map.updateSize();
	map.setCenter(map.getCenter(), map.getZoom());
}


// add a popup to map and set content
function showPopup(feature)
{
	// first remove all features of nearest objects
	markerLayer.removeAllFeatures();
	var item = feature.cluster[0];

	// create popup
	item.popup = new OpenLayers.Popup.FramedCloud("popup", new OpenLayers.LonLat(item.geometry.x, item.geometry.y), null, loading, {size: new OpenLayers.Size(6,6),offset: new OpenLayers.Pixel(-3,-3)}, true, function(){eventHandlerClick.unselectAll(item);});
	map.addPopup(item.popup);

	if (feature.cluster.length == 1)
	{
		// load popup contents
		var handler = function(request)
			{
				var content = request.responseText;

				if (content != "NULL")
				{
					item.popup.position = new OpenLayers.LonLat(item.geometry.x, item.geometry.y);
					item.popup.setContentHTML(editPopupContent(content, item.popup.position.lat, item.popup.position.lon, item.attributes['type'], item.attributes['id']));
					map.removePopup(item.popup);
					map.addPopup(item.popup);
				}
				else
					map.removePopup(item.popup);
			}
		requestApi("details", "id="+item.attributes['id']+"&type="+item.attributes['type']+"&format=text&offset="+offset+"&lang="+params['lang'], handler);
	}
	else
	{
		cluster++;
		item.popup.contentHTML = "<div id='clusterList"+cluster+"'>"+getNames(feature.cluster)+"</div>";

		// update popup
		map.removePopup(item.popup);
		map.addPopup(item.popup);

		// destroy cluster popup before creating selected popup
		gEBI("clusterList"+cluster).onclick =
			function()
			{
				map.removePopup(item.popup);
			}
	}
}


// removes given popup from map
function hidePopup(feature, popup)
{
	// first remove all features of nearest objects
	markerLayer.removeAllFeatures();
	map.removePopup(feature.cluster[0].popup);
}


// creates a popup at a given position
function createPopup(id, type, lat, lon)
{
	// create popup
	var popup = new OpenLayers.Popup.FramedCloud("popup", getMapLatLon(lat, lon), null, loading, {size: new OpenLayers.Size(6,6),offset: new OpenLayers.Pixel(-3,-3)}, true, function(){map.removePopup(popup);});
	map.addPopup(popup);

	// request details for popup
	var handler = function(request)
		{
			var content = request.responseText;

			if (content != "NULL")
			{
				// set popup content
				popup.setContentHTML(editPopupContent(request.responseText, popup.lonlat.lat, popup.lonlat.lon, type, id));
				map.removePopup(popup);
				map.addPopup(popup);
			}
			else
				map.removePopup(popup);
		}
	requestApi("details", "id="+id+"&type="+type+"&format=text&offset="+offset+"&lang="+params['lang'], handler);
}


// doing some edits on the popup content like adding links
function editPopupContent(content, lat, lon, type, id)
{
	// get bbox of shown map
	var bounds = map.getExtent().transform(map.getProjectionObject(), wgs84).toArray();
	var l = bounds[0];
	var b = bounds[1];
	var r = bounds[2];
	var t = bounds[3];

	// getting latlon in wgs84
	var position = new OpenLayers.LonLat(lon, lat).transform(map.getProjectionObject(), wgs84);
	var lat = position.lat;
	var lon = position.lon;

	var ext = gEBI('detailsBar').className == 'infoBar' ? 1 : 0;

	// add some links to the bottom of a popup
	content += "</div><br /><small id='popupLinks'><b><a id='moreInfoLink' href=\"javascript:showMoreInfo("+id+",'"+type+"', "+lat+", "+lon+")\">"+translations['more']+" >></a></b>"+
		"&nbsp;&nbsp;<a id='permalink' href='"+root+"?"+queryLatLonZoom(lat, lon, map.getZoom())+"&id="+id+"&type="+type+"&ext="+ext+"'>"+translations['permalink']+"</a>"+
		"&nbsp;&nbsp;<a href='http://www.openstreetmap.org/edit?"+queryLatLonZoom(lat, lon, map.getZoom())+"&"+type+"="+id+"' target='_blank'>Potlatch</a>"+
		"&nbsp;&nbsp;<a href='http://localhost:8111/load_and_zoom?left="+l+"&right="+r+"&top="+t+"&bottom="+b+"&select="+type+id+"' target='josm' onclick='return josm(this.href)'>JOSM</a>"+
		"&nbsp;&nbsp;<a href='http://www.openstreetmap.org/browse/"+type+"/"+id+"' target='_blank'>"+translations['details']+"</a></small>";
	return content;
}


// perform a synchron API request
function requestApi(file, query, handler)
{
	if (typeof handler == 'undefined')
		return OpenLayers.Request.GET({url: root+'api/'+file+'.php?'+query, async: false});
	else
		return OpenLayers.Request.GET({url: root+'api/'+file+'.php?'+query, async: true, success: handler});
}


// builds a lat-lon url parameter
function queryLatLon(lat, lon)
{
	return "lat="+lat+"&lon="+lon;
}


// builds a lat-lon url parameter with zoom
function queryLatLonZoom(lat, lon, zoom)
{
	return queryLatLon(lat, lon)+"&zoom="+zoom;
}
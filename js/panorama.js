/*
OpenLinkMap Copyright (C) 2010 Alexander Matheisen
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it under certain conditions.
See olm.openstreetmap.de/info for details.
*/


function Panorama(map, box, bar, searchButton, clearButton, searchOption)
{

	// sets bounded option
	this.setBounded = function(value)
	{
		if (this.bounded == 1)
			this.option.checked = true;
		else
			this.option.checked = false;

		this.bounded = value;
	}
	
	this.resultClick = function(feature)
	{
		var bounds = feature.attributes['bbox'].split(",");
		self.showResult(bounds[2], bounds[0], bounds[3], bounds[1], feature.attributes['lat'], feature.attributes['lon'], feature.attributes['id'], feature.attributes['type'])
	}


	this.map = map;
	this.layer = null;
	this.box = gEBI(box);
	this.searchButton = gEBI(searchButton);

	var self = this;
	this.searchButton.onclick = function()
		{
			self.send();
		};
	this.clearButton.onclick = function()
		{
			self.clear();
		};
		
	this.box.focus();
	
	if (params['bounded'] == 1)
		this.setBounded(1);

	// set up key event
	this.box.onkeypress =
		function(key)
		{
			if (key.which == "13")
				self.send();
		};



	this.layer = new OpenLayers.Layer.Vector(translations['searchresults'],
	{
		projection: wgs84,
		visibility: true,
		transitionEffect: 'resize',
		styleMap: styleMap
	});
	// adding control features
	var self = this;
	searchResultHandler = new OpenLayers.Control.SelectFeature(this.layer,
	{
		onSelect: self.resultClick
	});
	this.map.addControl(searchResultHandler);
	searchResultHandler.activate();

	this.map.addLayer(this.layer);
	
	// perform search request if search parameter is set
	if (params['searchquery'])
	{
		this.box.value = params['searchquery'];
		this.send();
	}
}




		var map = new OpenLayers.Map('fullscreen');
        var options = {numZoomLevels: 3};
        var graphic = new OpenLayers.Layer.Image(
                'City Lights',
                url,
                new OpenLayers.Bounds(-180, -88.759, 180, 88.759),
                new OpenLayers.Size(580, 288),
                options
            );
            
            graphic.events.on({
                loadstart: function() {
                    OpenLayers.Console.log("loadstart");
                },
                loadend: function() {
                    OpenLayers.Console.log("loadend");
                }
            });
            map.addLayers([graphic]);
            map.zoomToMaxExtent();

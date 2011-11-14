/*
OpenLinkMap Copyright (C) 2010 Alexander Matheisen
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it under certain conditions.
See olm.openstreetmap.de/info for details.
*/


function Panorama(frame, image)
{
	// shows the panorama
	this.show = function()
	{
		var self = this;

		this.frame.className = "panorama";
		this.panorama = new OpenLayers.Map(this.frameName);
		this.layer = new OpenLayers.Layer.Image(
			'Panorama',
			this.url,
			new OpenLayers.Bounds(-180, -88.759, 180, 88.759),
			new OpenLayers.Size(580, 288),
			{numZoomLevels: 3}
		);
		this.panorama.addLayer(this.layer);
		this.panorama.zoomToMaxExtent();
		/*
		var fullscreenimg = gEBI("fullscreenImg");
		fullscreenimg.onclick = function()
		{
			self.hide();
		};
		fullscreenimg.title = translations['close'];
		gEBI("fullscreenClose").onclick = function()
		{
			self.hide();
		};
		*/
	}

	// hides the panorama
	this.hide = function()
	{
		var self = this;
		this.frame.className = "fullscreenOut";
		this.frame.innerHTML = "";
		gEBI("fullscreenImg").onclick = function()
		{
			self.show(this.url);
		};
	}

	// inits the events
	this.init = function()
	{
		this.url = getWikipediaImageUrl(gEBI(this.image).src);

		var self = this;
		gEBI(this.image).onclick = function()
		{
			self.show(this.url);
		};
	}


	this.image = image;
	this.frameName = frame;
	this.frame = gEBI(frame);
}
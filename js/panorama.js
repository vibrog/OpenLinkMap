/*
OpenLinkMap Copyright (C) 2010 Alexander Matheisen
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it under certain conditions.
See olm.openstreetmap.de/info for details.
*/


function Panorama(frame, image)
{
	// shows the fullscreen view of an image
	this.show = function()
	{
		var self = this;
		this.frame.className = "fullscreen";
		this.frame.innerHTML = "<img id='fullscreenImg' src='"+this.url+"' />";

		var fullscreenimg = gEBI("fullscreenImg");
		fullscreenimg.onclick = new Function("self.hide();");
		fullscreenimg.title = translations['close'];
		gEBI("fullscreenClose").onclick = new Function("self.hide();");
	}

	// hides the fullscreen view of an image
	this.hide = function()
	{
		var self = this;
		this.frame.className = "fullscreenOut";
		this.frame.innerHTML = "";
		gEBI("fullscreenImg").onclick = new Function("self.show('"+this.url+"');");
	}

	// inits the events
	this.init = function()
	{
		var self = this;
		this.url = getWikipediaImageUrl(this.image.src);

		var map = new OpenLayers.Map(this.frame);
		this.layer = new OpenLayers.Layer.Image(
			'City Lights',
			this.url,
			new OpenLayers.Bounds(-180, -88.759, 180, 88.759), new OpenLayers.Size(580, 288), {numZoomLevels: 3}
		);
		map.addLayers([layer]);
		map.zoomToMaxExtent();

		this.image.onclick = function()
		{
			self.show(this.url);
		};
	}


	this.frame = gEBI(frame);
	this.image = gEBI(image);
}
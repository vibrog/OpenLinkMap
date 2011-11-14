/*
OpenLinkMap Copyright (C) 2010 Alexander Matheisen
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it under certain conditions.
See olm.openstreetmap.de/info for details.
*/


function Fullscreen(frame, image)
{
	// shows the fullscreen view of an image
	this.show = function(url)
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
		this.url = this.image.src;

		var self = this;
		this.image.onclick = function()
		{
			self.show(this.url);
		};
	}


	this.frame = gEBI(frame);
	this.image = gEBI(image);
}
<?php
	/*
	OpenLinkMap Copyright (C) 2010 Alexander Matheisen
	This program comes with ABSOLUTELY NO WARRANTY.
	This is free software, and you are welcome to redistribute it under certain conditions.
	See olm.openstreetmap.de/info for details.
	*/


	// email address to send error reports to
	$mail = "AlexanderMatheisen@ish.de";
	// name of application
	$appname = "OpenLinkMap";
	// id offset between nodes and centroids
	$offset = 1000000000000000;
	$offsetfactorrels = 2;

	// connects do database
	function connectToDatabase($dbname)
	{
		if (!isset($dbname))
		{
			reportError("Database name was not given.");
			return false;
		}

		$connection = pg_pconnect("user=postgres dbname=".$dbname);
		// if connection could not be set up
		if (!$connection)
		{
			reportError("Could not connect to database.");
			return false;
		}

		return $connection;
	}

	// send error report to own mail account
	function reportError($error = "")
	{
		global $mail;
		global $appname;

		// get ip and user agent string
		$header = $_SERVER['HTTP_USER_AGENT'];
		$ip = $_SERVER['REMOTE_ADDR'];

		// generating message
		$message = "An error happened in ".$appname.".at ".date("d.m.Y-H:i", time());
		$message .= "\n\n".$error;
		$message .= "\n\nUser: http://www.utrace.de/?query=".$ip;
		$message .= "\nWith header: ".$header;

		// sending error report by mail to given mail address
		$sended = mail($mail, "Error Report ".$appname, $message);

		// check if mail was being send
		if(!$sended)
			return false;

		return true;
	}

	// copies a file to a database
	function updateOsmFile($filename, $db)
	{
		global $offset;
		global $offsetfactorrels;

		$connection = connectToDatabase($db);
		// if there is no connection
		if (!$connection)
		{
			reportError("Could not connect to database.");
			return false;
		}

		$file = fopen($filename, "r");
		if ($file)
		{
			$tags = '';
			while (!feof($file))
			{
				$line = fgets($file);
				if (substr(trim($line), 0, 5) == "<node")
				{
					$id = explode("\" lat", $line);
					$id = intval(substr($id[0], 11));

					$lat = explode("\" lon=", $line);
					$lat = explode("lat=\"", $lat[0]);
					$lat = $lat[1];

					$lon = explode("\" lon=\"", $line);
					$lon = str_replace("\"/>", "", $lon[1]);
					$lon = str_replace("\">", "", $lon);

					if ($id > $offset*$offsetfactorrels)
						$type = "relations";
					else if ($id > $offset)
						$type = "ways";
					else
						$type = "nodes";

					if ($type == "relations")
						$id = $id-($offset*$offsetfactorrels);
					else if ($type == "ways")
						$id = $id-$offset;
				}
				else if (substr(trim($line), 0, 4) == "<tag")
				{
					$tag = explode("\" v=\"", $line);
					if ($tags == "")
						$tags = '"'.substr($tag[0], 10).'"=>"'.substr($tag[1], 0, -4).'"';
					else
						$tags .= ',"'.substr($tag[0], 10).'"=>"'.substr($tag[1], 0, -4).'"';
				}
				else if (trim($line) == "</node>")
				{
					if ($action == 0)
						$result = pg_query($connection, "INSERT INTO ".$type." (id, tags, geom) VALUES ('".$id."', '".$tags."', GeometryFromText('POINT ( ".$lon." ".$lat." )', 4326 ))");
					else if ($action == 2)
						$result = pg_query($connection, "DELETE FROM ".$type." WHERE (id = '".$id."')");
					else if ($action == 1)
					{
						$result = pg_query($connection, "DELETE FROM ".$type." WHERE (id = '".$id."')");
						$result = pg_query($connection, "INSERT INTO ".$type." (id, tags, geom) VALUES ('".$id."', '".$tags."', GeometryFromText('POINT ( ".$lon." ".$lat." )', 4326 ))");
					}
					$tags = '';
				}
				else if (substr(trim($line), 0, 7) == "<create")
				{
					$action = 0;
				}
				else if (substr(trim($line), 0, 7) == "<modify")
				{
					$action = 1;
				}
				else if (substr(trim($line), 0, 7) == "<delete")
				{
					$action = 2;
				}
			}
		}
		else
		{
			reportError("Could not connect to database.");
		}
		fclose($file);
		pg_close($connection);
		echo "Finished ".$db."...\n";
		return false;
	}

	updateOsmFile("olm.osc", "olm");
	updateOsmFile("nextobjects.osc", "nextobjects");
	echo "Finished.\n";
?>
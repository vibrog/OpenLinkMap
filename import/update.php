<?php
	/*
	OpenLinkMap Copyright (C) 2010 Alexander Matheisen
	This program comes with ABSOLUTELY NO WARRANTY.
	This is free software, and you are welcome to redistribute it under certain conditions.
	See olm.openstreetmap.de/info for details.
	*/


	function connectToDatabase($dbname)
	{
		if (!isset($dbname))
			return false;

		$connection = pg_pconnect("dbname=".$dbname);
		// if connection could not be set up
		if (!$connection)
			return false;

		return $connection;
	}

	// connnecting to database
	$connection = connectToDatabase("olm");
	// if there is no connection
	if (!$connection)
	{
		echo "Cannot connect to database.";
		exit;
	}


	$files = array("nodes", "ways");
	foreach ($types as $type)
	{
		$file = fopen("olm-".$type.".csv", "r");
		if ($file)
		{
			while (!feof($file))
			{
				$action = substr(fgets($file), 0, 1);
				$line = str_replace("\;", "#semikolon#", substr(fgets($file), 2));
				$data = explode(";", $line);

				$tags = str_replace("#semikolon#", ";", $data[1]);
				$tags = str_replace("'", "\\'", $tags);

				if ($action == "<")
					$result = pg_query($connection, "DELETE FROM ".$type." WHERE (id = '".$data[0]."')");
				else if ($action == ">")
					$result = pg_query($connection, "INSERT INTO ".$type." (id, tags, geom) VALUES ('".$data[0]."', '".$tags."', GeometryFromText('POINT ( ".$data[2]." ".$data[3]." )', 4326 ))");
			}
		}
		fclose($file);
		echo "Finished ".$type."...\n";
	}
	pg_close($connection);


	// connnecting to database
	$connection = connectToDatabase("nextobjects");
	// if there is no connection
	if (!$connection)
	{
		echo "Cannot connect to database.";
		exit;
	}

	$file = fopen("nextobjects.csv", "r");
	if ($file)
	{
		while (!feof($file))
		{
			$action = substr(fgets($file), 0, 1);
			$line = str_replace("\;", "#semikolon#", substr(fgets($file), 2));
			$data = explode(";", $line);

			$name = str_replace("#semikolon#", ";", $data[1]);
			$name = str_replace("'", "\\'", $tags);

			if ($action == "<")
				$result = pg_query($connection, "DELETE FROM nextobjects WHERE (name = '".$name."') AND (geom = GeometryFromText('POINT ( ".$data[2]." ".$data[3]." )', 4326 )))");
			else if ($action == ">")
				$result = pg_query($connection, "INSERT INTO nextobjects (type, name, geom) VALUES ('".$data[0]."', '".$name."', GeometryFromText('POINT ( ".$data[2]." ".$data[3]." )', 4326 ))");
		}
	}
	fclose($file);

	pg_close($connection);
 	echo "Finished nextobjects...\n";
	echo "Finished."
?>
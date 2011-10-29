<?php
	/*
	OpenLinkMap Copyright (C) 2010 Alexander Matheisen
	This program comes with ABSOLUTELY NO WARRANTY.
	This is free software, and you are welcome to redistribute it under certain conditions.
	See openlinkmap.org for details.
	*/


	// connects do database
	function connectToDatabase($dbname)
	{
		global $sqlFunctions;

		if (!isset($dbname))
		{
			reportError("Database name was not given.");
			return false;
		}

		$connection = pg_pconnect("dbname=".$dbname." user=olm");
		// if connection could not be set up
		if (!$connection)
		{
			reportError("Could not connect to database.");
			return false;
		}

		return $connection;
	}


	$centroids = array(
		array("point", "ST_Transform(way, 4326)"),
		array("line", "ST_Transform(ST_PointOnSurface(way), 4326)"),
		array("polygon", "ST_Transform(ST_PointOnSurface(way), 4326)")
	);

	$keys = array("wikipedia", "phone", "addr:phone", "contact:phone", "phone:mobile", "contact:mobile", "fax", "addr:fax", "contact:fax", "email", "addr:email", "contact:email", "website", "contact:website", "url", "url:official", "image");

	$mode = "file";
	$action = "";

	if ($mode == "file")
	{
		$output = fopen("list", "w+");
		$input = fopen("diff.osc", "r");
	}
	else if ($mode == "db")
	{
		// connnecting to database
		$connection = connectToDatabase("olm");
		// if there is no connection
		if (!$connection)
			exit;
	}


	while ($line = fgets($input))
	{
		if (preg_match("<create>$", $line))
			$action = "create";
		else if (preg_match("<delete>$", $line))
			$action = "delete";
		else if (preg_match("<modify>$", $line))
			$action = "modify";
		else if (preg_match("<node[ \S]+>$", $line))
			$action = "modify";

		else if re.search(r"<node[ \S]+>$", line):
			match = re.search(r"<node id=.(\d+). version=", line)
			$osmid = match.group(1)
			$osmtype = "point"

		else if re.search(r"<way id=[ \S]+>$", line):
			match = re.search(r"<way id=.(\d+). version=", line)
			$osmid = match.group(1)
			$osmtype = "line"

		else if ($action != "") and ($osmid != 0) and ($osmtype != "") and (re.search(r"<\/node>$", line) or re.search(r"<\/way>$", line))
		{
			osmObject = getLatLon(osmid, osmtype)
			if osmObject != False:
				executeChange(action, osmObject[3], osmObject[2], osmObject[0], osmObject[1])
				print str(osmid)
			$osmid = 0
			$osmtype = ""
			olmobject = False

			if ($mode == "file")
			{
				$result = pg_query($connection, "SELECT foo.id AS id, ST_X(foo.geom) AS x, ST_Y(foo.geom) AS y FROM (SELECT osm_id AS id, ".$centroid[1]." AS geom FROM olm_".$centroid[0]." WHERE (tags ? '".$key."') AND ST_IsValid(way)) AS foo;");
				$response = pg_fetch_all($result);
				if ($response)
				{
					foreach ($response as $element)
						fwrite($file, $element['id']."#".$element['y']."#".$element['x']."\n");
				}
			}
			else if ($mode == "db")
			{
				$result = pg_query($connection, "INSERT INTO ".$centroid[0]." (id, geom) SELECT * FROM dblink('dbname=olm user=olm', 'SELECT osm_id, ".$centroid[1]." AS geom FROM olm_".$centroid[0]."s WHERE (tags ? ''".$key."'') AND ST_IsValid(way);') AS foo(id bigint, way geometry)");
			}
		}
	}

	if ($mode == "file")
	{
		fclose($output);
		fclose($input);
	}
	else if ($mode == "db")
		pg_close($connection);
?>

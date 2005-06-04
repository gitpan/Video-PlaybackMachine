<?php
import_request_variables('P', 'p_');
?>
<HTML>
<HEAD><TITLE>Finish Update Title</TITLE></HEAD>
<BODY>

<?php

$database = pg_pconnect("dbname=playback_machine");
if (!$database) {
  echo "Error: " . pg_last_error();
  exit;
}
if (! pg_query($database, "UPDATE av_files SET title='" . pg_escape_string($p_updated_title) . "' WHERE title='" . pg_escape_string($p_orig_title) . "';")) {
  echo "<p>Error: Couldn't update '$p_orig_title' to '$p_updated_title': " . pg_last_error() . "</P>";
  exit;
}

?>

<H1>Title Updated</H1>

<P>
Updated title '<?php echo $p_orig_title ?>' to title '<?php echo $p_updated_title ?>'.
</P>

<A HREF="playback_titles.php">titles</A>

</BODY>
</HTML>
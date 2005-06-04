<HTML>
<HEAD><TITLE>Movies</TITLE></HEAD>
<BODY>

<H1>Movies</H1>

<TABLE BORDER="1">
<TR>
<TH>Title</TH>
<TH>Length</TH>
</TR>

<?php 

$database = pg_pconnect("dbname=playback_machine");
if (!$database) {
  echo "Error: " . pg_last_error();
  exit;
}

$result = pg_query($database, "SELECT title,duration FROM movies order by title");
if (!$result) {
  echo "Error: " . pg_last_error();

  exit;
}

for ($i = 0; $i < pg_num_rows($result); $i++) {
  $arr = pg_fetch_array($result, $i, PGSQL_NUM);
?>
<TR>
<TD><A HREF="playback_update.php?title=<?php echo urlencode($arr[0]) ?>"><?php echo $arr[0] ?></A></TD>
<TD><?php echo $arr[1] ?></TD>
</TR>
   <?php } ?>

</TABLE>

<p><A HREF="playback_schedule.php">Schedule</A></p>

</BODY>
</HTML>

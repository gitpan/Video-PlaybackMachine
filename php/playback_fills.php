<HTML>
<HEAD><TITLE>Fills</TITLE></HEAD>
<BODY>

<H1>Fills</H1>

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

$result = pg_query($database, "SELECT title,duration FROM fills order by title");
if (!$result) {
  echo "Error: " . pg_last_error();

  exit;
}

for ($i = 0; $i < pg_num_rows($result); $i++) {
  $arr = pg_fetch_array($result, $i, PGSQL_NUM);
?>
<TR>
<TD><?php echo $arr[0] ?></TD>
<TD><?php echo $arr[1] ?></TD>
</TR>
   <?php } ?>

</TABLE>

</BODY>
</HTML>

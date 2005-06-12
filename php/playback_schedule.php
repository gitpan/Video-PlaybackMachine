<?php 

session_start();
if (! $_SESSION['schedule'] ) {
  $_SESSION['schedule'] = $_REQUEST['schedule'];
}

?>

<HTML>
<HEAD><TITLE>Schedule <?php echo $_SESSION['schedule'] ?></TITLE></HEAD>
<BODY>
<H1>Schedule <?php echo $_SESSION['schedule'] ?></H1>

<TABLE BORDER="1">
<TR>
<TH>Start Time</TH>
<TH>Stop Time</TH>
<TH>Title</TH>
<TH>Delete?</TH>
</TR>

<FORM action="playback_delete.php" method="post">
<?php 

$database = pg_pconnect("dbname=playback_machine");
if (!$database) {
  echo "Error: " . pg_last_error();
  exit;
}

$result = pg_query($database, "select start_time, stop_time, title, id FROM schedule_times where schedule='$_SESSION[schedule]' order by start_time");
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
<TD><?php echo $arr[2] ?></TD>
<TD><INPUT TYPE="checkbox" NAME="delete_ids[]" VALUE="<?php echo $arr[3] ?>"/></TD>
</TR>
   <?php } ?>
</TABLE>

<P>
<INPUT TYPE="submit" VALUE="Delete"/>
&nbsp;
<INPUT TYPE="reset" VALUE="Reset" />
</P>

</FORM>
<P/>
<HR/>
<P/>
<FORM action="playback_add.php" method="post">
<TABLE>
<TR>
<TD>
<INPUT TYPE="text" NAME="start_time" VALUE="<?php 

$result = pg_query($database, "select date_trunc('minute', max(stop_time(title,start_time))) + INTERVAL '1 min' FROM content_schedule where schedule='$_SESSION[schedule]'");
if (!$result) {
  echo "Error: " . pg_last_error();
  exit;
}

$arr = pg_fetch_array($result, 0, PGSQL_NUM);

echo $arr[0];


?>"/>
</TD>
<TD>
<SELECT NAME="title">
<OPTION VALUE="">Title</OPTION>
<?php $titles_result = pg_query($database, "SELECT title, duration  FROM movies ORDER BY title");
if (!$titles_result) {
  echo "$Error: " . pg_last_error();
  exit;
}

for ($i = 0; $i < pg_num_rows($titles_result); $i++) {
  $arr = pg_fetch_array($titles_result, $i, PGSQL_NUM);

?>
<OPTION VALUE="<?php echo $arr[0] ?>"><?php echo "$arr[0] ($arr[1])" ?></OPTION>
   <?php } ?>
</SELECT>
</TD>
</TR>
</TABLE>

<P/>

<INPUT TYPE="submit" VALUE="Add"/>

</FORM>

<HR>
<A HREF="playback_titles.php">titles</A>

</BODY>
</HTML>

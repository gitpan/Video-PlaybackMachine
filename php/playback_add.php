<?php session_start() ?>
<HTML>
<HEAD><TITLE>Schedule <?php echo $_SESSION['schedule'] ?></TITLE></HEAD>
<BODY>
<H1>Schedule <?php echo $_SESSION['schedule'] ?></H1>

<P>Adding movie <?php echo $_REQUEST['title'] ?> at <?php echo $_REQUEST['start_time'] ?>.</P>


<?php 

$database = pg_pconnect("dbname=playback_machine");
if (!$database) {
  echo "Error: " . pg_last_error();
  exit;
}


if (! pg_insert($database, "content_schedule", array_merge($_POST, $_SESSION)) ) {
  echo "Error inserting! " . pg_last_error();
  exit;
}

pg_query($database, "NOTIFY content_schedule;");

?>


<P><A HREF="playback_schedule.php">Back to schedule <?php echo $_SESSION['schedule']?></A>

</BODY>
</HTML>


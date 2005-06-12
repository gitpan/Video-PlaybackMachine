<?php
start_session();
import_request_variables('p', 'p_');
?>


<HTML>
<HEAD><TITLE>Schedule <?php echo $_SESSION['schedule'] ?></TITLE></HEAD>
<BODY>
<H1>Schedule <?php echo $_SESSION['schedule'] ?></H1>

<P>Deleting movies...

<?php 

$database = pg_pconnect("dbname=playback_machine");
if (!$database) {
  echo "Error: " . pg_last_error();
  exit;
}

for ($i = 0; $i < count($p_delete_ids); $i++) {
  if (! pg_query($database, "delete from content_schedule where id=$p_delete_ids[$i] and schedule=$_SESSION['schedule'];")) {
    echo "Error: Couldn't delete id '$p_delete_id'<p>";
    exit;
  }
  
}
pg_query($database, "NOTIFY content_schedule;");

?>

done.</P>
<P><A HREF="playback_schedule.php">Return to schedule</A></P>


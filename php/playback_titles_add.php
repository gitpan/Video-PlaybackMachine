<HTML>
<HEAD><TITLE>Movies: Add <?php echo $_POST['title']?></TITLE></HEAD>
<BODY>

<?php

$uploaddir = '/usr/share/playback_machine/';
$uploadfile = $uploaddir . basename($_FILES['uploaded_movie']['name']);

if (move_uploaded_file($_FILES['uploaded_movie']['tmp_name'], $uploadfile)) {
  echo "<H1>Uploaded</H1>";
  $sys_title = escapeshellarg($_POST['title']);
  if ( system("/home/steven/Video/PlaybackMachine/bin/add_movie.pl $uploadfile \'$sys_title\' 2> /tmp/errors") ) {
    echo "<p><B>Success</B></P>";
  }
  else {
    echo "<p>Failure</p>";
  }
}
else {
  echo "<H1>Upload failed</H1>\n";
  print_r($_FILES);
}
?>

<HR>
<A HREF="playback_titles.php">titles</A>

</BODY>
</HTML>
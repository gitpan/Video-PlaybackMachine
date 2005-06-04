<?php
import_request_variables('G', 'g_');
?>
<HTML>
<HEAD><TITLE>Update Title</TITLE></HEAD>
<BODY>

<H1>Update Title</H1>

<FORM ACTION="playback_update_finish.php" METHOD="post">

<P>
<B>Original Title:</B> <?php echo $g_title ?>
<INPUT NAME="orig_title" VALUE="<?php echo $g_title ?>" TYPE="hidden" />
</P>

<P>
<B>Updated Title:</B>
<INPUT NAME="updated_title" VALUE="<?php echo $g_title ?>" TYPE="text" />
</P>

<INPUT TYPE="submit" VALUE="Update"/>

</FORM>

</BODY>
</HTML>
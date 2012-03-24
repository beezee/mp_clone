<?php
require_once('mixpanel-api.php');

$tracker = new MetricsTracker('chtkmpdemo');

$tracker->track('click', array('state' => 'New Jersey', 'source' => '<a href="http://www.google.com">google<a/>', 'ip' => '207.28.28.4'));


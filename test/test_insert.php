<?php
require_once('mixpanel-api.php');

$tracker = new MetricsTracker('chtkmpdemo');

$tracker->track('click', array('state' => 'New Jersey', 'source' => 'google', 'ip' => '207.28.28.4'));


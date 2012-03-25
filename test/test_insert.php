<?php
require_once('mixpanel-api.php');

$tracker = new MetricsTracker('chtkmpdemo');

$tracker->track('contact', array('state' => 'Michigan', 'source' => 'yahoo', 'ip' => '207.28.28.4'));


<?php
require_once('mixpanel-api.php');

$tracker = new MetricsTracker('chtkmpdemo');
$state_list = array("Alabama",  
			"Alaska",  
			"Arizona",  
			"Arkansas",  
			"California",  
			"Colorado",  
			"Connecticut",  
			"Delaware",  
			 "District Of Columbia",  
			"Florida",  
			"Georgia",  
			"Hawaii");

$urls = array(
    'yahoo.com', 'google.com', 'aol.com', 'yelp.com'
);

$events = array(
    'click', 'view', 'purchase', 'contact', 'slideshow'
);

function ip() {
    return rand(128, 240).'.'.rand(0, 255).'.'.rand(0, 255).'.'.rand(100, 200);
}

/*for($i=0; $i < 50; $i++)
{
    $ukey = rand(0, 3);
    $skey = rand(0, 11);
    $ekey = rand(0,4);
    $tracker->track($events[$ekey], array('state' => $state_list[$skey], 'source' => $urls[$ukey], 'ip' => ip()));
}*/

$tracker->track('p', array('val' => '.8065', 'ip' => '10.20.10.20'));



<?php
$filepath = $argv[1] ?? null;

if( empty($filepath) ) {
    throw new \RuntimeException("ip-address-extract: please provide the filepath to extract IPs from");
}

if( !file_exists($filepath) ) {
    throw new \RuntimeException("ip-address-extract: ##$filepath## not found");
}

$fileHandle = fopen($filepath, "r");

$arrIps = [];
while( $line = fgets($fileHandle) ) {

    $arrMatches = [];
    preg_match('/\b(?:\d{1,3}\.){3}\d{1,3}\b/', $line, $arrMatches);
    $address = $arrMatches[0] ?? null;

    if( !empty($address) && empty($arrIps[$address]) ) {

        $arrIps[$address] = 1;

    } elseif( !empty($address) ) {
        $arrIps[$address]++;
    }
}

fclose($fileHandle);

asort($arrIps);

foreach($arrIps as $address => $times) {
    echo "$times,$address" . PHP_EOL;
}

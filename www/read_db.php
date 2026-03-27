<?php
$db = new SQLite3(__DIR__ . '/motor.db');

$var = $argv[1];      // rpm, current, power, bemf
$run = intval($argv[2]);

// Map GUI names → DB column names
if ($var == "bemf") {
    $var = "back_emf";
}

$query = "SELECT $var FROM motor_data WHERE run_id = $run ORDER BY time ASC";

$result = $db->query($query);

while ($row = $result->fetchArray(SQLITE3_NUM)) {
    echo $row[0] . "\n";
}
?>
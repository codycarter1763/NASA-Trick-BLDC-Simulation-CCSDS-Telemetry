<?php

$db = new SQLite3(__DIR__ . '/motor.db');

$result = $db->query("SELECT DISTINCT run_id FROM motor_data ORDER BY run_id");

while ($row = $result->fetchArray(SQLITE3_NUM)) {
    echo $row[0] . "\n";
}
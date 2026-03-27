<?php

$db = new SQLite3(__DIR__ . '/motor.db');

/* Get next run_id */
$result = $db->query("SELECT MAX(run_id) FROM motor_data");
$row = $result->fetchArray();

$run_id = ($row[0] ?? 0) + 1;

/* Save to file so logger can reuse */
file_put_contents(__DIR__ . '/current_run.txt', $run_id);

echo $run_id;
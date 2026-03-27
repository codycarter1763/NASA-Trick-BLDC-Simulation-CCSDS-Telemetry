<?php

$db = new SQLite3(__DIR__ . '/motor.db');

/* Read current run */
$run_id = intval(file_get_contents(__DIR__ . '/current_run.txt'));

/* Insert */
$stmt = $db->prepare("
INSERT INTO motor_data 
(run_id, time, rpm, current, voltage, torque, power, back_emf)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
");

$stmt->bindValue(1, $run_id);
$stmt->bindValue(2, $argv[1]);
$stmt->bindValue(3, $argv[2]);
$stmt->bindValue(4, $argv[3]);
$stmt->bindValue(5, $argv[4]);
$stmt->bindValue(6, $argv[5]);
$stmt->bindValue(7, $argv[6]);
$stmt->bindValue(8, $argv[7]);

$stmt->execute();
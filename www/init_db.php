<?php
echo "Starting DB init...\n";

$db = new SQLite3(__DIR__ . '/motor.db');

if (!$db) {
    echo "Failed to open DB\n";
    exit(1);
}

echo "DB opened\n";

$result = $db->exec("
CREATE TABLE IF NOT EXISTS motor_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    time REAL,
    rpm REAL,
    current REAL,
    voltage REAL,
    torque REAL,
    power REAL,
    back_emf REAL
);
");

if (!$result) {
    echo "Table creation failed\n";
} else {
    echo "Table created successfully\n";
}

echo "Done.\n";
?>
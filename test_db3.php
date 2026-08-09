<?php
require 'backend/api/config/database.php';
$db = getDB();
$stmt = $db->query('DESCRIBE sightings');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

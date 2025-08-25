<?php
// Add this line
date_default_timezone_set('Asia/Kolkata');

// ... the rest of your PHP code will be here ...
/**
 * Test Auto Checkout System
 * Use this file to test the auto checkout functionality manually
 */

echo "<h2>Testing Auto Checkout System</h2>";
echo "<p>Current time: " . date('Y-m-d H:i:s') . "</p>";

// Test database connection first
echo "<h3>1. Testing Database Connection...</h3>";
$host = 'localhost';
$dbname = 'u261459251_software';
$username = 'u261459251_hotel';
$password = 'Vishraj@9884';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $pdo->exec("SET time_zone = '+05:30'");
    echo "✅ Database connection successful!<br>";
} catch(PDOException $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "<br>";
    exit;
}

// Check if tables exist
echo "<h3>2. Checking Database Tables...</h3>";
$tables = ['rooms', 'auto_checkout_logs', 'system_settings'];
foreach ($tables as $table) {
    try {
        $stmt = $pdo->query("SELECT COUNT(*) FROM $table");
        $count = $stmt->fetchColumn();
        echo "✅ Table '$table' exists with $count records<br>";
    } catch (Exception $e) {
        echo "❌ Table '$table' error: " . $e->getMessage() . "<br>";
    }
}

// Check occupied rooms
echo "<h3>3. Checking Occupied Rooms...</h3>";
try {
    $stmt = $pdo->query("SELECT * FROM rooms WHERE status = 'occupied'");
    $occupiedRooms = $stmt->fetchAll();
    
    if (empty($occupiedRooms)) {
        echo "ℹ️ No occupied rooms found. Creating a test booking...<br>";
        
        // Create a test booking
        $stmt = $pdo->prepare("
            UPDATE rooms 
            SET status = 'occupied',
                guest_name = 'Test Guest',
                guest_phone = '1234567890',
                guest_email = 'test@example.com',
                check_in_date = CURDATE(),
                check_in_time = CURTIME(),
                check_out_date = CURDATE(),
                auto_checkout_enabled = 1
            WHERE room_number = '101'
        ");
        $stmt->execute();
        echo "✅ Test booking created for Room 101<br>";
    } else {
        echo "✅ Found " . count($occupiedRooms) . " occupied rooms:<br>";
        foreach ($occupiedRooms as $room) {
            echo "- Room {$room['room_number']}: {$room['guest_name']} (Auto checkout: " . 
                 ($room['auto_checkout_enabled'] ? 'Enabled' : 'Disabled') . ")<br>";
        }
    }
} catch (Exception $e) {
    echo "❌ Error checking rooms: " . $e->getMessage() . "<br>";
}

// Test auto checkout system
echo "<h3>4. Testing Auto Checkout System...</h3>";
try {
    require_once 'includes/auto_checkout.php';
    
    $autoCheckout = new AutoCheckout($pdo);
    $result = $autoCheckout->executeDailyCheckout();
    
    echo "✅ Auto checkout test completed!<br>";
    echo "<strong>Result:</strong> " . $result['status'] . "<br>";
    
    if (isset($result['checked_out'])) {
        echo "<strong>Rooms checked out:</strong> " . $result['checked_out'] . "<br>";
    }
    
    if (isset($result['failed'])) {
        echo "<strong>Failed checkouts:</strong> " . $result['failed'] . "<br>";
    }
    
    if (isset($result['message'])) {
        echo "<strong>Message:</strong> " . $result['message'] . "<br>";
    }
    
    if (isset($result['details'])) {
        echo "<strong>Details:</strong><br>";
        echo "<pre>" . print_r($result['details'], true) . "</pre>";
    }
    
} catch (Exception $e) {
    echo "❌ Auto checkout test failed: " . $e->getMessage() . "<br>";
}

// Check system settings
echo "<h3>5. System Settings...</h3>";
try {
    $stmt = $pdo->query("SELECT * FROM system_settings");
    $settings = $stmt->fetchAll();
    
    foreach ($settings as $setting) {
        echo "<strong>{$setting['setting_key']}:</strong> {$setting['setting_value']}<br>";
    }
} catch (Exception $e) {
    echo "❌ Error reading settings: " . $e->getMessage() . "<br>";
}

echo "<h3>6. Manual Test Links</h3>";
echo "<a href='cron/auto_checkout_cron.php?manual_run=1' target='_blank'>Test Cron Script</a><br>";
echo "<a href='admin/rooms.php'>View Rooms</a><br>";
echo "<a href='admin/auto_checkout_logs.php'>View Checkout Logs</a><br>";

echo "<h3>7. Cron Job Setup</h3>";
echo "<p>Add this to your cPanel cron jobs:</p>";
echo "<code>*/5 * * * * /usr/bin/php " . __DIR__ . "/cron/auto_checkout_cron.php</code>";
?>
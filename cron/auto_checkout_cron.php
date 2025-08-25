<?php
/**
 * Auto Checkout Cron Job for L.P.S.T Hotel Booking System
 * This file should be executed by cron every minute or every 5 minutes
 * 
 * Cron command for Hostinger:
 * */5 * * * * /usr/bin/php /home/u261459251/domains/soft.galaxytribes.in/public_html/cron/auto_checkout_cron.php
 * 
 * Or every minute for more precise timing:
 * * * * * * /usr/bin/php /home/u261459251/domains/soft.galaxytribes.in/public_html/cron/auto_checkout_cron.php
 */

// Set timezone first
date_default_timezone_set('Asia/Kolkata');

// Allow manual testing via browser
if (isset($_GET['manual_run']) || isset($_GET['test'])) {
    // Allow browser access for testing
} else if (php_sapi_name() !== 'cli') {
    // Prevent direct browser access in production
    http_response_code(403);
    die('Access denied. This script should only be run via cron job. Add ?manual_run=1 for testing.');
}

// Direct database connection for cron (no environment variables needed)
$host = 'localhost';
$dbname = 'u261459251_software';
$username = 'u261459251_hotel';
$password = 'Vishraj@9884';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $pdo->exec("SET time_zone = '+05:30'");
} catch(PDOException $e) {
    $error = "Database connection failed: " . $e->getMessage();
    error_log($error);
    
    if (isset($_GET['manual_run']) || isset($_GET['test'])) {
        header('Content-Type: application/json');
        echo json_encode(['status' => 'error', 'message' => $error]);
    } else {
        echo $error . "\n";
    }
    exit;
}

// Include the auto checkout class
require_once dirname(__DIR__) . '/includes/auto_checkout.php';

try {
    $autoCheckout = new AutoCheckout($pdo);
    $result = $autoCheckout->executeDailyCheckout();
    
    // Create logs directory if it doesn't exist
    $logDir = dirname(__DIR__) . '/logs';
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    // Log the result
    $logMessage = date('Y-m-d H:i:s') . " - Auto Checkout Result: " . json_encode($result) . "\n";
    file_put_contents($logDir . '/auto_checkout.log', $logMessage, FILE_APPEND | LOCK_EX);
    
    // Output result
    if (isset($_GET['manual_run']) || isset($_GET['test'])) {
        header('Content-Type: application/json');
        echo json_encode($result);
    } else {
        echo "Auto checkout executed: " . $result['status'] . "\n";
        if (isset($result['checked_out'])) {
            echo "Checked out: " . $result['checked_out'] . " bookings\n";
        }
        if (isset($result['failed'])) {
            echo "Failed: " . $result['failed'] . " bookings\n";
        }
    }
    
} catch (Exception $e) {
    $logDir = dirname(__DIR__) . '/logs';
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    $errorMessage = date('Y-m-d H:i:s') . " - Auto Checkout Error: " . $e->getMessage() . "\n";
    file_put_contents($logDir . '/auto_checkout.log', $errorMessage, FILE_APPEND | LOCK_EX);
    
    if (isset($_GET['manual_run']) || isset($_GET['test'])) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    } else {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
?>
<?php
require_once 'config/database.php';

class AutoCheckout {
    private $pdo;
    
    public function __construct($pdo) {
        $this->pdo = $pdo;
    }
    
    /**
     * Execute daily auto checkout at 10am
     */
    public function executeDailyCheckout() {
        try {
            // Get system settings
            $settings = $this->getSystemSettings();
            
            if (!$settings['auto_checkout_enabled']) {
                return ['status' => 'disabled', 'message' => 'Auto checkout is disabled'];
            }
            
            // Set timezone
            date_default_timezone_set($settings['timezone']);
            
            $currentTime = date('H:i');
            $checkoutTime = $settings['auto_checkout_time'];
            $today = date('Y-m-d');
            
            // For testing purposes, allow manual execution anytime
            // In production, uncomment the time check below
            /*
            if ($currentTime < $checkoutTime) {
                return ['status' => 'not_time', 'message' => 'Not yet time for auto checkout'];
            }
            */
            
            // Check if auto checkout already ran today
            $lastRun = $settings['last_auto_checkout_run'];
            // For testing, allow multiple runs per day
            /*
            if ($lastRun && date('Y-m-d', strtotime($lastRun)) === $today) {
                return ['status' => 'already_run', 'message' => 'Auto checkout already executed today'];
            }
            */
            
            // Get all occupied rooms that need checkout
            $rooms = $this->getRoomsForCheckout();
            $checkedOutRooms = [];
            $failedRooms = [];
            
            foreach ($rooms as $room) {
                $result = $this->checkoutRoom($room);
                if ($result['success']) {
                    $checkedOutRooms[] = $room;
                } else {
                    $failedRooms[] = ['room' => $room, 'error' => $result['error']];
                }
            }
            
            // Update last run time
            $this->updateLastRunTime();
            
            return [
                'status' => 'completed',
                'checked_out' => count($checkedOutRooms),
                'failed' => count($failedRooms),
                'details' => [
                    'successful' => $checkedOutRooms,
                    'failed' => $failedRooms
                ]
            ];
            
        } catch (Exception $e) {
            error_log("Auto checkout error: " . $e->getMessage());
            return ['status' => 'error', 'message' => $e->getMessage()];
        }
    }
    
    /**
     * Get rooms that need to be checked out
     */
    private function getRoomsForCheckout() {
        $today = date('Y-m-d');
        
        $stmt = $this->pdo->prepare("
            SELECT * FROM rooms 
            WHERE status = 'occupied' 
            AND auto_checkout_enabled = 1 
            AND (check_out_date <= ? OR check_out_date IS NULL)
        ");
        $stmt->execute([$today]);
        
        return $stmt->fetchAll();
    }
    
    /**
     * Checkout a specific room
     */
    private function checkoutRoom($room) {
        try {
            $this->pdo->beginTransaction();
            
            // Update room status
            $stmt = $this->pdo->prepare("
                UPDATE rooms 
                SET status = 'cleaning',
                    guest_name = NULL,
                    guest_phone = NULL,
                    guest_email = NULL,
                    check_in_date = NULL,
                    check_in_time = NULL,
                    check_out_date = NULL,
                    check_out_time = NULL,
                    last_auto_checkout = NOW()
                WHERE id = ?
            ");
            $stmt->execute([$room['id']]);
            
            // Log the checkout
            $stmt = $this->pdo->prepare("
                INSERT INTO auto_checkout_logs 
                (room_id, room_number, guest_name, checkout_date, checkout_time, status, notes) 
                VALUES (?, ?, ?, ?, ?, 'success', 'Automatic checkout at 10am')
            ");
            $stmt->execute([
                $room['id'],
                $room['room_number'],
                $room['guest_name'],
                date('Y-m-d'),
                date('H:i:s')
            ]);
            
            $this->pdo->commit();
            return ['success' => true];
            
        } catch (Exception $e) {
            $this->pdo->rollBack();
            
            // Log failed checkout
            $stmt = $this->pdo->prepare("
                INSERT INTO auto_checkout_logs 
                (room_id, room_number, guest_name, checkout_date, checkout_time, status, notes) 
                VALUES (?, ?, ?, ?, ?, 'failed', ?)
            ");
            $stmt->execute([
                $room['id'],
                $room['room_number'],
                $room['guest_name'],
                date('Y-m-d'),
                date('H:i:s'),
                'Error: ' . $e->getMessage()
            ]);
            
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
    
    /**
     * Get system settings
     */
    private function getSystemSettings() {
        $stmt = $this->pdo->query("SELECT setting_key, setting_value FROM system_settings");
        $settings = [];
        
        while ($row = $stmt->fetch()) {
            $settings[$row['setting_key']] = $row['setting_value'];
        }
        
        // Set defaults if not found
        return [
            'auto_checkout_enabled' => $settings['auto_checkout_enabled'] ?? '1',
            'auto_checkout_time' => $settings['auto_checkout_time'] ?? '10:00',
            'timezone' => $settings['timezone'] ?? 'Asia/Kolkata',
            'last_auto_checkout_run' => $settings['last_auto_checkout_run'] ?? ''
        ];
    }
    
    /**
     * Update last run time
     */
    private function updateLastRunTime() {
        $stmt = $this->pdo->prepare("
            UPDATE system_settings 
            SET setting_value = NOW() 
            WHERE setting_key = 'last_auto_checkout_run'
        ");
        $stmt->execute();
    }
}
?>
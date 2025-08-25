-- Auto Checkout System Setup for L.P.S.T Hotel Booking System
-- Run this SQL script in your phpMyAdmin to set up the auto checkout system

-- Create auto_checkout_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS `auto_checkout_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) DEFAULT NULL,
  `resource_id` int(11) NOT NULL,
  `resource_name` varchar(100) NOT NULL,
  `guest_name` varchar(100) DEFAULT NULL,
  `checkout_date` date NOT NULL,
  `checkout_time` time NOT NULL,
  `status` enum('success','failed') DEFAULT 'success',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_checkout_date` (`checkout_date`),
  KEY `idx_resource` (`resource_id`),
  KEY `idx_booking` (`booking_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create or update system_settings table
CREATE TABLE IF NOT EXISTS `system_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text NOT NULL,
  `description` text DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `setting_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default auto checkout settings
INSERT INTO `system_settings` (`setting_key`, `setting_value`, `description`) VALUES
('auto_checkout_time', '10:00', 'Daily automatic checkout time (24-hour format)'),
('auto_checkout_enabled', '1', 'Enable/disable automatic checkout system'),
('timezone', 'Asia/Kolkata', 'System timezone for auto checkout'),
('last_auto_checkout_run', '', 'Last time auto checkout was executed')
ON DUPLICATE KEY UPDATE 
  `setting_value` = VALUES(`setting_value`),
  `description` = VALUES(`description`);

-- Add foreign key constraints if they don't exist
-- Note: These may fail if the referenced tables don't exist, but that's okay
SET foreign_key_checks = 0;

ALTER TABLE `auto_checkout_logs` 
ADD CONSTRAINT `fk_auto_checkout_booking` 
FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL;

ALTER TABLE `auto_checkout_logs` 
ADD CONSTRAINT `fk_auto_checkout_resource` 
FOREIGN KEY (`resource_id`) REFERENCES `resources` (`id`) ON DELETE CASCADE;

SET foreign_key_checks = 1;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS `idx_bookings_status_checkin` ON `bookings` (`status`, `check_in`);
CREATE INDEX IF NOT EXISTS `idx_auto_checkout_logs_date_status` ON `auto_checkout_logs` (`checkout_date`, `status`);

-- Insert sample data to test (optional - remove if not needed)
-- This creates a test booking that can be auto-checked out
-- INSERT INTO `bookings` (`resource_id`, `client_name`, `client_mobile`, `check_in`, `check_out`, `status`, `admin_id`, `created_at`) 
-- VALUES (1, 'Test Guest', '9999999999', DATE_SUB(NOW(), INTERVAL 25 HOUR), NOW(), 'BOOKED', 1, DATE_SUB(NOW(), INTERVAL 25 HOUR));

-- Show current settings
SELECT 'Current Auto Checkout Settings:' as info;
SELECT setting_key, setting_value, description FROM system_settings WHERE setting_key LIKE 'auto_checkout%' OR setting_key = 'timezone';

-- Show table status
SELECT 'Tables Created Successfully:' as info;
SHOW TABLES LIKE '%auto_checkout%';
SHOW TABLES LIKE 'system_settings';
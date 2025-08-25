-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Aug 25, 2025 at 04:40 AM
-- Server version: 10.11.10-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u261459251_software`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`u261459251_hotel`@`127.0.0.1` PROCEDURE `AddColumnToRooms` ()   BEGIN
    -- Add 'room_name' column if it does not exist
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'rooms' AND COLUMN_NAME = 'room_name') THEN
        ALTER TABLE `rooms` ADD COLUMN `room_name` VARCHAR(100) NULL AFTER `room_number`;
    END IF;
END$$

CREATE DEFINER=`u261459251_hotel`@`127.0.0.1` PROCEDURE `ProcessAutoCheckout` ()   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE room_id INT;
    DECLARE guest_name VARCHAR(255);
    DECLARE checkout_cursor CURSOR FOR 
        SELECT r.id, b.guest_name 
        FROM rooms r 
        JOIN bookings b ON r.id = b.room_id 
        WHERE r.status = 'occupied' 
        AND r.auto_checkout_enabled = TRUE
        AND b.checkout_date <= CURDATE();
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Update last run date
    UPDATE auto_checkout_settings SET last_run_date = CURDATE();
    
    OPEN checkout_cursor;
    
    checkout_loop: LOOP
        FETCH checkout_cursor INTO room_id, guest_name;
        IF done THEN
            LEAVE checkout_loop;
        END IF;
        
        -- Update room status to available
        UPDATE rooms SET status = 'available' WHERE id = room_id;
        
        -- Update booking status to completed
        UPDATE bookings SET status = 'completed', actual_checkout_date = NOW() 
        WHERE room_id = room_id AND status = 'active';
        
        -- Log the activity
        INSERT INTO activity_logs (activity_type, room_id, guest_name, description)
        VALUES ('auto_checkout', room_id, guest_name, 
                CONCAT('Automatic checkout completed for room ', room_id, ' - Guest: ', guest_name));
        
    END LOOP;
    
    CLOSE checkout_cursor;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `id` int(11) NOT NULL,
  `activity_type` varchar(50) NOT NULL,
  `room_id` int(11) DEFAULT NULL,
  `guest_name` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`id`, `activity_type`, `room_id`, `guest_name`, `description`, `created_at`) VALUES
(1, 'system', NULL, NULL, 'Auto checkout system initialized successfully', '2025-08-24 09:02:13');

-- --------------------------------------------------------

--
-- Table structure for table `admin_activities`
--

CREATE TABLE `admin_activities` (
  `id` int(11) NOT NULL,
  `admin_id` int(11) NOT NULL,
  `activity_type` varchar(50) NOT NULL,
  `description` text NOT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `room_id` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `admin_activity`
-- (See below for the actual view)
--
CREATE TABLE `admin_activity` (
`admin_id` int(11)
,`admin_name` varchar(50)
,`total_bookings` bigint(21)
,`active_bookings` bigint(21)
,`completed_bookings` bigint(21)
,`advance_bookings` bigint(21)
,`total_revenue` decimal(32,2)
,`last_booking_date` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `auto_checkout_logs`
--

CREATE TABLE `auto_checkout_logs` (
  `id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `room_number` varchar(10) NOT NULL,
  `guest_name` varchar(100) DEFAULT NULL,
  `checkout_date` date NOT NULL,
  `checkout_time` time NOT NULL,
  `status` enum('success','failed') DEFAULT 'success',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `auto_checkout_settings`
--

CREATE TABLE `auto_checkout_settings` (
  `id` int(11) NOT NULL,
  `checkout_time` time DEFAULT '10:00:00',
  `is_enabled` tinyint(1) DEFAULT 1,
  `last_run_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auto_checkout_settings`
--

INSERT INTO `auto_checkout_settings` (`id`, `checkout_time`, `is_enabled`, `last_run_date`, `created_at`, `updated_at`) VALUES
(1, '10:00:00', 1, NULL, '2025-08-24 08:49:55', '2025-08-24 08:49:55'),
(2, '10:00:00', 1, NULL, '2025-08-24 09:02:13', '2025-08-24 09:02:13');

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` int(11) NOT NULL,
  `resource_id` int(11) NOT NULL,
  `client_name` varchar(255) NOT NULL,
  `client_mobile` varchar(15) NOT NULL,
  `client_aadhar` varchar(20) DEFAULT NULL,
  `client_license` varchar(20) DEFAULT NULL,
  `receipt_number` varchar(100) DEFAULT NULL,
  `payment_mode` enum('ONLINE','OFFLINE') DEFAULT 'OFFLINE',
  `check_in` datetime NOT NULL,
  `check_out` datetime NOT NULL,
  `actual_check_in` datetime DEFAULT NULL,
  `actual_check_out` datetime DEFAULT NULL,
  `status` enum('BOOKED','PENDING','COMPLETED','ADVANCED_BOOKED','PAID') DEFAULT 'BOOKED',
  `auto_checkout` tinyint(1) DEFAULT 0,
  `checkout_date` datetime DEFAULT NULL,
  `booked_by_admin` int(11) DEFAULT NULL,
  `booking_type` enum('regular','advanced') DEFAULT 'regular',
  `advance_date` date DEFAULT NULL,
  `advance_payment_mode` enum('ONLINE','OFFLINE') DEFAULT NULL,
  `admin_id` int(11) NOT NULL,
  `is_paid` tinyint(1) DEFAULT 0,
  `total_amount` decimal(10,2) DEFAULT 0.00,
  `payment_notes` text DEFAULT NULL,
  `duration_minutes` int(11) DEFAULT 0,
  `sms_sent` tinyint(1) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `resource_id`, `client_name`, `client_mobile`, `client_aadhar`, `client_license`, `receipt_number`, `payment_mode`, `check_in`, `check_out`, `actual_check_in`, `actual_check_out`, `status`, `auto_checkout`, `checkout_date`, `booked_by_admin`, `booking_type`, `advance_date`, `advance_payment_mode`, `admin_id`, `is_paid`, `total_amount`, `payment_notes`, `duration_minutes`, `sms_sent`, `created_at`, `updated_at`) VALUES
(1, 1, 'vishal', '9765834383', '689265983323', NULL, '1234', 'OFFLINE', '2025-08-21 10:24:00', '2025-08-22 10:10:00', '2025-08-21 04:48:16', '2025-08-21 05:03:04', 'PAID', 0, NULL, NULL, 'regular', NULL, NULL, 3, 1, 0.00, NULL, 0, 0, '2025-08-21 04:48:16', '2025-08-21 05:03:04'),
(2, 7, 'Raj', '9765834383', NULL, NULL, '132', 'OFFLINE', '2025-08-22 12:10:00', '2025-08-23 12:10:00', NULL, '2025-08-23 12:18:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, 'OFFLINE', 3, 0, 0.00, NULL, 0, 0, '2025-08-21 04:49:31', '2025-08-23 06:48:57'),
(3, 2, 'shivaji', '7767834383', '968599888899', 'MH15568565', '7898', 'ONLINE', '2025-08-21 04:57:00', '2025-08-22 04:57:00', '2025-08-21 04:58:44', '2025-08-21 04:59:23', 'PAID', 0, NULL, NULL, 'regular', NULL, NULL, 3, 1, 0.00, NULL, 0, 0, '2025-08-21 04:58:44', '2025-08-21 04:59:23'),
(4, 1, 'MAYUR', '9860500330', NULL, NULL, NULL, 'OFFLINE', '2025-08-21 05:05:00', '2025-08-22 05:05:00', '2025-08-21 05:07:10', '2025-08-21 05:14:14', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 2, 0, 0.00, NULL, 7, 0, '2025-08-21 05:07:10', '2025-08-21 05:14:14'),
(5, 3, 'rohan', '9898565656', NULL, NULL, '13425554', 'OFFLINE', '2025-08-21 11:19:00', '2025-08-22 11:19:00', '2025-08-21 11:20:23', NULL, 'PAID', 0, NULL, NULL, 'regular', NULL, NULL, 3, 1, 700.00, NULL, 0, 0, '2025-08-21 05:50:23', '2025-08-21 05:50:57'),
(6, 10, 'vijay', '9765834383', NULL, NULL, '1111', 'OFFLINE', '2025-08-21 14:01:00', '2025-08-22 14:01:00', '2025-08-21 14:01:36', '2025-08-24 15:15:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-21 08:31:36', '2025-08-24 09:45:10'),
(7, 28, 'Sanjay', '9146533689', NULL, NULL, NULL, 'OFFLINE', '2025-08-21 18:03:00', '2025-08-22 18:03:00', '2025-08-21 18:06:48', '2025-08-24 10:46:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 2, 0, 0.00, NULL, 0, 0, '2025-08-21 12:36:48', '2025-08-24 05:16:56'),
(8, 26, 'Sanjay', '9146533689', NULL, NULL, 'Ok', 'OFFLINE', '2025-08-21 18:10:00', '2025-08-22 18:10:00', '2025-08-21 18:12:02', '2025-08-23 12:23:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 2, 0, 0.00, NULL, 0, 0, '2025-08-21 12:42:02', '2025-08-23 06:51:06'),
(9, 2, 'Deepak', '9403393536', NULL, NULL, '25001', 'OFFLINE', '2025-08-21 18:34:00', '2025-08-22 10:00:00', '2025-08-21 18:35:52', '2025-08-23 11:48:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 2, 0, 0.00, NULL, 0, 0, '2025-08-21 13:05:52', '2025-08-23 06:18:50'),
(10, 27, 'Sanjay', '9860500330', NULL, NULL, 'R55653', 'OFFLINE', '2025-08-25 09:38:00', '2025-08-25 14:38:00', '2025-08-21 18:39:21', '2025-08-21 18:39:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 2, 0, 0.00, NULL, 0, 0, '2025-08-21 13:09:21', '2025-08-21 13:09:37'),
(11, 20, 'hemraj', '9825203256', NULL, NULL, NULL, 'OFFLINE', '2025-08-23 12:19:00', '2025-08-23 12:22:00', '2025-08-23 12:20:03', '2025-08-23 12:37:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-23 06:50:03', '2025-08-23 07:07:32'),
(12, 7, 'rohit', '9865986598', NULL, NULL, NULL, 'OFFLINE', '2025-08-23 12:37:00', '2025-08-24 12:37:00', '2025-08-23 12:38:08', NULL, 'PENDING', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-23 07:08:08', '2025-08-24 08:15:51'),
(13, 5, 'raju', '9865986598', NULL, NULL, NULL, 'OFFLINE', '2025-08-23 12:38:00', '2025-08-24 12:38:00', '2025-08-23 12:38:19', NULL, 'PENDING', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-23 07:08:19', '2025-08-24 08:15:51'),
(14, 17, 'rehman', '9898989898', NULL, NULL, NULL, 'OFFLINE', '2025-08-23 12:38:00', '2025-08-24 12:38:00', '2025-08-23 12:38:29', NULL, 'PENDING', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-23 07:08:29', '2025-08-24 08:15:51'),
(15, 16, 'crish', '9865659898', NULL, NULL, NULL, 'OFFLINE', '2025-08-23 12:38:00', '2025-08-24 12:38:00', '2025-08-23 12:38:41', NULL, 'PENDING', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-23 07:08:41', '2025-08-24 08:15:51'),
(16, 21, 'શિવાજી', '9765326535', NULL, NULL, NULL, 'OFFLINE', '2025-08-23 12:45:00', '2025-08-24 12:45:00', '2025-08-23 12:45:59', '2025-08-24 10:46:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-23 07:15:59', '2025-08-24 05:16:46'),
(17, 6, 'Mayu', '9860500330', NULL, NULL, NULL, 'OFFLINE', '2025-08-23 13:15:00', '2025-08-24 10:00:00', '2025-08-23 13:17:08', NULL, 'PENDING', 0, NULL, NULL, 'regular', NULL, NULL, 2, 0, 0.00, NULL, 0, 0, '2025-08-23 07:47:08', '2025-08-24 08:15:51'),
(18, 11, 'लक्ष्मीनारायण', '9865323232', NULL, NULL, NULL, 'OFFLINE', '2025-08-24 17:18:00', '2025-08-25 17:18:00', '2025-08-24 17:19:07', NULL, 'BOOKED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-24 11:49:07', '2025-08-24 11:49:07'),
(19, 2, 'suresh', '9865989898', NULL, NULL, NULL, 'OFFLINE', '2025-08-24 18:43:00', '2025-08-25 18:43:00', '2025-08-24 18:44:10', NULL, 'BOOKED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-24 13:14:10', '2025-08-24 13:14:10'),
(20, 21, 'swami', '9865989898', NULL, NULL, NULL, 'OFFLINE', '2025-08-24 18:55:00', '2025-08-25 18:55:00', '2025-08-24 18:55:30', NULL, 'BOOKED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-24 13:25:30', '2025-08-24 13:25:30'),
(21, 1, 'badrinath', '9865989898', NULL, NULL, NULL, 'OFFLINE', '2025-08-24 18:55:00', '2025-08-25 18:55:00', '2025-08-24 18:55:42', NULL, 'BOOKED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-24 13:25:42', '2025-08-24 13:25:42'),
(22, 23, 'स्वप्ना', '9865323232', NULL, NULL, NULL, 'OFFLINE', '2025-08-24 19:16:00', '2025-08-25 19:16:00', '2025-08-24 19:16:56', '2025-08-25 10:02:00', 'COMPLETED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-24 13:46:56', '2025-08-25 04:33:10'),
(23, 8, 'સમીર પટેલ', '6532323232', NULL, NULL, NULL, 'OFFLINE', '2025-08-24 19:16:00', '2025-08-25 19:16:00', '2025-08-24 19:17:14', NULL, 'BOOKED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-24 13:47:14', '2025-08-24 13:47:14'),
(24, 18, 'kanti patel', '6555550111', NULL, NULL, NULL, 'OFFLINE', '2025-08-24 19:36:00', '2025-08-25 19:36:00', '2025-08-24 19:37:07', NULL, 'BOOKED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-24 14:07:07', '2025-08-24 14:07:07'),
(25, 24, 'vasant', '9898989999', NULL, NULL, NULL, 'OFFLINE', '2025-08-24 19:37:00', '2025-08-25 19:37:00', '2025-08-24 19:37:20', NULL, 'BOOKED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-24 14:07:20', '2025-08-24 14:07:20'),
(26, 14, 'sawant', '9850503322', NULL, NULL, NULL, 'OFFLINE', '2025-08-25 09:25:00', '2025-08-26 09:25:00', '2025-08-25 09:25:48', NULL, 'BOOKED', 0, NULL, NULL, 'regular', NULL, NULL, 3, 0, 0.00, NULL, 0, 0, '2025-08-25 03:55:48', '2025-08-25 03:55:48');

-- --------------------------------------------------------

--
-- Table structure for table `booking_cancellations`
--

CREATE TABLE `booking_cancellations` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `resource_id` int(11) NOT NULL,
  `cancelled_by` int(11) NOT NULL,
  `cancellation_reason` text DEFAULT NULL,
  `original_client_name` varchar(255) DEFAULT NULL,
  `original_client_mobile` varchar(15) DEFAULT NULL,
  `original_advance_date` date DEFAULT NULL,
  `duration_at_cancellation` int(11) DEFAULT 0,
  `cancelled_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `booking_summary`
-- (See below for the actual view)
--
CREATE TABLE `booking_summary` (
`id` int(11)
,`client_name` varchar(255)
,`client_mobile` varchar(15)
,`client_aadhar` varchar(20)
,`client_license` varchar(20)
,`receipt_number` varchar(100)
,`payment_mode` enum('ONLINE','OFFLINE')
,`resource_name` varchar(100)
,`resource_custom_name` varchar(100)
,`resource_type` enum('room','hall')
,`check_in` datetime
,`check_out` datetime
,`status` enum('BOOKED','PENDING','COMPLETED','ADVANCED_BOOKED','PAID')
,`booking_type` enum('regular','advanced')
,`advance_date` date
,`advance_payment_mode` enum('ONLINE','OFFLINE')
,`total_amount` decimal(10,2)
,`is_paid` tinyint(1)
,`admin_name` varchar(50)
,`created_at` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `email_logs`
--

CREATE TABLE `email_logs` (
  `id` int(11) NOT NULL,
  `recipient_email` varchar(255) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `email_type` enum('EXPORT','REPORT','NOTIFICATION') NOT NULL,
  `status` enum('SENT','FAILED','PENDING') DEFAULT 'PENDING',
  `response_data` text DEFAULT NULL,
  `admin_id` int(11) NOT NULL,
  `sent_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `email_logs`
--

INSERT INTO `email_logs` (`id`, `recipient_email`, `subject`, `email_type`, `status`, `response_data`, `admin_id`, `sent_at`) VALUES
(1, 'galaxytribes@gmail.com', 'L.P.S.T Bookings - Email Configuration Test', 'EXPORT', 'SENT', 'OK', 1, '2025-08-21 09:41:07'),
(2, 'vishrajrathod@gmail.com', 'L.P.S.T Bookings - Email Configuration Test', 'EXPORT', 'SENT', 'OK', 1, '2025-08-22 06:41:18');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `resource_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) DEFAULT 'UPI',
  `payment_status` enum('PENDING','COMPLETED','FAILED') DEFAULT 'PENDING',
  `upi_transaction_id` varchar(100) DEFAULT NULL,
  `payment_notes` text DEFAULT NULL,
  `admin_id` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `booking_id`, `resource_id`, `amount`, `payment_method`, `payment_status`, `upi_transaction_id`, `payment_notes`, `admin_id`, `created_at`) VALUES
(1, 3, 2, 500.00, 'CHECKOUT', 'COMPLETED', NULL, 'Checkout payment for A103 - Duration: 0h 2m', 3, '2025-08-21 04:59:23'),
(2, NULL, 3, 500.00, 'UPI', 'PENDING', NULL, NULL, 3, '2025-08-21 05:01:45'),
(3, NULL, 3, 500.00, 'MANUAL', 'COMPLETED', NULL, 'Manual payment for A104', 3, '2025-08-21 05:01:53'),
(4, 1, 1, 500.00, 'CHECKOUT', 'COMPLETED', NULL, 'Checkout payment for A102 - Duration: 5h 20m', 3, '2025-08-21 05:03:04'),
(5, 4, 1, 500.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for A102 - Duration: 0h 9m', 3, '2025-08-21 05:14:14'),
(6, NULL, 3, 900.00, 'UPI', 'PENDING', NULL, NULL, 3, '2025-08-21 05:17:36'),
(7, 5, 3, 700.00, 'OFFLINE', 'COMPLETED', NULL, 'Payment received for A104 - Method: OFFLINE', 3, '2025-08-21 05:50:57'),
(8, 10, 27, 8600.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for LARGE HALL - Duration: 86h 59m - Checkout: 2025-08-21T18:39', 2, '2025-08-21 13:09:37'),
(9, 9, 2, 4100.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for A103 - Duration: 41h 14m - Checkout: 2025-08-23T11:48', 3, '2025-08-23 06:18:50'),
(10, 2, 7, 2400.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for A108 - Duration: 24h 8m - Checkout: 2025-08-23T12:18', 3, '2025-08-23 06:48:57'),
(11, 8, 26, 4200.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for B003 - Duration: 42h 13m - Checkout: 2025-08-23T12:23', 3, '2025-08-23 06:51:06'),
(12, 11, 20, 500.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for B103 - Duration: 0h 18m - Checkout: 2025-08-23T12:37', 3, '2025-08-23 07:07:32'),
(13, 16, 21, 2200.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for B201 - Duration: 22h 1m - Checkout: 2025-08-24T10:46', 3, '2025-08-24 05:16:46'),
(14, 7, 28, 6400.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for SMALL HALL - Duration: 64h 43m - Checkout: 2025-08-24T10:46', 3, '2025-08-24 05:16:56'),
(15, 6, 10, 7300.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for A203 - Duration: 73h 14m - Checkout: 2025-08-24T15:15', 3, '2025-08-24 09:45:11'),
(16, 22, 23, 1400.00, 'CHECKOUT_COMPLETE', 'COMPLETED', NULL, 'Checkout completed for B203 - Duration: 14h 46m - Checkout: 2025-08-25T10:02', 3, '2025-08-25 04:33:10');

-- --------------------------------------------------------

--
-- Table structure for table `resources`
--

CREATE TABLE `resources` (
  `id` int(11) NOT NULL,
  `type` enum('room','hall') NOT NULL,
  `identifier` varchar(50) NOT NULL,
  `display_name` varchar(100) NOT NULL,
  `custom_name` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `resources`
--

INSERT INTO `resources` (`id`, `type`, `identifier`, `display_name`, `custom_name`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'room', '1', 'ROOM NO 1', 'A102', 1, '2025-08-21 04:24:42', '2025-08-21 04:42:05'),
(2, 'room', '2', 'ROOM NO 2', 'A103', 1, '2025-08-21 04:24:42', '2025-08-21 04:42:13'),
(3, 'room', '3', 'ROOM NO 3', 'A104', 1, '2025-08-21 04:24:42', '2025-08-21 04:43:58'),
(4, 'room', '4', 'ROOM NO 4', 'A105', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:06'),
(5, 'room', '5', 'ROOM NO 5', 'A106', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:10'),
(6, 'room', '6', 'ROOM NO 6', 'A107', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:14'),
(7, 'room', '7', 'ROOM NO 7', 'A108', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:17'),
(8, 'room', '8', 'ROOM NO 8', 'A201', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:31'),
(9, 'room', '9', 'ROOM NO 9', 'A202', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:35'),
(10, 'room', '10', 'ROOM NO 10', 'A203', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:39'),
(11, 'room', '11', 'ROOM NO 11', 'A204', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:43'),
(12, 'room', '12', 'ROOM NO 12', 'A205', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:48'),
(13, 'room', '13', 'ROOM NO 13', 'A206', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:53'),
(14, 'room', '14', 'ROOM NO 14', 'A207', 1, '2025-08-21 04:24:42', '2025-08-21 04:44:58'),
(15, 'room', '15', 'ROOM NO 15', 'A208', 1, '2025-08-21 04:24:42', '2025-08-21 04:45:02'),
(16, 'room', '16', 'ROOM NO 16', 'A209', 1, '2025-08-21 04:24:42', '2025-08-21 04:45:08'),
(17, 'room', '17', 'ROOM NO 17', 'A210', 1, '2025-08-21 04:24:42', '2025-08-21 04:45:17'),
(18, 'room', '18', 'ROOM NO 18', 'B101', 1, '2025-08-21 04:24:42', '2025-08-21 04:45:27'),
(19, 'room', '19', 'ROOM NO 19', 'B102', 1, '2025-08-21 04:24:42', '2025-08-21 04:45:33'),
(20, 'room', '20', 'ROOM NO 20', 'B103', 1, '2025-08-21 04:24:42', '2025-08-21 04:45:42'),
(21, 'room', '21', 'ROOM NO 21', 'B201', 1, '2025-08-21 04:24:42', '2025-08-21 04:45:51'),
(22, 'room', '22', 'ROOM NO 22', 'B202', 1, '2025-08-21 04:24:42', '2025-08-21 04:46:00'),
(23, 'room', '23', 'ROOM NO 23', 'B203', 1, '2025-08-21 04:24:42', '2025-08-21 04:46:07'),
(24, 'room', '24', 'ROOM NO 24', 'B001', 1, '2025-08-21 04:24:42', '2025-08-21 04:46:15'),
(25, 'room', '25', 'ROOM NO 25', 'B002', 1, '2025-08-21 04:24:42', '2025-08-21 04:46:22'),
(26, 'room', '26', 'ROOM NO 26', 'B003', 1, '2025-08-21 04:24:42', '2025-08-21 04:46:33'),
(27, 'hall', 'SMALL_PARTY_HALL', 'SMALL PARTY HALL', 'LARGE HALL', 1, '2025-08-21 04:24:42', '2025-08-21 04:46:54'),
(28, 'hall', 'BIG_PARTY_HALL', 'BIG PARTY HALL', 'SMALL HALL', 1, '2025-08-21 04:24:42', '2025-08-21 04:46:43');

-- --------------------------------------------------------

--
-- Table structure for table `rooms`
--

CREATE TABLE `rooms` (
  `id` int(11) NOT NULL,
  `room_number` varchar(50) NOT NULL,
  `room_name` varchar(100) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'available',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `auto_checkout_enabled` tinyint(1) DEFAULT 1,
  `auto_checkout_notice` text DEFAULT 'Auto Checkout Daily 10am',
  `guest_name` varchar(255) DEFAULT NULL,
  `check_out_date` datetime DEFAULT NULL,
  `guest_phone` varchar(20) DEFAULT NULL,
  `guest_email` varchar(255) DEFAULT NULL,
  `check_in_date` datetime DEFAULT NULL,
  `check_in_time` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `settings`
--

INSERT INTO `settings` (`id`, `setting_key`, `setting_value`, `updated_by`, `updated_at`) VALUES
(1, 'upi_id', 'vishrajrathod@kotak', 1, '2025-08-21 05:17:25'),
(2, 'upi_name', 'L.P.S.T Bookings', 1, '2025-08-21 05:17:25'),
(3, 'hotel_name', 'L.P.S.T Hotel', 1, '2025-08-21 05:16:14'),
(4, 'sms_api_url', 'https://api.textlocal.in/send/', 1, '2025-08-21 05:16:14'),
(5, 'sms_api_key', 'YOUR_SMS_API_KEY_HERE', 1, '2025-08-21 05:16:14'),
(6, 'sms_sender_id', 'LPSTHT', 1, '2025-08-21 05:16:14'),
(7, 'smtp_host', 'smtp.hostinger.com', 1, '2025-08-21 05:06:15'),
(8, 'smtp_port', '465', 1, '2025-08-21 05:06:15'),
(9, 'smtp_username', 'info@gtai.in', 1, '2025-08-21 07:18:59'),
(10, 'smtp_password', 'Vishraj@9884', 1, '2025-08-21 07:10:30'),
(11, 'smtp_encryption', 'ssl', 1, '2025-08-21 07:10:30'),
(12, 'owner_email', 'info@gtai.in', 1, '2025-08-21 05:48:28'),
(13, 'system_timezone', 'Asia/Kolkata', NULL, '2025-08-21 04:24:42'),
(14, 'auto_refresh_interval', '30', NULL, '2025-08-21 04:24:42'),
(15, 'checkout_grace_hours', '24', NULL, '2025-08-21 04:24:42'),
(16, 'default_room_rate', '1000.00', NULL, '2025-08-21 04:24:42'),
(17, 'default_hall_rate', '5000.00', NULL, '2025-08-21 04:24:42'),
(19, 'qr_image', '', NULL, '2025-08-21 04:30:15');

-- --------------------------------------------------------

--
-- Table structure for table `sms_logs`
--

CREATE TABLE `sms_logs` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `mobile_number` varchar(15) NOT NULL,
  `message` text NOT NULL,
  `sms_type` enum('BOOKING','CHECKOUT','CANCELLATION','ADVANCE') NOT NULL,
  `status` enum('SENT','FAILED','PENDING') DEFAULT 'PENDING',
  `response_data` text DEFAULT NULL,
  `admin_id` int(11) NOT NULL,
  `sent_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sms_logs`
--

INSERT INTO `sms_logs` (`id`, `booking_id`, `mobile_number`, `message`, `sms_type`, `status`, `response_data`, `admin_id`, `sent_at`) VALUES
(1, 1, '9765834383', 'Dear vishal, your room A102 booked successfully at 21-Aug-2025 10:24 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-21 04:48:16'),
(2, 2, '9765834383', 'Dear Raj, your advance booking for A108 on 22-Aug-2025 at L.P.S.T Hotel confirmed. Thank you!', 'ADVANCE', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-21 04:49:31'),
(3, 3, '7767834383', 'Dear shivaji, your room A103 booked successfully at 21-Aug-2025 04:57 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-21 04:58:44'),
(4, 3, '7767834383', 'Dear shivaji, checkout from A103 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-21 04:59:23'),
(5, 1, '9765834383', 'Dear vishal, checkout from A102 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-21 05:03:04'),
(6, 4, '9860500330', 'Dear MAYUR, your room A102 booked successfully at 21-Aug-2025 05:05 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-21 05:07:10'),
(7, 4, '9860500330', 'Dear MAYUR, checkout from A102 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-21 05:14:14'),
(9, 5, '9898565656', 'Dear rohan, your room A104 booked successfully at 21-Aug-2025 11:19 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-21 05:50:23'),
(11, 6, '9765834383', 'Dear vijay, your room A203 booked successfully at 21-Aug-2025 14:01 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-21 08:31:36'),
(12, 7, '9146533689', 'Dear Sanjay, your room SMALL HALL booked successfully at 21-Aug-2025 18:03 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-21 12:36:48'),
(13, 8, '9146533689', 'Dear Sanjay, your room B003 booked successfully at 21-Aug-2025 18:10 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-21 12:42:02'),
(14, 9, '9403393536', 'Dear Deepak, your room A103 booked successfully at 21-Aug-2025 18:34 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-21 13:05:52'),
(15, 10, '9860500330', 'Dear Sanjay, your room LARGE HALL booked successfully at 25-Aug-2025 09:38 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-21 13:09:21'),
(16, 10, '9860500330', 'Dear Sanjay, checkout from LARGE HALL completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-21 13:09:37'),
(17, 9, '9403393536', 'Dear Deepak, checkout from A103 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-23 06:18:50'),
(18, 2, '9765834383', 'Dear Raj, checkout from A108 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-23 06:48:57'),
(19, 11, '9825203256', 'Dear hemraj, your room B103 booked successfully at 23-Aug-2025 12:19 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-23 06:50:03'),
(20, 8, '9146533689', 'Dear Sanjay, checkout from B003 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-23 06:51:06'),
(21, 11, '9825203256', 'Dear hemraj, checkout from B103 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-23 07:07:32'),
(22, 12, '9865986598', 'Dear rohit, your room A108 booked successfully at 23-Aug-2025 12:37 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-23 07:08:08'),
(23, 13, '9865986598', 'Dear raju, your room A106 booked successfully at 23-Aug-2025 12:38 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-23 07:08:19'),
(24, 14, '9898989898', 'Dear rehman, your room A210 booked successfully at 23-Aug-2025 12:38 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-23 07:08:29'),
(25, 15, '9865659898', 'Dear crish, your room A209 booked successfully at 23-Aug-2025 12:38 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-23 07:08:41'),
(26, 16, '9765326535', 'Dear શિવાજી, your room B201 booked successfully at 23-Aug-2025 12:45 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-23 07:15:59'),
(27, 17, '9860500330', 'Dear Mayu, your room A107 booked successfully at 23-Aug-2025 13:15 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-23 07:47:08'),
(28, 16, '9765326535', 'Dear શિવાજી, checkout from B201 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 05:16:46'),
(29, 7, '9146533689', 'Dear Sanjay, checkout from SMALL HALL completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 2, '2025-08-24 05:16:56'),
(30, 6, '9765834383', 'Dear vijay, checkout from A203 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 09:45:10'),
(31, 18, '9865323232', 'Dear लक्ष्मीनारायण, your room A204 booked successfully at 24-Aug-2025 17:18 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 11:49:07'),
(32, 19, '9865989898', 'Dear suresh, your room A103 booked successfully at 24-Aug-2025 18:43 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 13:14:10'),
(33, 20, '9865989898', 'Dear swami, your room B201 booked successfully at 24-Aug-2025 18:55 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 13:25:30'),
(34, 21, '9865989898', 'Dear badrinath, your room A102 booked successfully at 24-Aug-2025 18:55 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 13:25:42'),
(35, 22, '9865323232', 'Dear स्वप्ना, your room B203 booked successfully at 24-Aug-2025 19:16 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 13:46:56'),
(36, 23, '6532323232', 'Dear સમીર પટેલ, your room A201 booked successfully at 24-Aug-2025 19:16 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 13:47:14'),
(37, 24, '6555550111', 'Dear kanti patel, your room B101 booked successfully at 24-Aug-2025 19:36 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 14:07:07'),
(38, 25, '9898989999', 'Dear vasant, your room B001 booked successfully at 24-Aug-2025 19:37 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-24 14:07:20'),
(39, 26, '9850503322', 'Dear sawant, your room A207 booked successfully at 25-Aug-2025 09:25 at L.P.S.T Hotel. Thank you!', 'BOOKING', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-25 03:55:48'),
(40, 22, '9865323232', 'Dear स्वप्ना, checkout from B203 completed at L.P.S.T Hotel. Thank you for your visit! Please visit again.', 'CHECKOUT', 'FAILED', '{\"errors\":[{\"code\":3,\"message\":\"Invalid login details\"}],\"status\":\"failure\"}', 3, '2025-08-25 04:33:10');

-- --------------------------------------------------------

--
-- Table structure for table `system_logs`
--

CREATE TABLE `system_logs` (
  `id` int(11) NOT NULL,
  `log_type` varchar(50) NOT NULL,
  `message` text NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `system_logs`
--

INSERT INTO `system_logs` (`id`, `log_type`, `message`, `created_at`) VALUES
(1, 'error', 'Auto checkout failed: SQLSTATE[42S22]: Column not found: 1054 Unknown column \'b.check_in_date\' in \'WHERE\'', '2025-08-24 18:22:50');

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text NOT NULL,
  `description` text DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `system_settings`
--

INSERT INTO `system_settings` (`id`, `setting_key`, `setting_value`, `description`, `updated_at`) VALUES
(1, 'auto_checkout_time', '10:00', 'Daily automatic checkout time (24-hour format)', '2025-08-24 09:40:38'),
(2, 'auto_checkout_enabled', '1', 'Enable/disable automatic checkout system', '2025-08-24 09:40:38'),
(3, 'timezone', 'Asia/Kolkata', 'System timezone for auto checkout', '2025-08-24 09:40:38'),
(4, 'last_auto_checkout_run', '2025-08-25 10:09:07', 'Last time auto checkout was executed', '2025-08-25 04:39:07');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('OWNER','ADMIN') NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `role`, `created_at`, `updated_at`) VALUES
(1, 'owner', '$2y$10$cGb5zSziSATjboGnZDyGxuOPx/AgImgSGnatdAnz29seZuBUvleyq', 'OWNER', '2025-08-21 04:24:42', '2025-08-21 04:35:14'),
(2, 'mayur', '$2y$10$XjkpdHRcaxxPJQoSVdhz1.SaP/ha3ELyOM4lbjYT3orAWmLeqUYGu', 'ADMIN', '2025-08-21 04:24:42', '2025-08-21 04:36:49'),
(3, 'raj', '$2y$10$06/SKVSQpg/bUwQMqsog/.oq4ZBsatlUTAh6VRSISZA97kUUnC91C', 'ADMIN', '2025-08-21 04:24:42', '2025-08-21 04:37:57'),
(4, 'admin3', '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBxGkgaHqz3nO6', 'ADMIN', '2025-08-21 04:24:42', '2025-08-21 04:24:42'),
(5, 'admin4', '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBxGkgaHqz3nO6', 'ADMIN', '2025-08-21 04:24:42', '2025-08-21 04:24:42'),
(6, 'admin5', '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBxGkgaHqz3nO6', 'ADMIN', '2025-08-21 04:24:42', '2025-08-21 04:24:42'),
(7, 'admin6', '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBxGkgaHqz3nO6', 'ADMIN', '2025-08-21 04:24:42', '2025-08-21 04:24:42');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_activity_type` (`activity_type`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `admin_activities`
--
ALTER TABLE `admin_activities`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_admin_activities_admin` (`admin_id`),
  ADD KEY `idx_admin_activities_date` (`created_at`),
  ADD KEY `idx_admin_activities_type` (`activity_type`);

--
-- Indexes for table `auto_checkout_logs`
--
ALTER TABLE `auto_checkout_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `room_id` (`room_id`);

--
-- Indexes for table `auto_checkout_settings`
--
ALTER TABLE `auto_checkout_settings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_bookings_resource_status` (`resource_id`,`status`),
  ADD KEY `idx_bookings_advance_date` (`advance_date`),
  ADD KEY `idx_bookings_admin` (`admin_id`),
  ADD KEY `idx_bookings_mobile` (`client_mobile`);

--
-- Indexes for table `booking_cancellations`
--
ALTER TABLE `booking_cancellations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `resource_id` (`resource_id`),
  ADD KEY `cancelled_by` (`cancelled_by`);

--
-- Indexes for table `email_logs`
--
ALTER TABLE `email_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_email_logs_admin` (`admin_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `admin_id` (`admin_id`),
  ADD KEY `idx_payments_resource` (`resource_id`);

--
-- Indexes for table `resources`
--
ALTER TABLE `resources`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_resource` (`type`,`identifier`),
  ADD KEY `idx_resources_active` (`is_active`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `room_number` (`room_number`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `sms_logs`
--
ALTER TABLE `sms_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `admin_id` (`admin_id`),
  ADD KEY `idx_sms_logs_booking` (`booking_id`);

--
-- Indexes for table `system_logs`
--
ALTER TABLE `system_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_system_logs_type` (`log_type`),
  ADD KEY `idx_system_logs_date` (`created_at`);

--
-- Indexes for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `admin_activities`
--
ALTER TABLE `admin_activities`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `auto_checkout_logs`
--
ALTER TABLE `auto_checkout_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `auto_checkout_settings`
--
ALTER TABLE `auto_checkout_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `booking_cancellations`
--
ALTER TABLE `booking_cancellations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `email_logs`
--
ALTER TABLE `email_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `resources`
--
ALTER TABLE `resources`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `settings`
--
ALTER TABLE `settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=129;

--
-- AUTO_INCREMENT for table `sms_logs`
--
ALTER TABLE `sms_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `system_logs`
--
ALTER TABLE `system_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

-- --------------------------------------------------------

--
-- Structure for view `admin_activity`
--
DROP TABLE IF EXISTS `admin_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u261459251_hotel`@`127.0.0.1` SQL SECURITY DEFINER VIEW `admin_activity`  AS SELECT `u`.`id` AS `admin_id`, `u`.`username` AS `admin_name`, count(`b`.`id`) AS `total_bookings`, count(case when `b`.`status` = 'BOOKED' then 1 end) AS `active_bookings`, count(case when `b`.`status` = 'COMPLETED' then 1 end) AS `completed_bookings`, count(case when `b`.`booking_type` = 'advanced' then 1 end) AS `advance_bookings`, sum(case when `b`.`is_paid` = 1 then `b`.`total_amount` else 0 end) AS `total_revenue`, max(`b`.`created_at`) AS `last_booking_date` FROM (`users` `u` left join `bookings` `b` on(`u`.`id` = `b`.`admin_id`)) WHERE `u`.`role` = 'ADMIN' GROUP BY `u`.`id`, `u`.`username` ;

-- --------------------------------------------------------

--
-- Structure for view `booking_summary`
--
DROP TABLE IF EXISTS `booking_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u261459251_hotel`@`127.0.0.1` SQL SECURITY DEFINER VIEW `booking_summary`  AS SELECT `b`.`id` AS `id`, `b`.`client_name` AS `client_name`, `b`.`client_mobile` AS `client_mobile`, `b`.`client_aadhar` AS `client_aadhar`, `b`.`client_license` AS `client_license`, `b`.`receipt_number` AS `receipt_number`, `b`.`payment_mode` AS `payment_mode`, `r`.`display_name` AS `resource_name`, `r`.`custom_name` AS `resource_custom_name`, `r`.`type` AS `resource_type`, `b`.`check_in` AS `check_in`, `b`.`check_out` AS `check_out`, `b`.`status` AS `status`, `b`.`booking_type` AS `booking_type`, `b`.`advance_date` AS `advance_date`, `b`.`advance_payment_mode` AS `advance_payment_mode`, `b`.`total_amount` AS `total_amount`, `b`.`is_paid` AS `is_paid`, `u`.`username` AS `admin_name`, `b`.`created_at` AS `created_at` FROM ((`bookings` `b` join `resources` `r` on(`b`.`resource_id` = `r`.`id`)) join `users` `u` on(`b`.`admin_id` = `u`.`id`)) ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `auto_checkout_logs`
--
ALTER TABLE `auto_checkout_logs`
  ADD CONSTRAINT `auto_checkout_logs_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`resource_id`) REFERENCES `resources` (`id`),
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`admin_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `booking_cancellations`
--
ALTER TABLE `booking_cancellations`
  ADD CONSTRAINT `booking_cancellations_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`),
  ADD CONSTRAINT `booking_cancellations_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resources` (`id`),
  ADD CONSTRAINT `booking_cancellations_ibfk_3` FOREIGN KEY (`cancelled_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `email_logs`
--
ALTER TABLE `email_logs`
  ADD CONSTRAINT `email_logs_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`),
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resources` (`id`),
  ADD CONSTRAINT `payments_ibfk_3` FOREIGN KEY (`admin_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `settings`
--
ALTER TABLE `settings`
  ADD CONSTRAINT `settings_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `sms_logs`
--
ALTER TABLE `sms_logs`
  ADD CONSTRAINT `sms_logs_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`),
  ADD CONSTRAINT `sms_logs_ibfk_2` FOREIGN KEY (`admin_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

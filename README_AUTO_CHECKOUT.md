# Auto Checkout System Setup Guide for L.P.S.T Hotel

## 🎯 What This System Does

The Auto Checkout System automatically checks out all active bookings daily at a configured time (default: 10:00 AM). This eliminates the need for manual checkout and ensures consistent billing.

## 📋 Setup Steps (For Beginners)

### Step 1: Database Setup
1. Open **phpMyAdmin** in your Hostinger control panel
2. Select your database: `u261459251_software`
3. Click on **SQL** tab
4. Copy and paste the entire content from `setup_auto_checkout.sql` file
5. Click **Go** to execute the SQL

### Step 2: Test the System
1. Open your website: `https://soft.galaxytribes.in/test_auto_checkout.php`
2. Check if all tests pass (green checkmarks)
3. If any errors, contact support

### Step 3: Setup Cron Job in Hostinger
1. Login to **Hostinger Control Panel**
2. Go to **Advanced** → **Cron Jobs**
3. Click **Create New Cron Job**
4. Set the schedule: `*/5 * * * *` (every 5 minutes)
5. Set the command: 
   ```
   /usr/bin/php /home/u261459251/domains/soft.galaxytribes.in/public_html/cron/auto_checkout_cron.php
   ```
6. Click **Create**

### Step 4: Configure Auto Checkout Time
1. Login to your admin panel
2. Go to **Auto Checkout** in the navigation
3. Set your preferred checkout time (default: 10:00 AM)
4. Enable the system
5. Click **Update Settings**

## 🔧 How It Works

### Daily Process:
1. **Cron job runs every 5 minutes** (but only executes at the configured time)
2. **At 10:00 AM daily** (or your configured time):
   - System finds all active bookings (BOOKED or PENDING status)
   - Calculates duration and amount for each booking
   - Updates booking status to COMPLETED
   - Creates payment records
   - Sends SMS notifications to guests
   - Logs all activities

### Billing Calculation:
- **Rooms**: ₹100 per hour
- **Halls**: ₹500 per hour
- Duration is calculated from check-in to checkout time
- Partial hours are rounded up

## 📊 Features

### Admin Panel Features:
- **Auto Checkout Settings**: Configure time and enable/disable
- **Live Statistics**: Today's and weekly auto checkout stats
- **Detailed Logs**: View all auto checkout activities
- **Manual Testing**: Test the system anytime
- **Status Monitoring**: Real-time system status

### Grid View Features:
- **Auto Checkout Notice**: Visible on main grid
- **Resource Status**: Shows auto checkout info on each room/hall
- **Real-time Updates**: Status updates automatically

## 🚨 Important Notes

### For Hostinger Users:
- Use the exact cron command provided above
- The system timezone is set to `Asia/Kolkata`
- Logs are stored in `/logs/auto_checkout.log`

### Security:
- Only admins can access auto checkout settings
- CSRF protection on all forms
- Database transactions ensure data integrity

### Troubleshooting:
1. **If auto checkout doesn't run**: Check cron job setup
2. **If bookings aren't found**: Verify booking status is BOOKED or PENDING
3. **If SMS fails**: Check SMS configuration in owner settings
4. **If database errors**: Run the SQL setup file again

## 📱 SMS Notifications

When auto checkout runs, guests receive SMS like:
```
Dear [Guest Name], checkout from [Room/Hall] completed at L.P.S.T Hotel. 
Thank you for your visit! Please visit again.
```

## 💰 Payment Integration

- Automatic payment calculation based on duration
- Payment records created with AUTO_CHECKOUT method
- Revenue tracking in admin dashboard
- Export capabilities for accounting

## 🔄 Manual Override

Admins can:
- Manually run auto checkout anytime using the test button
- Override auto checkout time
- Disable auto checkout temporarily
- View detailed logs and statistics

## 📞 Support

If you need help:
1. Check the test page: `/test_auto_checkout.php`
2. View logs in admin panel
3. Contact your developer for advanced configuration

---

**System Status**: ✅ Ready for Production
**Last Updated**: August 2025
**Compatible**: Hostinger, cPanel, and most shared hosting providers
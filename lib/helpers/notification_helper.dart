import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationHelper {
  static Future<void> sendBookingNotification({
    required String bookingType,
    required String serviceName,
    required String bookingId,
    required String customerName,
    required String message,
    String status = 'Confirmed',
    String? staffName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('guest_notifications') ?? [];
    
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': '$bookingType Booking $status',
      'message': '$serviceName: $message',
      'ticketId': bookingId,
      'ticketType': bookingType,
      'status': status,
      'timestamp': DateTime.now().toString(),
      'isRead': false,
      'staffName': staffName ?? 'Resort Staff',
      'customerName': customerName,
    };
    
    notifications.add(json.encode(notification));
    await prefs.setStringList('guest_notifications', notifications);
  }

  // Create booking status notification when staff updates booking status
  static Future<void> createBookingStatusNotification({
    required String bookingId,
    required String bookingType,
    required String bookingName,
    required String oldStatus,
    required String newStatus,
    required String staffName,
    String? additionalMessage,
  }) async {
    // Only create notification if status actually changed
    if (oldStatus.toLowerCase() == newStatus.toLowerCase()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsList = prefs.getStringList('guest_notifications') ?? [];
    
    String title = '';
    String message = '';
    
    // Generate appropriate title and message based on status
    switch (newStatus.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        title = '$bookingType Booking Confirmed';
        message = 'Great news! Your $bookingName booking has been confirmed by $staffName. ${additionalMessage ?? 'We look forward to serving you!'}';
        break;
      case 'declined':
        title = '$bookingType Booking Declined';
        message = 'Unfortunately, your $bookingName booking has been declined by $staffName. ${additionalMessage ?? 'Please contact our staff for alternative options or more information.'}';
        break;
      case 'rejected':
        title = '$bookingType Booking Rejected';
        message = 'Your $bookingName booking has been rejected by $staffName. ${additionalMessage ?? 'Please contact our staff for more information about this decision.'}';
        break;
      case 'cancelled':
        title = '$bookingType Booking Cancelled';
        message = 'Your $bookingName booking has been cancelled by $staffName. ${additionalMessage ?? 'If you have any questions, please contact our staff.'}';
        break;
      case 'completed':
        title = '$bookingType Booking Completed';
        message = 'Your $bookingName booking has been completed successfully! ${additionalMessage ?? 'Thank you for choosing our resort. We hope you had a wonderful experience!'}';
        break;
      case 'in progress':
        title = '$bookingType Booking Started';
        message = 'Your $bookingName booking is now in progress. ${additionalMessage ?? 'Please proceed to the designated area and enjoy your experience!'}';
        break;
      case 'under review':
        title = '$bookingType Booking Under Review';
        message = 'Your $bookingName booking is currently under review by $staffName. ${additionalMessage ?? 'We will notify you once the review is complete.'}';
        break;
      default:
        title = '$bookingType Booking Updated';
        message = 'Your $bookingName booking status has been updated to "$newStatus" by $staffName. ${additionalMessage ?? 'Please check your booking details for more information.'}';
    }
    
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'status': newStatus,
      'staffName': staffName,
      'ticketType': '$bookingType Booking',
      'isRead': false,
      'bookingName': bookingName,
      'bookingType': bookingType,
      'bookingId': bookingId,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
    };
    
    notificationsList.add(json.encode(notification));
    await prefs.setStringList('guest_notifications', notificationsList);
    
    print('Booking status notification created: $title');
  }

  static Future<void> sendRoomBookingNotification({
    required String roomType,
    required String bookingId,
    required String customerName,
    required String checkinDate,
    required String checkoutDate,
    String status = 'Confirmed',
  }) async {
    await sendBookingNotification(
      bookingType: 'Room Booking',
      serviceName: roomType,
      bookingId: bookingId,
      customerName: customerName,
      message: 'Your room booking has been $status. Check-in: $checkinDate, Check-out: $checkoutDate',
      status: status,
    );
  }

  static Future<void> sendFacilityBookingNotification({
    required String facilityName,
    required String bookingId,
    required String customerName,
    required String bookingDate,
    required String timeSlot,
    String status = 'Confirmed',
  }) async {
    await sendBookingNotification(
      bookingType: 'Facility Booking',
      serviceName: facilityName,
      bookingId: bookingId,
      customerName: customerName,
      message: 'Your facility booking has been $status. Date: $bookingDate, Time: $timeSlot',
      status: status,
    );
  }

  static Future<void> sendActivityBookingNotification({
    required String activityName,
    required String bookingId,
    required String customerName,
    required String bookingDate,
    required String timeSlot,
    String status = 'Confirmed',
  }) async {
    await sendBookingNotification(
      bookingType: 'Activity Booking',
      serviceName: activityName,
      bookingId: bookingId,
      customerName: customerName,
      message: 'Your activity booking has been $status. Date: $bookingDate, Time: $timeSlot',
      status: status,
    );
  }

  static Future<void> sendServiceRequestNotification({
    required String serviceType,
    required String requestId,
    required String customerName,
    required String message,
    String status = 'Received',
  }) async {
    await sendBookingNotification(
      bookingType: 'Service Request',
      serviceName: serviceType,
      bookingId: requestId,
      customerName: customerName,
      message: message,
      status: status,
    );
  }

  static Future<void> sendTicketNotification({
    required String ticketType,
    required String ticketId,
    required String customerName,
    required String subject,
    required String message,
    String status = 'Received',
  }) async {
    await sendBookingNotification(
      bookingType: 'Support Ticket',
      serviceName: subject,
      bookingId: ticketId,
      customerName: customerName,
      message: message,
      status: status,
    );
  }

  static Future<void> sendGeneralNotification({
    required String title,
    required String message,
    required String customerName,
    String? staffName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('guest_notifications') ?? [];
    
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'ticketId': '',
      'ticketType': 'General',
      'status': 'Information',
      'timestamp': DateTime.now().toString(),
      'isRead': false,
      'staffName': staffName ?? 'Resort Staff',
      'customerName': customerName,
    };
    
    notifications.add(json.encode(notification));
    await prefs.setStringList('guest_notifications', notifications);
  }

  static Future<int> getUnreadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsList = prefs.getStringList('guest_notifications') ?? [];
    
    int unreadCount = 0;
    try {
      for (String notificationStr in notificationsList) {
        final Map<String, dynamic> notification = json.decode(notificationStr);
        if (notification['isRead'] == false) {
          unreadCount++;
        }
      }
    } catch (e) {
      print('Error counting unread notifications: $e');
    }
    
    return unreadCount;
  }

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsList = prefs.getStringList('guest_notifications') ?? [];
    
    try {
      final List<String> updatedList = notificationsList.map((str) {
        final Map<String, dynamic> notification = json.decode(str);
        notification['isRead'] = true;
        return json.encode(notification);
      }).toList();
      
      await prefs.setStringList('guest_notifications', updatedList);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  static Future<void> deleteAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_notifications');
  }
}

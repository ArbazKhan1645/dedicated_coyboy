import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailTemplates {
  static const String username = 'hammad1645988@gmail.com';
  static const String password = 'gfha omxq fsie mheg';
  static final smtpServer = gmail(username, password);

  // Template 1: Listing Under Review
  static Future<void> sendListingUnderReviewEmail({
    required String recipientEmail,
    required String recipientName,
    required String listingTitle,
    required String listingUrl,
  }) async {
    try {
      final message =
          Message()
            ..from = Address(username, 'Dedicated Cowboy Team')
            ..recipients.add(recipientEmail)
            ..subject = 'Your Listing "$listingTitle" is Under Review'
            ..html = _getListingUnderReviewTemplate(
              recipientName: recipientName,
              listingTitle: listingTitle,
              listingUrl: listingUrl,
            );

      await send(message, smtpServer);
    } on MailerException catch (e) {
      print('Failed to send listing under review email: ${e.message}');
      for (var problem in e.problems) {
        print('Problem: ${problem.code}: ${problem.msg}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  // Template 2: Listing Approved/Live
  static Future<void> sendListingLiveEmail({
    required String recipientEmail,
    required String recipientName,
    required String listingTitle,
    required String listingUrl,
  }) async {
    try {
      final message =
          Message()
            ..from = Address(username, 'Dedicated Cowboy Team')
            ..recipients.add(recipientEmail)
            ..subject = 'Your Listing "$listingTitle" is Live!'
            ..html = _getListingLiveTemplate(
              recipientName: recipientName,
              listingTitle: listingTitle,
              listingUrl: listingUrl,
            );

      await send(message, smtpServer);
    } on MailerException catch (e) {
      print('Failed to send listing live email: ${e.message}');
      for (var problem in e.problems) {
        print('Problem: ${problem.code}: ${problem.msg}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  // Template 3: Subscription Welcome
  static Future<void> sendSubscriptionWelcomeEmail({
    required String recipientEmail,
    required String recipientName,
    required String orderId,
    required String totalAmount,
    required String orderDetailsUrl,
  }) async {
    try {
      final message =
          Message()
            ..from = Address(username, 'Dedicated Cowboy Team')
            ..recipients.add(recipientEmail)
            ..subject = 'Welcome! Your Subscription is Active'
            ..html = _getSubscriptionWelcomeTemplate(
              recipientName: recipientName,
              orderId: orderId,
              totalAmount: totalAmount,
              orderDetailsUrl: orderDetailsUrl,
            );

      await send(message, smtpServer);
    } on MailerException catch (e) {
      print('Failed to send subscription welcome email: ${e.message}');
      for (var problem in e.problems) {
        print('Problem: ${problem.code}: ${problem.msg}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  // HTML Template 1: Listing Under Review
  static String _getListingUnderReviewTemplate({
    required String recipientName,
    required String listingTitle,
    required String listingUrl,
  }) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Listing Under Review</title>
    </head>
    <body style="margin: 0; padding: 20px; font-family: Arial, sans-serif; background-color: #f5f5f5;">
        <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            
            <!-- Header -->
            <div style="background-color: #E6B649; padding: 20px; text-align: center;">
                <h1 style="margin: 0; color: #666; font-size: 18px; font-weight: normal;">
                    Your Listing "$listingTitle" is Under Review
                </h1>
            </div>
            
            <!-- Content -->
            <div style="padding: 30px;">
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    <strong>Dear $recipientName,</strong>
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    Thank you for submitting your listing <strong>"$listingTitle"</strong> to Dedicated Cowboy.
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    Your listing is currently under review by our team and will be published once it's approved. We'll send you a notification as soon as it goes live.
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    In the meantime, you can review or edit your submission here:
                    <br><a href="$listingUrl" style="color: #4CAF50; text-decoration: none;">$listingTitle</a>
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 30px;">
                    Thank you for being the best part of Dedicated Cowboy!
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 10px;">
                    To Trails Ahead,<br>
                    <strong>The Dedicated Cowboy Team</strong><br>
                    <a href="https://dedicatedcowboy.com" style="color: #4CAF50; text-decoration: none;">https://dedicatedcowboy.com</a>
                </p>
            </div>
            
            <!-- Footer -->
            <div style="text-align: center; padding: 20px;">
                <img src="https://dedicatedcowboy.com/wp-content/uploads/elementor/thumbs/Group-11-r22ub9pqki70qwrf184tmu4hmun3mxpdeg514akv9w.png" alt="Dedicated Cowboy - Where the West Continues" style="max-width: 200px; height: auto;" />
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // HTML Template 2: Listing Live
  static String _getListingLiveTemplate({
    required String recipientName,
    required String listingTitle,
    required String listingUrl,
  }) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Listing is Live</title>
    </head>
    <body style="margin: 0; padding: 20px; font-family: Arial, sans-serif; background-color: #f5f5f5;">
        <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            
            <!-- Header -->
            <div style="background-color: #E6B649; padding: 20px; text-align: center;">
                <h1 style="margin: 0; color: #666; font-size: 18px; font-weight: normal;">
                    Your Listing "$listingTitle" is Live!
                </h1>
            </div>
            
            <!-- Content -->
            <div style="padding: 30px;">
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    <strong>Dear $recipientName,</strong>
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    You're Live! Your listing <strong>"$listingTitle"</strong> has been approved and is now visible on Dedicated Cowboy.
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    You can view your listing here: <a href="$listingUrl" style="color: #4CAF50; text-decoration: none;">$listingTitle</a>
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    If you have any questions or need help along the way, don't hesitate to reach out.
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 30px;">
                    Thank you for being the best part of Dedicated Cowboy!
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 10px;">
                    To Trails Ahead,<br>
                    <strong>The Dedicated Cowboy Team</strong><br>
                    <a href="https://dedicatedcowboy.com" style="color: #4CAF50; text-decoration: none;">https://dedicatedcowboy.com</a>
                </p>
            </div>
            
        <!-- Footer -->
            <div style="text-align: center; padding: 20px;">
                <img src="https://dedicatedcowboy.com/wp-content/uploads/elementor/thumbs/Group-11-r22ub9pqki70qwrf184tmu4hmun3mxpdeg514akv9w.png" alt="Dedicated Cowboy - Where the West Continues" style="max-width: 200px; height: auto;" />
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // HTML Template 3: Subscription Welcome
  static String _getSubscriptionWelcomeTemplate({
    required String recipientName,
    required String orderId,
    required String totalAmount,
    required String orderDetailsUrl,
  }) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Subscription Active</title>
    </head>
    <body style="margin: 0; padding: 20px; font-family: Arial, sans-serif; background-color: #f5f5f5;">
        <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            
            <!-- Header -->
            <div style="background-color: #E6B649; padding: 20px; text-align: center;">
                <h1 style="margin: 0; color: #666; font-size: 18px; font-weight: normal;">
                    Welcome! Your Subscription is Active
                </h1>
            </div>
            
            <!-- Content -->
            <div style="padding: 30px;">
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    <strong>Dear $recipientName,</strong>
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    Welcome to Dedicated Cowboy — Where the West Continues.
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    Your order <strong>#$orderId</strong> has been successfully completed.
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    By signing up, you now have <strong>unlimited access to post listings in all three categories:</strong>
                </p>
                
                <ul style="color: #333; line-height: 1.6; margin-bottom: 20px; padding-left: 20px;">
                    <li>Items</li>
                    <li>Events</li>
                    <li>Businesses</li>
                </ul>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                    You can check your order details by clicking the link below:<br>
                    <strong>Order Details Page:</strong> <a href="$orderDetailsUrl" style="color: #4CAF50; text-decoration: none;">View Order/Payment Receipt</a>
                </p>
                
                <!-- Order Summary Table -->
                <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                    <h3 style="margin: 0 0 15px 0; color: #333;">Your order summary:</h3>
                    <table style="width: 100%; border-collapse: collapse;">
                        <tr style="border-bottom: 1px solid #ddd;">
                            <td style="padding: 8px 0; color: #666;">Item(s)</td>
                            <td style="padding: 8px 0; color: #666; text-align: right;">Price [USD]</td>
                        </tr>
                        <tr style="border-bottom: 1px solid #ddd;">
                            <td style="padding: 8px 0; color: #333;">Subscription</td>
                            <td style="padding: 8px 0; color: #333; text-align: right;">$totalAmount</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; color: #333; font-weight: bold;">Total amount [USD]</td>
                            <td style="padding: 8px 0; color: #333; font-weight: bold; text-align: right;">$totalAmount</td>
                        </tr>
                    </table>
                </div>
                
                <p style="color: #666; font-style: italic; font-size: 14px; margin-bottom: 20px;">
                    <strong>Please note:</strong> You'll need to be logged in to your account to access the order details.
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 30px;">
                    Thank you for being the best part of Dedicated Cowboy!
                </p>
                
                <p style="color: #333; line-height: 1.6; margin-bottom: 10px;">
                    To Trails Ahead,<br>
                    <strong>The Dedicated Cowboy Team</strong><br>
                    <a href="https://dedicatedcowboy.com" style="color: #4CAF50; text-decoration: none;">https://dedicatedcowboy.com</a>
                </p>
            </div>
            
        <!-- Footer -->
            <div style="text-align: center; padding: 20px;">
                <img src="https://dedicatedcowboy.com/wp-content/uploads/elementor/thumbs/Group-11-r22ub9pqki70qwrf184tmu4hmun3mxpdeg514akv9w.png" alt="Dedicated Cowboy - Where the West Continues" style="max-width: 200px; height: auto;" />
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  static Future<void> sendRegistrationWelcomeEmail({
    required String recipientEmail,
    required String recipientName,
    String? loginUrl,
  }) async {
    try {
      final message =
          Message()
            ..from = Address(username, 'Dedicated Cowboy Team')
            ..recipients.add(recipientEmail)
            ..subject = 'Welcome to Dedicated Cowboy!'
            ..html = _getRegistrationWelcomeTemplate(
              recipientName: recipientName,
              loginUrl: loginUrl ?? 'https://dedicatedcowboy.com/login',
            );

      await send(message, smtpServer);
    } on MailerException catch (e) {
      print('Failed to send registration welcome email: ${e.message}');
      for (var problem in e.problems) {
        print('Problem: ${problem.code}: ${problem.msg}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  // HTML Template 4: Registration Welcome
  static String _getRegistrationWelcomeTemplate({
    required String recipientName,
    required String loginUrl,
  }) {
    return '''
  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Welcome to Dedicated Cowboy</title>
  </head>
  <body style="margin: 0; padding: 20px; font-family: Arial, sans-serif; background-color: #f5f5f5;">
      <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          
          <!-- Header -->
          <div style="background-color: #F2B342; padding: 20px; text-align: center;">
              <h1 style="margin: 0; color: #666; font-size: 18px; font-weight: normal;">
                  Welcome to Dedicated Cowboy!
              </h1>
          </div>
          
          <!-- Content -->
          <div style="padding: 30px;">
              <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                  <strong>Dear $recipientName,</strong>
              </p>
              
              <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                  Welcome to Dedicated Cowboy — Where the West Continues!
              </p>
              
              <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                  Thank you for creating your account and joining our western community. We're excited to have you as part of the Dedicated Cowboy family!
              </p>
              
              <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                  Your account has been successfully created. Here's what you can explore:
              </p>
              
              <ul style="color: #333; line-height: 1.6; margin-bottom: 20px; padding-left: 20px;">
                  <li><strong>Browse Items</strong> - Discover authentic western goods, equipment, and collectibles</li>
                  <li><strong>Find Events</strong> - Stay updated on rodeos, shows, and western community gatherings</li>
                  <li><strong>Explore Businesses</strong> - Connect with western shops, services, and professionals</li>
                  <li><strong>Build Your Profile</strong> - Share your western story with fellow enthusiasts</li>
              </ul>
              
              <div style="text-align: center; margin: 30px 0;">
                  <a href="$loginUrl" style="background-color: #F2B342; color: #333; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                      Start Exploring - Login Now
                  </a>
              </div>
              
              <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                  Ready to start selling or promoting your own items and events? Consider our premium membership for unlimited posting privileges across all categories.
              </p>
              
              <p style="color: #333; line-height: 1.6; margin-bottom: 20px;">
                  If you have any questions or need assistance getting started, our team is here to help. Don't hesitate to reach out!
              </p>
              
              <p style="color: #333; line-height: 1.6; margin-bottom: 30px;">
                  Thank you for being the best part of Dedicated Cowboy!
              </p>
              
              <p style="color: #333; line-height: 1.6; margin-bottom: 10px;">
                  To Trails Ahead,<br>
                  <strong>The Dedicated Cowboy Team</strong><br>
                  <a href="https://dedicatedcowboy.com" style="color: #4CAF50; text-decoration: none;">https://dedicatedcowboy.com</a>
              </p>
          </div>
          
          <!-- Footer -->
            <div style="text-align: center; padding: 20px;">
                <img src="https://dedicatedcowboy.com/wp-content/uploads/elementor/thumbs/Group-11-r22ub9pqki70qwrf184tmu4hmun3mxpdeg514akv9w.png" alt="Dedicated Cowboy - Where the West Continues" style="max-width: 200px; height: auto;" />
            </div>
      </div>
  </body>
  </html>
  ''';
  }
}

// Usage examples:
/*

// Example 1: Send listing under review email
await EmailTemplates.sendListingUnderReviewEmail(
  recipientEmail: 'user@example.com',
  recipientName: 'Chelle Allen',
  listingTitle: 'Wires Of The Old West Texas Sign',
  listingUrl: 'https://dedicatedcowboy.com/listing/wires-of-the-old-west-texas-sign',
);

// Example 2: Send listing live email
await EmailTemplates.sendListingLiveEmail(
  recipientEmail: 'user@example.com',
  recipientName: 'Chelle Allen',
  listingTitle: 'Saddle pads',
  listingUrl: 'https://dedicatedcowboy.com/listing/saddle-pads',
);

// Example 3: Send subscription welcome email
await EmailTemplates.sendSubscriptionWelcomeEmail(
  recipientEmail: 'user@example.com',
  recipientName: 'John Doe',
  orderId: '17311',
  totalAmount: '\$5',
  orderDetailsUrl: 'https://dedicatedcowboy.com/order/17311',
);

*/

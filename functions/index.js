const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {logger} = require("firebase-functions");

// Initialize Firebase Admin
admin.initializeApp();

// This function runs automatically when a blood request is created
exports.sendBloodRequestNotification = onDocumentCreated(
  "Blood_request/{requestId}",
  async (event) => {
    logger.info("🩸 New blood request created!");

    try {
      // Get the blood request data
      const requestData = event.data.data();
      const requestId = event.params.requestId;

      logger.info("Request ID:", requestId);
      logger.info("Blood Type:", requestData.bloodType);

      // Get all users from Firestore
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .get();

      if (usersSnapshot.empty) {
        logger.warn("❌ No users found in database");
        return null;
      }

      logger.info(`✅ Found ${usersSnapshot.size} users`);

      // Collect FCM tokens from all users
      const tokens = [];
      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        // Check if user has a notification token
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        logger.warn("❌ No users have notification tokens");
        return null;
      }

      logger.info(`✅ Sending notifications to ${tokens.length} users`);

      // Prepare the notification message
      const message = { 
        notification: {
          title: "🩸 Urgent Blood Request",
          body: `Blood Type ${requestData.bloodType} needed at ${requestData.hospitalName || "Hospital"}`,
        },
        data: {
          requestId: requestId,
          bloodType: requestData.bloodType || "",
          type: "blood_request",
        },
      };

      // Send notifications to all tokens
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        notification: message.notification,
        data: message.data,
      });

      logger.info(`✅ Successfully sent ${response.successCount} notifications`);
      logger.info(`❌ Failed to send ${response.failureCount} notifications`);

      return response;
    } catch (error) {
      logger.error("❌ Error sending notifications:", error);
      return null;
    }
  }
);30
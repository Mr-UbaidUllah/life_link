// // const {onDocumentCreated} = require("firebase-functions/v2/firestore");
// // const admin = require("firebase-admin");
// // const {logger} = require("firebase-functions");

// // // Initialize Firebase Admin
// // admin.initializeApp();

// // // This function runs automatically when a blood request is created
// // exports.sendBloodRequestNotification = onDocumentCreated(
// //   "Blood_request/{requestId}",
// //   async (event) => {
// //     logger.info("🩸 New blood request created!");

// //     try {
// //       // Get the blood request data
// //       const requestData = event.data.data();
// //       const requestId = event.params.requestId;

// //       logger.info("Request ID:", requestId);
// //       logger.info("Blood Type:", requestData.bloodType);

// //       // Get all users from Firestore
// //       const usersSnapshot = await admin
// //         .firestore()
// //         .collection("users")
// //         .get();

// //       if (usersSnapshot.empty) {
// //         logger.warn("❌ No users found in database");
// //         return null;
// //       }

// //       logger.info(`✅ Found ${usersSnapshot.size} users`);

// //       // Collect FCM tokens from all users
// //       const tokens = [];
// //       usersSnapshot.forEach((doc) => {
// //         const userData = doc.data();
// //         // Check if user has a notification token
// //         if (userData.fcmToken) {
// //           tokens.push(userData.fcmToken);
// //         }
// //       });

// //       if (tokens.length === 0) {
// //         logger.warn("❌ No users have notification tokens");
// //         return null;
// //       }

// //       logger.info(`✅ Sending notifications to ${tokens.length} users`);

// //       // Prepare the notification message
// //       const message = { 
// //         notification: {
// //           title: "🩸 Urgent Blood Request",
// //           body: `Blood Type ${requestData.bloodType} needed at ${requestData.hospitalName || "Hospital"}`,
// //         },
// //         data: {
// //           requestId: requestId,
// //           bloodType: requestData.bloodType || "",
// //           type: "blood_request",
// //         },
// //       };

// //       // Send notifications to all tokens
// //       const response = await admin.messaging().sendEachForMulticast({
// //         tokens: tokens,
// //         notification: message.notification,
// //         data: message.data,
// //       });

// //       logger.info(`✅ Successfully sent ${response.successCount} notifications`);
// //       logger.info(`❌ Failed to send ${response.failureCount} notifications`);

// //       return response;
// //     } catch (error) {
// //       logger.error("❌ Error sending notifications:", error);
// //       return null;
// //     }
// //   }
// // );30
// const {onDocumentCreated} = require("firebase-functions/v2/firestore");
// const admin = require("firebase-admin");
// const {logger} = require("firebase-functions");

// // Initialize Firebase Admin
// admin.initializeApp();

// // This function runs automatically when a blood request is created
// exports.sendBloodRequestNotification = onDocumentCreated(
//   "Blood_request/{requestId}",
//   async (event) => {
//     logger.info("🩸 New blood request created!");

//     try {
//       // Get the blood request data
//       const requestData = event.data.data(); 
//       const requestId = event.params.requestId;

//       logger.info("Request ID:", requestId);
//       logger.info("Blood Group:", requestData.bloodGroup);
//       logger.info("Hospital:", requestData.hospital);
      
//       //  Get the creator's user ID
//       const creatorUserId = requestData.userId;
//       logger.info("Creator User ID:", creatorUserId);

//       if (!creatorUserId) {
//         logger.warn("⚠️ No userId found in request data - will send to all users");
//       }

//       // Get all users from Firestore
//       const usersSnapshot = await admin
//         .firestore()
//         .collection("users")
//         .get();

//       if (usersSnapshot.empty) {
//         logger.warn("❌ No users found in database");
//         return null;
//       }

//       logger.info(`✅ Found ${usersSnapshot.size} total users`);

//       // Collect FCM tokens from all users EXCEPT the creator
//       const tokens = [];
//       let totalUsers = 0;
//       let usersWithTokens = 0;
//       let creatorSkipped = false;
      
//       usersSnapshot.forEach((doc) => {
//         const userData = doc.data();
//         const userId = doc.id;
//         totalUsers++;
        
//         // 👇 Skip the user who created the request
//         if (creatorUserId && userId === creatorUserId) {
//           logger.info(`⏭️ Skipping notification for creator: ${userId}`);
//           creatorSkipped = true;
//           return; // Skip this user
//         }
        
//         // Check if user has a notification token
//         if (userData.fcmToken) {
//           tokens.push(userData.fcmToken);
//           usersWithTokens++;
//           logger.info(`✅ Added token for user: ${userId} (${userData.name || 'No name'})`);
//         } else {
//           logger.info(`⚠️ User ${userId} (${userData.name || 'No name'}) has no FCM token`);
//         }
//       });

//       if (creatorUserId && !creatorSkipped) {
//         logger.warn(`⚠️ Creator ${creatorUserId} was not found in users collection`);
//       }

//       logger.info(`📊 Stats: Total users: ${totalUsers}, With tokens: ${usersWithTokens}, Creator skipped: ${creatorSkipped}`);

//       if (tokens.length === 0) {
//         logger.warn("❌ No users have notification tokens (excluding creator)");
//         return null;
//       }

//       logger.info(`✅ Sending notifications to ${tokens.length} users`);

//       // Prepare the notification message
//       const message = { 
//         notification: {
//           title: "🩸 Urgent Blood Request",
//           body: `Blood Group ${requestData.bloodGroup} needed - ${requestData.bags} bag(s) at ${requestData.hospital}`,
//         },
//         data: {
//           requestId: requestId,
//           bloodGroup: requestData.bloodGroup || "",
//           hospital: requestData.hospital || "",
//           bags: String(requestData.bags || 0),
//           type: "blood_request",
//         },
//       };

//       // Send notifications to all tokens
//       const response = await admin.messaging().sendEachForMulticast({
//         tokens: tokens,
//         notification: message.notification,
//         data: message.data,
//       });

//       logger.info(`✅ Successfully sent ${response.successCount} notifications`);
      
//       if (response.failureCount > 0) {
//         logger.error(`❌ Failed to send ${response.failureCount} notifications`);
        
//         // Log details of failed notifications
//         response.responses.forEach((resp, idx) => {
//           if (!resp.success) {
//             logger.error(`Failed token ${idx}: ${resp.error?.message || 'Unknown error'}`);
//           }
//         });
//       }

//       return {
//         success: response.successCount,
//         failed: response.failureCount,
//         total: tokens.length,
//       };
      
//     } catch (error) {
//       logger.error("❌ Error sending notifications:", error);
//       return null;
//     }
//   }
// );
// // Donors
// // Add this new function to your index.js file

// exports.sendDonorAvailabilityNotification = onDocumentUpdated(
//   "users/{userId}",
//   async (event) => {
//     logger.info("👤 User document updated!");

//     try {
//       // Get the before and after data
//       const beforeData = event.data.before.data();
//       const afterData = event.data.after.data();
//       const userId = event.params.userId;

//       // Check if isDonor status changed from false to true
//       const wasDonor = beforeData.isDonor || false;
//       const isDonor = afterData.isDonor || false;

//       // Only send notification if user just became available to donate
//       if (!wasDonor && isDonor) {
//         logger.info(`✅ User ${userId} is now available for donation!`);

//         // Get all users from Firestore
//         const usersSnapshot = await admin
//           .firestore()
//           .collection("users")
//           .get();

//         if (usersSnapshot.empty) {
//           logger.warn("❌ No users found in database");
//           return null;
//         }

//         logger.info(`✅ Found ${usersSnapshot.size} total users`);

//         // Collect FCM tokens from all users EXCEPT the donor who just toggled
//         const tokens = [];
//         let totalUsers = 0;
//         let usersWithTokens = 0;
//         let donorSkipped = false;

//         usersSnapshot.forEach((doc) => {
//           const userData = doc.data();
//           const currentUserId = doc.id;
//           totalUsers++;

//           // 👇 Skip the user who toggled donation
//           if (currentUserId === userId) {
//             logger.info(`⏭️ Skipping notification for donor: ${userId}`);
//             donorSkipped = true;
//             return;
//           }

//           // Check if user has a notification token
//           if (userData.fcmToken) {
//             tokens.push(userData.fcmToken);
//             usersWithTokens++;
//             logger.info(`✅ Added token for user: ${currentUserId}`);
//           } else {
//             logger.info(`⚠️ User ${currentUserId} has no FCM token`);
//           }
//         });

//         logger.info(
//           `📊 Stats: Total users: ${totalUsers}, With tokens: ${usersWithTokens}, Donor skipped: ${donorSkipped}`
//         );

//         if (tokens.length === 0) {
//           logger.warn("❌ No users have notification tokens (excluding donor)");
//           return null;
//         }

//         logger.info(`✅ Sending notifications to ${tokens.length} users`);

//         // Prepare the notification message
//         const donorName = afterData.name || "A donor";
//         const bloodGroup = afterData.bloodGroup || "their blood group";
//         const city = afterData.city || "your area";

//         const message = {
//           notification: {
//             title: "🩸 New Donor Available!",
//             body: `${donorName} with blood group ${bloodGroup} is now available to donate in ${city}`,
//           },
//           data: {
//             userId: userId,
//             donorName: donorName,
//             bloodGroup: bloodGroup,
//             city: city,
//             phone: afterData.phone || "",
//             type: "donor_available",
//           },
//         };

//         // Send notifications to all tokens
//         const response = await admin.messaging().sendEachForMulticast({
//           tokens: tokens,
//           notification: message.notification,
//           data: message.data,
//         });

//         logger.info(`✅ Successfully sent ${response.successCount} notifications`);

//         if (response.failureCount > 0) {
//           logger.error(`❌ Failed to send ${response.failureCount} notifications`);

//           // Log details of failed notifications
//           response.responses.forEach((resp, idx) => {
//             if (!resp.success) {
//               logger.error(`Failed token ${idx}: ${resp.error?.message || 'Unknown error'}`);
//             }
//           });
//         }

//         return {
//           success: response.successCount,
//           failed: response.failureCount,
//           total: tokens.length,
//           donorName: donorName,
//           bloodGroup: bloodGroup,
//         };
//       } else {
//         logger.info("ℹ️ isDonor status unchanged or changed to false - no notification sent");
//         return null;
//       }
//     } catch (error) {
//       logger.error("❌ Error sending donor availability notifications:", error);
//       return null;
//     }
//   }
// );
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {logger} = require("firebase-functions");

// Initialize Firebase Admin
admin.initializeApp();

// ============================================
// 🩸 BLOOD REQUEST NOTIFICATION
// ============================================
exports.sendBloodRequestNotification = onDocumentCreated(
  "Blood_request/{requestId}",
  async (event) => {
    logger.info("🩸 New blood request created!");

    try {
      const requestData = event.data.data();
      const requestId = event.params.requestId;
      const creatorUserId = requestData.userId;

      logger.info("Request ID:", requestId);
      logger.info("Blood Group:", requestData.bloodGroup);
      logger.info("Creator User ID:", creatorUserId);

      if (!creatorUserId) {
        logger.warn("⚠️ No userId found in request data");
      }

      // Get all users
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .get();

      if (usersSnapshot.empty) {
        logger.warn("❌ No users found");
        return null;
      }

      logger.info(`✅ Found ${usersSnapshot.size} total users`);

      // Collect tokens (skip creator)
      const tokens = [];
      let usersWithTokens = 0;
      let creatorSkipped = false;

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        const userId = doc.id;

        // Skip the creator
        if (creatorUserId && userId === creatorUserId) {
          logger.info(`⏭️ Skipping creator: ${userId}`);
          creatorSkipped = true;
          return;
        }

        // Collect token
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
          usersWithTokens++;
          logger.info(`✅ Added token for user: ${userId}`);
        }
      });

      logger.info(
        `📊 Stats: Total users: ${usersSnapshot.size}, ` +
        `With tokens: ${usersWithTokens}, ` +
        `Creator skipped: ${creatorSkipped}`
      );

      if (tokens.length === 0) {
        logger.warn("❌ No tokens found (excluding creator)");
        return null;
      }

      logger.info(`✅ Sending to ${tokens.length} users`);

      // Prepare notification
      const message = {
        notification: {
          title: "🩸 Urgent Blood Request",
          body: `Blood Group ${requestData.bloodGroup} needed - ${requestData.bags} bag(s) at ${requestData.hospital}`,
        },
        data: {
          requestId: requestId,
          bloodGroup: requestData.bloodGroup || "",
          hospital: requestData.hospital || "",
          bags: String(requestData.bags || 0),
          type: "blood_request",
        },
      };

      // Send notifications
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        notification: message.notification,
        data: message.data,
      });

      logger.info(`✅ Sent ${response.successCount} notifications`);

      if (response.failureCount > 0) {
        logger.error(`❌ Failed ${response.failureCount} notifications`);
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            logger.error(
              `Failed token ${idx}: ${resp.error?.message || "Unknown error"}`
            );
          }
        });
      }

      return {
        success: response.successCount,
        failed: response.failureCount,
        total: tokens.length,
      };
    } catch (error) {
      logger.error("❌ Error:", error);
      return null;
    }
  }
);

// ============================================
// 👤 DONOR AVAILABILITY NOTIFICATION
// ============================================
exports.sendDonorAvailabilityNotification = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    logger.info("👤 User document updated!");

    try {
      // Get before and after data
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const userId = event.params.userId;

      // Check if isDonor changed from false to true
      const wasDonor = beforeData.isDonor || false;
      const isDonor = afterData.isDonor || false;

      // Only notify when user becomes available (false → true)
      if (!wasDonor && isDonor) {
        logger.info(`✅ User ${userId} is now available for donation!`);

        // Get all users
        const usersSnapshot = await admin
          .firestore()
          .collection("users")
          .get();

        if (usersSnapshot.empty) {
          logger.warn("❌ No users found");
          return null;
        }

        logger.info(`✅ Found ${usersSnapshot.size} total users`);

        // Collect tokens (skip the donor)
        const tokens = [];
        let usersWithTokens = 0;
        let donorSkipped = false;

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const currentUserId = doc.id;

          // Skip the donor who toggled
          if (currentUserId === userId) {
            logger.info(`⏭️ Skipping donor: ${userId}`);
            donorSkipped = true;
            return;
          }

          // Collect token
          if (userData.fcmToken) {
            tokens.push(userData.fcmToken);
            usersWithTokens++;
            logger.info(`✅ Added token for user: ${currentUserId}`);
          }
        });

        logger.info(
          `📊 Stats: Total users: ${usersSnapshot.size}, ` +
          `With tokens: ${usersWithTokens}, ` +
          `Donor skipped: ${donorSkipped}`
        );

        if (tokens.length === 0) {
          logger.warn("❌ No tokens found (excluding donor)");
          return null;
        }

        logger.info(`✅ Sending to ${tokens.length} users`);

        // Prepare notification
        const donorName = afterData.name || "A donor";
        const bloodGroup = afterData.bloodGroup || "Unknown blood group";
        const city = afterData.city || "your area";

        const message = {
          notification: {
            title: "🩸 New Donor Available!",
            body: `${donorName} with blood group ${bloodGroup} is now available to donate in ${city}`,
          },
          data: {
            userId: userId,
            donorName: donorName,
            bloodGroup: bloodGroup,
            city: city,
            phone: afterData.phone || "",
            type: "donor_available",
          },
        };

        // Send notifications
        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokens,
          notification: message.notification,
          data: message.data,
        });

        logger.info(`✅ Sent ${response.successCount} notifications`);

        if (response.failureCount > 0) {
          logger.error(`❌ Failed ${response.failureCount} notifications`);
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              logger.error(
                `Failed token ${idx}: ${resp.error?.message || "Unknown error"}`
              );
            }
          });
        }

        return {
          success: response.successCount,
          failed: response.failureCount,
          total: tokens.length,
          donorName: donorName,
          bloodGroup: bloodGroup,
        };
      } else {
        logger.info("ℹ️ isDonor unchanged or turned off - no notification");
        return null;
      }
    } catch (error) {
      logger.error("❌ Error:", error);
      return null;
    }
  }
);
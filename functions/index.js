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
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const {logger} = require("firebase-functions");

// Initialize Firebase Admin
admin.initializeApp();

// ============================================
// 🔎 MATCHING HELPERS (pure — unit-tested in matching.test.js)
// ============================================

/** Normalize a string for case/whitespace-insensitive comparison. */
function norm(value) {
  return (value || "").toString().trim().toLowerCase();
}

/**
 * Whether a user should be notified about a blood request.
 * Rules: the candidate must be a registered donor (isDonor === true), with an
 * exact blood group match AND same city, and never the request's own creator.
 * Returns false if the request itself is missing bloodGroup/city, so an
 * incomplete request never broadcasts to everyone.
 *
 * @param {object} requestData  The Blood_request document data.
 * @param {string} userId       The candidate user's document id.
 * @param {object} userData     The candidate user's document data.
 * @param {string} creatorUserId  userId of the request's creator.
 * @return {boolean}
 */
function shouldNotifyForRequest(requestData, userId, userData, creatorUserId) {
  // Never notify the creator about their own request.
  if (creatorUserId && userId === creatorUserId) return false;

  // Only registered donors are notified — non-donors can't act on a request,
  // so pushing to them is pure cost. (The caller also pre-filters the query to
  // isDonor === true; this keeps the rule correct if that ever changes.)
  if (userData.isDonor !== true) return false;

  const reqGroup = norm(requestData.bloodGroup);
  const reqCity = norm(requestData.city);
  // Incomplete request → no safe audience.
  if (!reqGroup || !reqCity) return false;

  // Exact blood group match.
  if (norm(userData.bloodGroup) !== reqGroup) return false;

  // Same city.
  if (norm(userData.city) !== reqCity) return false;

  return true;
}

exports.shouldNotifyForRequest = shouldNotifyForRequest;

/**
 * Persist an in-app notification document into each recipient's
 * `users/{uid}/notifications` subcollection so it shows up in the app's
 * Notification inbox (not just as an ephemeral push). `pushHandled: true`
 * tells sendChatPushNotification NOT to send a second push for these — the
 * blood-request / donor functions already delivered the FCM push directly.
 *
 * @param {string[]} userIds  Recipients' user document ids.
 * @param {object} payload    { title, body, type, ...extra } fields to store.
 * @return {Promise<void>}
 */
async function writeInboxNotifications(userIds, payload) {
  if (!userIds || userIds.length === 0) return;
  const db = admin.firestore();
  const chunkSize = 450; // Firestore batch limit is 500 ops.
  for (let i = 0; i < userIds.length; i += chunkSize) {
    const chunk = userIds.slice(i, i + chunkSize);
    const batch = db.batch();
    chunk.forEach((uid) => {
      const ref = db
        .collection("users").doc(uid)
        .collection("notifications").doc();
      batch.set(ref, {
        ...payload,
        isRead: false,
        pushHandled: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
  }
  logger.info(`📝 Wrote ${userIds.length} inbox notification(s)`);
}

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

      // If the request is missing the fields we match on, there's no safe
      // audience — bail BEFORE reading any users rather than broadcasting.
      if (!norm(requestData.bloodGroup) || !norm(requestData.city)) {
        logger.warn(
          "❌ Request missing bloodGroup or city — skipping notifications " +
          `(bloodGroup="${requestData.bloodGroup}", city="${requestData.city}")`
        );
        return null;
      }

      // Billing: read ONLY registered donors, not the whole users collection.
      // isDonor is auto-indexed (single field), so this scales with the donor
      // count rather than total user count. City/blood-group are then filtered
      // in memory (case-insensitive via norm) by shouldNotifyForRequest.
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("isDonor", "==", true)
        .get();

      if (usersSnapshot.empty) {
        logger.warn("❌ No donors found");
        return null;
      }

      logger.info(`✅ Found ${usersSnapshot.size} donor(s) to evaluate`);

      // Collect MATCHING recipients only — exact blood group + same city, and
      // never the creator (see shouldNotifyForRequest). Track ids (for the
      // in-app inbox) and tokens (for the push) separately.
      const tokens = [];
      const matchedUserIds = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        const userId = doc.id;

        if (!shouldNotifyForRequest(requestData, userId, userData, creatorUserId)) {
          return;
        }
        matchedUserIds.push(userId);

        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
          logger.info(`✅ Matched recipient: ${userId}`);
        } else {
          logger.info(`⚠️ Matched user ${userId} has no FCM token`);
        }
      });

      logger.info(
        `📊 Stats: Donors evaluated: ${usersSnapshot.size}, ` +
        `Matched: ${matchedUserIds.length}, With tokens: ${tokens.length}`
      );

      const bodyText =
        `Blood Group ${requestData.bloodGroup} needed - ` +
        `${requestData.bags} bag(s) at ${requestData.hospital}`;

      // Persist to each matched user's in-app inbox regardless of whether they
      // have a push token, so the Notifications screen always shows the match.
      await writeInboxNotifications(matchedUserIds, {
        title: "🩸 Urgent Blood Request",
        body: bodyText,
        type: "blood_request",
        requestId: requestId,
      });

      if (tokens.length === 0) {
        logger.warn(
          `❌ No matching recipients with tokens for ` +
          `${norm(requestData.bloodGroup)} in ${norm(requestData.city)} ` +
          `(excluding creator) — inbox written, push skipped`
        );
        return null;
      }

      logger.info(`✅ Sending to ${tokens.length} matching users`);

      // Prepare notification
      const message = {
        notification: {
          title: "🩸 Urgent Blood Request",
          body: bodyText,
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
//  DONOR AVAILABILITY NOTIFICATION
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

        // Billing + relevance: only notify users in the SAME city as the donor.
        // A donor in another city is irrelevant to a recipient, so broadcasting
        // to the whole user base is both spammy and the dominant cost here
        // (N reads + N inbox writes + N triggered push functions). If the donor
        // has no city we have no safe audience — bail rather than broadcast.
        const donorCity = afterData.city;
        if (!norm(donorCity)) {
          logger.warn("❌ Donor has no city — skipping donor-available broadcast");
          return null;
        }

        // city comes from a fixed picker (app_constants), so an exact-match
        // query is safe and reads only same-city users, not everyone.
        const usersSnapshot = await admin
          .firestore()
          .collection("users")
          .where("city", "==", donorCity)
          .get();

        if (usersSnapshot.empty) {
          logger.warn("❌ No same-city users found");
          return null;
        }

        logger.info(`✅ Found ${usersSnapshot.size} user(s) in ${donorCity}`);

        // Collect recipients (everyone in the city except the donor). Track ids
        // for the in-app inbox and tokens for the push separately.
        const tokens = [];
        const recipientUserIds = [];

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const currentUserId = doc.id;

          // Skip the donor who toggled
          if (currentUserId === userId) {
            logger.info(`⏭️ Skipping donor: ${userId}`);
            return;
          }
          recipientUserIds.push(currentUserId);

          // Collect token
          if (userData.fcmToken) {
            tokens.push(userData.fcmToken);
            logger.info(`✅ Added token for user: ${currentUserId}`);
          }
        });

        if (recipientUserIds.length === 0) {
          logger.info("ℹ️ No other users in city — nothing to send");
          return null;
        }

        logger.info(
          `📊 Stats: City users: ${usersSnapshot.size}, ` +
          `Recipients: ${recipientUserIds.length}, ` +
          `With tokens: ${tokens.length}`
        );

        // Prepare notification
        const donorName = afterData.name || "A donor";
        const bloodGroup = afterData.bloodGroup || "Unknown blood group";
        const city = afterData.city || "your area";
        const donorBody =
          `${donorName} with blood group ${bloodGroup} ` +
          `is now available to donate in ${city}`;

        // Persist to every recipient's in-app inbox regardless of push token.
        await writeInboxNotifications(recipientUserIds, {
          title: "🩸 New Donor Available!",
          body: donorBody,
          type: "donor_available",
          senderId: userId,
        });

        if (tokens.length === 0) {
          logger.warn("❌ No tokens found (excluding donor) — inbox written, push skipped");
          return null;
        }

        logger.info(`✅ Sending to ${tokens.length} users`);

        const message = {
          notification: {
            title: "🩸 New Donor Available!",
            body: donorBody,
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

// ============================================
// 💬 CHAT / IN-APP NOTIFICATION PUSH
// ============================================
// Fires whenever a notification document is written to any user's
// `users/{userId}/notifications` subcollection (chat messages write here). The
// client cannot send FCM to another device, so the push MUST happen here:
// look up the recipient's fcmToken and deliver. Generic — works for any
// notification type the app starts writing (chat today, others later).
exports.sendChatPushNotification = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    try {
      const notification = event.data.data();
      const userId = event.params.userId;

      // Blood-request and donor-availability inbox docs are written by their
      // own functions, which already delivered the FCM push. They carry
      // pushHandled:true — skip here so the recipient doesn't get a second push.
      if (notification.pushHandled === true) {
        logger.info("⏭️ pushHandled — inbox-only, skipping duplicate push");
        return null;
      }

      // Look up the recipient's FCM token.
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        logger.warn(`❌ Recipient ${userId} not found`);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        logger.info(`⚠️ Recipient ${userId} has no FCM token — in-app only`);
        return null;
      }

      const title = notification.title || "New notification";
      const body = notification.body || "";

      const response = await admin.messaging().send({
        token: fcmToken,
        notification: {title, body},
        data: {
          type: notification.type || "general",
          senderId: notification.senderId || "",
        },
        android: {priority: "high"},
      });

      logger.info(`✅ Push sent to ${userId}: ${response}`);
      return {success: true};
    } catch (error) {
      // A stale/unregistered token throws — log and move on, don't retry-loop.
      logger.error("❌ Error sending chat push:", error);
      return null;
    }
  }
);

// ============================================
// ⏰ RE-ELIGIBILITY REMINDER (retention)
// ============================================
// Keep in sync with DonationEligibility.cooldownDays in the Flutter app.
const COOLDOWN_DAYS = 56;
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Daily at 09:00: nudge donors whose 56-day cooldown ended in the last 24h so
 * they come back and donate again. Sends an FCM push (when a token exists) and
 * writes an in-app inbox notification via the shared helper.
 */
exports.reEligibilityReminder = onSchedule("every day 09:00", async () => {
  const now = Date.now();
  // Eligible-again = lastDonationDate + COOLDOWN_DAYS. Target the 24h window of
  // donors who crossed that line today.
  const windowEnd = new Date(now - COOLDOWN_DAYS * DAY_MS);
  const windowStart = new Date(now - (COOLDOWN_DAYS + 1) * DAY_MS);

  const snap = await admin
    .firestore()
    .collection("users")
    .where("isDonor", "==", true)
    .where("lastDonationDate", ">=", admin.firestore.Timestamp.fromDate(windowStart))
    .where("lastDonationDate", "<", admin.firestore.Timestamp.fromDate(windowEnd))
    .get();

  const tokens = [];
  const recipientIds = [];
  snap.forEach((doc) => {
    recipientIds.push(doc.id);
    const token = doc.get("fcmToken");
    if (token) tokens.push(token);
  });

  if (tokens.length) {
    await admin.messaging().sendEach(
      tokens.map((token) => ({
        token,
        notification: {
          title: "You can donate again! 🩸",
          body: "Your recovery period is over. Someone near you may need your help.",
        },
        data: {type: "re_eligible"},
        android: {priority: "high"},
      })),
    );
  }

  // Inbox copy so it appears in the Notifications screen too.
  await writeInboxNotifications(recipientIds, {
    title: "You can donate again! 🩸",
    body: "Your recovery period is over. Tap to find requests near you.",
    type: "re_eligible",
  });

  logger.info(`⏰ reEligibilityReminder: notified ${recipientIds.length} donor(s)`);
});

// ============================================
// 🧹 CLOSE EXPIRED BLOOD REQUESTS (feed hygiene)
// ============================================
// Why this exists: the app filters expired requests out of the feed
// CLIENT-SIDE, but nothing flipped their `status`, so they stayed `open`
// forever — occupying the server-side `.limit()` window and shrinking the
// visible feed. This sweep flips expired-but-open requests to `closed`.
//
// Cost design (deliberately frugal — "prevent unnecessary calls"):
//   • Runs every 6 hours (4 invocations/day), NOT on every write. Per-document
//     triggers would fire on every request create/update; a batched sweep is far
//     cheaper and the client over-fetch covers the in-between window.
//   • The query is filtered SERVER-SIDE (status == 'open' AND expiryDate < now),
//     so it reads ONLY the docs that actually need closing — never the whole
//     collection. On a healthy DB most runs read 0 docs and cost ~nothing.
//   • Does no writes when there's nothing expired (early return, no empty batch).
//   • Pages in batch-sized chunks with a hard cap so one run can't run away.
// Requires composite index: Blood_request (status ASC, expiryDate ASC).
const EXPIRE_PAGE_SIZE = 450; // Firestore batch limit is 500 ops.
const EXPIRE_MAX_PAGES = 20; // Safety cap: ≤ 9000 closes per run.

/**
 * Core sweep: flip every open-but-expired Blood_request to `closed`, paged in
 * batch-sized chunks. Extracted from the scheduled handler so it can be tested
 * directly against the Firestore emulator with a deterministic `now`.
 *
 * @param {FirebaseFirestore.Firestore} db   Firestore instance.
 * @param {FirebaseFirestore.Timestamp} now  Cutoff; requests expiring before
 *   this are closed. Passed in so tests control the clock.
 * @return {Promise<number>} count of requests closed.
 */
async function sweepExpiredRequests(db, now) {
  let totalClosed = 0;

  for (let page = 0; page < EXPIRE_MAX_PAGES; page++) {
    const snap = await db
      .collection("Blood_request")
      .where("status", "==", "open")
      .where("expiryDate", "<", now)
      .limit(EXPIRE_PAGE_SIZE)
      .get();

    // Nothing left to close — stop before doing any write work.
    if (snap.empty) break;

    const batch = db.batch();
    snap.forEach((doc) => batch.update(doc.reference, {status: "closed"}));
    await batch.commit();

    totalClosed += snap.size;

    // A short page means we've drained the backlog; don't query again.
    if (snap.size < EXPIRE_PAGE_SIZE) break;
  }

  return totalClosed;
}

exports.sweepExpiredRequests = sweepExpiredRequests;

exports.closeExpiredRequests = onSchedule("every 6 hours", async () => {
  const db = admin.firestore();
  const totalClosed = await sweepExpiredRequests(db, admin.firestore.Timestamp.now());
  logger.info(`🧹 closeExpiredRequests: closed ${totalClosed} expired request(s)`);
  return {closed: totalClosed};
});
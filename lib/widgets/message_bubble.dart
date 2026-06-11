import 'package:blood_donation/models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
    final time = DateFormat('hh:mm a').format(message.createdAt.toDate());

    final bubbleColor = isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 7.h),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
              bottomRight: Radius.circular(isMe ? 4.r : 18.r),
            ),
            // Received bubbles get a hairline border so they stay legible
            // against the scaffold even when surfaces are close in tone.
            border: isMe
                ? null
                : Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 14.5.sp, height: 1.3),
              ),
              SizedBox(height: 3.h),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

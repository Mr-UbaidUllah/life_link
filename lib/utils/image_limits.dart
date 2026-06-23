/// Maximum allowed size for an uploaded image, in bytes (10 MB).
///
/// Keep this in sync with `isImageUnder10MB()` in `storage.rules` — the client
/// gate below short-circuits oversized picks before upload, and the Storage
/// rule is the server-side enforcement of the same ceiling.
const int kMaxImageBytes = 10 * 1024 * 1024;

/// Whether a picked image of [bytes] is within the upload limit.
bool isAcceptableImageSize(int bytes) => bytes <= kMaxImageBytes;

/// Maximum allowed size for a chat attachment (image or video), in bytes
/// (50 MB).
///
/// Keep this in sync with `isChatMediaUnderLimit()` in `storage.rules`. The
/// client gate short-circuits oversized picks before upload (so the user gets a
/// friendly message instead of an opaque permission-denied), and the Storage
/// rule is the server-side enforcement of the same ceiling.
const int kMaxChatMediaBytes = 50 * 1024 * 1024;

/// Whether a picked chat attachment of [bytes] is within the upload limit.
bool isAcceptableChatMediaSize(int bytes) => bytes <= kMaxChatMediaBytes;

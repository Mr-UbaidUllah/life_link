/// Maximum allowed size for an uploaded image, in bytes (10 MB).
///
/// Keep this in sync with `isImageUnder10MB()` in `storage.rules` — the client
/// gate below short-circuits oversized picks before upload, and the Storage
/// rule is the server-side enforcement of the same ceiling.
const int kMaxImageBytes = 10 * 1024 * 1024;

/// Whether a picked image of [bytes] is within the upload limit.
bool isAcceptableImageSize(int bytes) => bytes <= kMaxImageBytes;

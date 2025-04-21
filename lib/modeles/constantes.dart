// Collection Keys
String memberCollectionKey = "members";
String postCollectionKey = "posts";
String commentCollectionKey = "comments";
String notificationCollectionKey = "notifications";

// Member Field Keys
String memberIdKey =
    "memberID"; // Often this is the document ID itself, not a field
String nameKey = "name"; // Nom
String surnameKey = "surname"; // Prénom
String profilePictureKey = "profilePicture";
String coverPictureKey = "coverPicture";
String descriptionKey = "description";

// Post Field Keys
String textKey = "text";
String postImageKey = "image";
String dateKey = "date"; // Timestamp field
String likesKey = "likes"; // Array of user IDs who liked

// Notification Field Keys
String fromKey = "from"; // User ID of sender
String isReadKey = "read"; // Boolean flag
String postIdKey = "postID"; // ID of the related post (if any)
// Notification might also need 'textKey' and 'dateKey'

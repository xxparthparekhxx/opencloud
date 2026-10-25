library opencloud.app_constants;

/// SharedPreferences key under which the combined Firebase project config JSON
/// (the "BaseConfig") is persisted.
const String kBaseConfigPrefKey = "BaseConfig";

/// SharedPreferences key under which the signed-in user's email is persisted.
const String kEmailPrefKey = "email";

/// SharedPreferences key under which the signed-in user's password is persisted.
const String kPasswordPrefKey = "password";

/// Firestore collection name that stores per-project Firebase config documents.
const String kProjectsCollection = "projects";

/// Name of the placeholder file used to materialize an empty folder
/// in Firebase Storage (folders cannot exist without at least one object).
const String kFolderPlaceholderFileName = "NEWFILEPLACEHOLDER.txt";

/// Fallback `messagingSenderId` when the Firebase config JSON does not carry
/// one. Avoids a bare magic `"0"` literal.
const String kDefaultMessagingSenderId = "0";

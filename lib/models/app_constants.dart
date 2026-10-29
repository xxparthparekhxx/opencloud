library opencloud.app_constants;

/// SharedPreferences key under which the combined Firebase project config JSON
/// (the "BaseConfig") is persisted.
const String kBaseConfigPrefKey = "BaseConfig";

/// Firestore collection name that stores per-project Firebase config documents.
const String kProjectsCollection = "projects";

/// Field of a project document holding the uid of the account that added it.
/// Owner-only Firestore Security Rules (see the README) check it against
/// `request.auth.uid`.
const String kProjectOwnerField = "owner";

/// Name of the placeholder file used to materialize an empty folder
/// in Firebase Storage (folders cannot exist without at least one object).
const String kFolderPlaceholderFileName = "NEWFILEPLACEHOLDER.txt";

/// Fallback `messagingSenderId` when the Firebase config JSON does not carry
/// one. Avoids a bare magic `"0"` literal.
const String kDefaultMessagingSenderId = "0";

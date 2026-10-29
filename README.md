# Open Cloud ☁️
An open source cloud platform for the masses.

## What is Open Cloud? ☁️
It is a multi-project Cloud Storage App. Powered By Firebase Free Tier.
Just Upload your config for your firebase project and you have your own cloud storage app.

## How does the storage work? ☁️
Open Cloud is multi-project storage: you add one or more Firebase projects through the app, and each project contributes its own Firebase Storage free-tier quota.
- Firebase Storage's free tier is **not unlimited**: it includes limited storage (5 GB) and limited daily egress (1 GB/day) per Firebase project.
- By adding multiple Firebase projects, each project's free-tier quota is available in the same app, so you can store and download more across projects.
- You can add as many Firebase projects as you want — each one is isolated and brings its own quota.

## How to use it? 🤔

1. Create a firebase project
2. Enable FireStore for the first project It will Store all the your Configurations for other firebase projects.
3. Enable Email/Password Authentication for the first project.
4. Enable Storage for all projects.
5. Register app with firebase and download google-services.json file for all projects.
6. Open the app, go to the "Add Project" screen, and pick/export each project's `google-services.json` through the in-app file picker. The config is imported at runtime — nothing is bundled in the app.
7. Create your account with your own email and password (or sign in, if you already have one). If you used a version of Open Cloud from before accounts existed, choose **Secure your existing account** instead (see below).
8. Publish the [recommended Security Rules](#recommended-firebase-security-rules) for the first project.

## Accounts 🔐
You sign in to the first project's Firebase Authentication with an email and password you choose. Firebase Auth keeps you signed in on the device; Open Cloud itself stores no credentials.

### Upgrading from an earlier version
Earlier versions signed every install in with an email and password derived from the project's Firebase API key (`<apiKey>@opencloud.org` / `<apiKey>`). API keys are not secret: they are in every config file and app built from it, so anyone with the config could sign in as you.

On first start after updating, the app asks you to **secure your account**: it signs in with the old derived credentials one last time, replaces the password with one you choose, and asks Firebase to move the account to your email address. The password changes immediately. The email change completes when you click the verification link Firebase sends to the new address; until then the account keeps its old address. If you are signed out before clicking the link, choose **Secure your existing account** on the sign-in screen and enter your new password to get a new link.

## Recommended Firebase Security Rules
### Cloud Firestore (first project)
The first project's Firestore holds the list of your projects (collection `projects`). Each entry records the uid of the account that added it in an `owner` field, and the app filters its queries to the signed-in account's entries, so these rules let each account read and write only its own entries:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /projects/{projectId} {
      allow read, delete: if request.auth != null
        && resource.data.owner == request.auth.uid;
      allow create: if request.auth != null
        && request.resource.data.owner == request.auth.uid;
      allow update: if request.auth != null
        && resource.data.owner == request.auth.uid
        && request.resource.data.owner == request.auth.uid;
    }
  }
}
```

**Upgrading:** entries created by earlier versions have no `owner`. Update the app and sign in (or secure your account) once *before* publishing these rules: the first time it loads your projects, the app tags every entry without an owner with your account, which only works while the old rules still allow it. Entries left untagged are hidden by these rules.

### Cloud Storage (every project)
Not possible yet. The app opens each storage project as a separate Firebase app and only signs in to the first project, so requests to your storage buckets carry no `request.auth`. An owner-only rule such as

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null
        && request.auth.uid == "<your uid in this project>";
    }
  }
}
```

would block the app entirely, so **do not publish it with this version**. Locking Storage down to the owner needs the app to also sign in to each storage project, which it does not do yet. Until then, your files are only as private as each bucket's current rules, and the app works only with rules that allow unauthenticated access.

## features 📋
- Multi-project Cloud Storage (each Firebase project brings its own free-tier quota)
- Public URLs for all the files on demand (make any file accessible to anyone with the link)

## Download
Get the latest build from the [GitHub Releases page](https://github.com/xxparthparekhxx/opencloud/releases). Releases are the official distribution channel; APKs are not committed to the repository.

## Roadmap 🚀
- [x] Unlimited upload upto 5gb ( per project )
- [ ] Making a website for the app
- [ ] Convering all the Projects into a Single Volume of storage so that you can download a Single file bigger then one gb.
- [ ] Sharing Files with other users 
- [ ] Access Control for files
- [ ] Making Better UI/UX

## Contributing 🤝
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License 📜
[unlicense](https://unlicense.org)

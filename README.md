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

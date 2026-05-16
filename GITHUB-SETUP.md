# Publishing to GitHub

This walks you through every step from "I have these files on my computer" to "the project is live on github.com." Pick **Path A** if you've never used Git before; **Path B** if you have, or want to learn.

---

## Before you start

You need three things:

**1. A GitHub account.** Free at [github.com/signup](https://github.com/signup).

**2. Git installed locally.** Check by opening a terminal:

```bash
git --version
```

If you see a version number (e.g. `git version 2.41.0`), you're set. If not:
- **Windows:** download from [git-scm.com](https://git-scm.com/download/win), accept the defaults during install
- **Mac:** `xcode-select --install` in Terminal, or [git-scm.com](https://git-scm.com/download/mac)
- **Linux:** `sudo apt install git` (Ubuntu/Debian) or `sudo dnf install git` (Fedora)

**3. The unzipped project folder** — `vitalis-healthcare/` containing this file, plus `sql/`, `powerbi/`, `web/`, `docs/`.

---

# Path A — Web upload (no Git, easiest)

Use this if you've never used Git before. About 5 minutes.

### 1. Create the repository

1. Sign in to [github.com](https://github.com)
2. Click the **+** in the top-right → **New repository**
3. Fill in:
   - **Repository name:** `vitalis-healthcare`
   - **Description:** `Healthcare analytics: PostgreSQL, Power BI dashboards, and a React web app on a synthetic patient dataset.`
   - **Public** so reviewers can see it
   - **Do NOT** check "Add a README", ".gitignore", or "Choose a license" — we already have these
4. Click **Create repository**

### 2. Upload your files

You'll see a "Quick setup" page. Find the link near the bottom that says **"uploading an existing file"** — click it.

1. Drag the **contents** of your `vitalis-healthcare/` folder into the upload area (the files INSIDE the folder: `README.md`, `LICENSE`, `sql/`, etc. — not the folder itself)
2. Wait for the upload to finish (the `.pbix` file and the web app source are the biggest pieces)
3. Scroll down to **Commit changes**:
   - **Commit message:** `Initial commit — full project`
4. Click **Commit changes**

Done. Your repo is live at `https://github.com/<your-username>/vitalis-healthcare`.

> **Heads-up:** GitHub's web upload has a 100-file limit per upload. If you hit it, upload one folder at a time: `sql/`, then `powerbi/`, then `web/`, then `docs/`.

### 3. (Optional) Polish

On your repo's main page:
1. Click the **gear icon** next to "About" on the right
2. Add **topics**: `healthcare`, `analytics`, `power-bi`, `sql`, `react`, `dashboard`, `data-visualization`
3. Save

These make your repo discoverable.

---

# Path B — Git workflow (recommended for ongoing work)

Use this if you've used Git before, or want to learn. About 10 minutes.

### 1. Create the repository on GitHub

Follow steps 1–3 of Path A — create the empty repo on GitHub but don't upload anything yet. Keep that GitHub tab open; you'll copy a URL from it.

### 2. Configure Git (one-time only)

```bash
git config --global user.name "Your Name"
git config --global user.email "your-github-email@example.com"
```

Use the same email you signed up to GitHub with.

### 3. Initialise the repo locally

```bash
cd path/to/vitalis-healthcare
git init
git add .
git commit -m "Initial commit — full project"
```

Git will list every file it's tracking.

### 4. Connect to GitHub and push

On the GitHub tab from step 1, find the URL of your new repo:

```
https://github.com/<your-username>/vitalis-healthcare.git
```

In your terminal:

```bash
git branch -M main
git remote add origin https://github.com/<your-username>/vitalis-healthcare.git
git push -u origin main
```

First time you push, GitHub may prompt for authentication:
- **Browser pop-up:** sign in normally
- **Command line:** GitHub no longer accepts your account password here. Generate a **personal access token** at [github.com/settings/tokens](https://github.com/settings/tokens) (Generate new token → classic → check the `repo` scope → copy the token, paste it as the password when prompted)

Refresh the GitHub repo page — your files should be there.

### 5. Future updates

After this, edits flow like:

```bash
# Make your changes in any editor

git add .                              # stage everything you changed
git commit -m "Fix DAX measure"        # describe what you did
git push                               # push to GitHub
```

---

## After publishing

### Pin the repo to your profile

1. Go to your GitHub profile (`github.com/<your-username>`)
2. Click **Customize your pins**
3. Select `vitalis-healthcare`. Save.

### Add a screenshot to the README

1. Take a screenshot of the Vitalis dashboard
2. Save it as `docs/screenshots/dashboard.png` locally
3. Near the top of `README.md` add:
   ```markdown
   ![Vitalis dashboard](docs/screenshots/dashboard.png)
   ```
4. Commit and push (or re-upload via web)

### Add status badges (optional)

Drop these near the top of your README to show project state at a glance:

```markdown
![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-blue.svg)
![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-yellow.svg)
![React](https://img.shields.io/badge/React-18-61dafb.svg)
```

### Share the link

```
https://github.com/<your-username>/vitalis-healthcare
```

Post it anywhere — résumé, LinkedIn, email signature, classroom submission.

---

## Troubleshooting

**"fatal: remote origin already exists"** — you ran `git remote add origin` twice. Run `git remote remove origin` then retry the add.

**"refusing to merge unrelated histories"** — happens if you accidentally checked "Add a README" when creating the repo. Easiest fix: delete the GitHub repo (Settings → Danger Zone → Delete), recreate it with no initial files, then re-push.

**"large file detected"** — GitHub blocks files over 100 MB. The `.pbix` file in this project is well under that limit. If you swap it for a larger one, store it externally (Google Drive, etc.) and link to it from the README.

**Web upload stalls or fails** — try smaller batches. Upload top-level files first (`README.md`, `LICENSE`, `.gitignore`, `CONTRIBUTING.md`, `GITHUB-SETUP.md`). Commit. Then upload each subfolder separately.

**"Permission denied (publickey)"** — you're using SSH but haven't set up keys. Use HTTPS instead (the URLs in the steps above use HTTPS) or follow [GitHub's SSH setup guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

---

## What you'll have at the end

A public GitHub repo at `https://github.com/<your-username>/vitalis-healthcare` containing the full project, with:

- A README that explains the project at a glance
- All three deliverables (SQL, Power BI, web app) in their own folders
- Documentation deck in `docs/`
- MIT license, contributing guidelines, gitignore
- Topics and description so it's discoverable

That's a real portfolio piece — link to it from your résumé.

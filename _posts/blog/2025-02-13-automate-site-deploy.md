---
title: Automating Site Deployment for an `nb` -> Github -> VPS Setup
description: ""
date: 2025-02-13
tags: open-source software self-hosting
---

As mentioned in the blog post on [syncing my `nb` notebook across devices using Syncthing](../blog/syncthing-nb.md), I wanted a way to auto-publish to my site after finishing a piece of writing. What I ended up coming up with was having two notebooks: _draft_ and _final_, which were structurally the same as the markdown folder in the actual website code. When done with a piece in _draft_, I `cp` it to the appropriate place in `final`, then run a bash syncing script which copies all files from _final_ to the corresponding markdown folder in my Sveltekit website repo, `git commit`'s the results, and pushes it to the remote repository. Here is the bash script I'm using, in case anyone else finds it useful. Note the environment variables which must be defined before running. It's really just a directory copying + `git commit` script:

```bash
#!/bin/bash

# Script to copy files from nb drafts to site code, then commit and push

# --- Check environment variables ---
if [ -z "$SITE_GIT_REPO_DIR" ]; then
  echo "ERROR: SITE_GIT_REPO_DIR is not set."
  exit 1
fi
if [ -z "$NB_FINAL_DRAFT_DIR" ]; then
  echo "ERROR: NB_FINAL_DRAFT_DIR is not set."
  exit 1
fi

if [ -z "$NB_FINAL_DRAFT_IMAGES_DIR" ]; then
  echo "ERROR: NB_FINAL_DRAFT_IMAGES_DIR is not set."
  exit 1
fi

if [ -z "$SITE_CODE_MD_DIR" ]; then
  echo "ERROR: SITE_CODE_MD_DIR is not set."
  exit 1
fi

if [ -z "$SITE_CODE_MD_IMAGES_DIR" ]; then
  echo "ERROR: SITE_CODE_MD_IMAGES_DIR is not set."
  exit 1
fi

# --- Copy files ---

# Copy markdown files
echo "Copying files from $NB_FINAL_DRAFT_DIR to $SITE_CODE_MD_DIR..."
cp -r "$NB_FINAL_DRAFT_DIR"/* "$SITE_CODE_MD_DIR"/

# Check if the copy command was successful.
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to copy files from $NB_FINAL_DRAFT_DIR to $SITE_CODE_MD_DIR."
  exit 1
fi

# Copy image files
echo "Copying files from $NB_FINAL_DRAFT_IMAGES_DIR to $SITE_CODE_MD_IMAGES_DIR..."
cp -r "$NB_FINAL_DRAFT_IMAGES_DIR"/* "$SITE_CODE_MD_IMAGES_DIR"/

# Check if the copy command was successful.
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to copy files from $NB_FINAL_DRAFT_IMAGES_DIR to $SITE_CODE_MD_IMAGES_DIR."
  exit 1
fi

# --- Git Commit and Push ---

# Navigate to the Git repository directory
cd "$SITE_GIT_REPO_DIR"

# Check if it's a git repository
if [ ! -d ".git" ]; then
  echo "ERROR: $SITE_GIT_REPO_DIR is not a git repository."
  exit 1
fi

# Add the changed files (only the md and images directories)
echo "Adding files to git..."
git add "$SITE_CODE_MD_DIR" "$SITE_CODE_MD_IMAGES_DIR"

# Check if there are any changes to commit
if ! git diff --cached --quiet --exit-code; then
  echo "Committing changes to git..."
  git commit -m "Update content"

  # Push the changes to the remote repository
  echo "Pushing changes to remote origin..."
  git push origin master

  # Check if the push command was successful.
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to push changes to remote origin."
    exit 1
  fi

  echo "Successfully updated remote repository."
else
  echo "No changes to commit."
fi

echo "Script completed."
exit 0

```

## Automating Deployments to VPS

I also wanted to automate deployments to the VPS I was using on every push. So essentially, my website would update every time the script ran. So I put this `deploy.yml` in `.github/workflows`:

```yml
name: Deploy to VPS

on:
  push:
    branches:
      - master

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: npm install

      - name: Build SvelteKit app
        run: npm run build

      - name: Deploy to VPS
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          password: ${{ secrets.VPS_PASSWORD }}
          source: "build/*"
          target: "/var/www/blu"
          rm: true
          strip_components: 1
```

Note that the `VPS_HOST`, `VPS_USER`, and `VPS_PASSWORD` must be defined repository/environment secrets in Github. Also note the action we're using at the end to do the actual deploy, `appleboy/scp-action`. Two parameters were important for what I was trying to do. First, `rm: true`, which deletes the target folder (`/var/www/blu` in this case) before uploading the data. In the scenario where I delete or move a file in the new build, the old file would've remained present without that parameter set, which I didn't want.

Second, the `strip_components: 1` is also important here. Without it, the `build` directory was getting placed inside `/var/www/blu`, instead of the _contents_ of the build directory moving into `blu`. So `strip_components` specifies that while I want to use `build/*` as the _source_ of my files, I only want _what's in it_, i.e. `build/*`, so don't put anything after the first slash (e.g. `build`) into `/var/www/blu`.

That's it! Now every time I update the content of the site (such as with this post), I just copy it over to _final_, then run the sync script, and voila!

---
title: "Valentine's Day. ssh-copy-id"
date: 2025-02-14
tags: journal
---

This lovely Valentine's, I learned about a cool command for automating `ssh` logins to another computer.

`ssh-copy-id` sets up the `ssh` keypair exchange for you automatically by just running it against your `username@host-ip` like so:

```bash
ssh-copy-id root@123.456.789
```

Then, it'll ask you for your password, and voila! You should now have `ssh` setup between your computer and the host such that the next time you run `ssh root@123.456.789` it will just auto-log you in, no passwords required!

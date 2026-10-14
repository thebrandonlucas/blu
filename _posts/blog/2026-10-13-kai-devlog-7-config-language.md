---
title: "Kai Devlog #7: Triumph of Roc"
description: ""
date: 2026-10-13
tags:
time: "20:12"
---

Apologies in advance for the brief post. More details to come soon.

Two months ago when I wrote [Devlog #3](https://blu.cx/posts/blog/2026-08-11-kai-devlog-3-custom-dsl-plugin-modules/), I decided to write my own custom config language for Kai. Emboldened by [Caddy](https://caddyserver.com/) having paved the way, I gambled that the long-term simplicity gains were worth it. Agents of course saved me from having to do the difficult and tedious work of learning how all of this worked at a deep level, but I was also losing even my superficial grip on it.

The "custom language", while fun in theory, distracted from the real work and was the source of a lot of developer slowdown and feature churn. Friends were requesting syntax highlighting and LSP's and such, and it quickly became higher priority to think about things this project shouldn't be slowed down by, when, as pointed out by [Luke Boswell](https://github.com/lukewilliamboswell), the Roc language was purpose-built for this!

Moving forward, Kai's config language will be done in Roc.

Thank you to [Russell Weas](https://github.com/russweas/) and [LightningKoala](https://github.com/LightningK0ala/) for your encouragement and suggestions to not roll my own config language, and especially to [Luke Boswell](https://github.com/lukewilliamboswell) for writing an amazing proof of concept that even improved upon the original design and UX of Kai and for your enlightening discussions.

Onward and upward friends. Let's make something great!




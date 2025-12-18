---
title: Toward A Better Site
description: A more thoughtful approach to personal site development
date: 2025-01-29
---

> We shall not cease from exploration  
And the end of all our exploring  
Will be to arrive where we started  
And know the place for the first time.  

- [T.S. Eliot, from “Little Gidding,” Four Quartets. Originally published 1943.](https://www.columbia.edu/itc/history/winter/w3206/edit/tseliotlittlegidding.html)

This past year, I've experimented with several different methods of creating and managing a personal website. I didn't merely want the most convenient solution, or the solution most likely to buy popularity more easily via its platform or network effects. I wanted a solution that was in line with:

- 1) A growing set of principles I want to practice see more of in software I use and create. 
- 2) A set of very unique and specific features I desired.

The pursuit of principles and features, of course, give way to the brutal constraints of reality to some degree. I don't have infinite time. And so the desire to obtain the features I want while maintaining those principles must be balanced with the constraints of time and effort. After experimenting with several iterations of website-building, I have in many ways "arrived where I started", but now feel more confident, more sure-footed, more "aligned", and more excited about what even a simple little personal website could be.

### First Site — A DIY Compromise

I started out as most Gen-Z developers start, I think. You want to be a developer, you need a portfolio. You want to be a _web developer_? Your portfolio is your website. And so my first website was just that. I built it during many skipped classes in college, while I was still painstakingly and inefficiently learning HTML, CSS, and Javascript. It was designed to be artsy and beautiful and to get me a job as a web developer. And so I didn't post or write about anything, just listed what I felt would be most impressive to recruiters. But, after proving to yourself that you can indeed get a job and you can indeed make enough to pay your rent and not be a broke college kid forever, you start to realize there's more important things in life than just trying to impress recruiters. You realize that a personal website can be so much more. It can be a _reflection of yourself_. 

And so, with that in mind, I built my first "real" attempt at a personal site. I built it in [Sveltekit](https://svelte.dev/) (which was in unstable version 3 at the time), used the [MDSveX](https://github.com/pngwn/MDsveX) library so I could write my articles in [Markdown](https://en.wikipedia.org/wiki/Markdown). This was a proper blogging site that also listed projects and "About Me" and "Contact" and whatnot, however there were several problems:

- **Hosting**: It was hosted on Netlify, which meant that there were often cold starts when visiting it. This also meant that I wasn't hosting the site myself, which wasn't a big deal to me at the time, but developed into one over the course of the year.
- **Features**: The site was low on features and bells and whistles, but this was mainly because I just didn't take the time to implement them. The fact that everything was written in Sveltekit meant that I could have, but I wasn't taking the time to really think about what I wanted implemented and then come up with a good plan to do it.
- **Preprocessing the Markdown**: I didn't quite understand how to set up the preprocessor in MDSveX properly, which does the job of converting the Markdown to HTML when building the site. What I _think_ was happening was this resulted in pages having to convert the Markdown to HTML on the fly during runtime, and so the bigger the article, the slower the page load, but I never truly investigating this since I decided to redo the website from the ground up anyway. To the end user, this just felt like the page was frozen for awhile, which was really annoying UX.
- **Content and Organization**: I wasn't sure of how I wanted things organized, and I only had a few articles, blogs, and quotes on there. The way I would write my content was by writing the article in Markdown directly on the site and then just committing and pushing the code to Github, and from there it would build and deploy to Netlify automagically. That was nice, but I would prefer to be able to write the article in another program (so that I could have "draft" versions of it and whatnot) and then just commit + push when ready in a single command/click sort of way.

All these problems contributed to a year of experimentation that left my actual ability to write things a bit in limbo. 

### Substack
I started out by just wanting something that worked, and worked well, for _writing_, without having to worry about anything else. Substack is the obvious choice for this. It's famously anti-censorship, has an intuitive UI, a large audience, most of my own subscriptions worth reading are from Substack, easy subscription tiers and connection to Stripe for payments, easy email subscriptions. What's not to like?

There was one thing that just ended up being a deal breaker for me. Probably a bizarre requirement to most people, but I just couldn't in good conscience do it. At the time, I was considering requiring subscriptions and payments for some of the articles I wrote, and on Substack, there's _no option for bitcoin payments_. The saddest thing of all is, it appears that there _was_ a way to pay with bitcoin while [Substack was using OpenNode's API](https://opennode.com/blog/bitcoin-payments-with-substack/), but don't any longer. I suppose that's a price of vendor lock-in. It is now Substack's [official policy](https://support.substack.com/hc/en-us/articles/360037862551-I-can-t-use-Stripe-Do-you-accept-PayPal-crypto-clamshells-etc) to _not_ support any bitcoin/crypto payments. I work in the Lightning Network _because_ the payments use case of bitcoin is one of if not it's most exciting aspect. It's probably one of the strongest ways bitcoin can positively influence how we use the internet. To only allow credit card subscriptions, and not bitcoin lightning micropayments, for paywalled articles if I did any would be sad and hypocritical of me. There are other reasons of course, like the fact that Substack isn't open source and that I wouldn't actually own my own data. The idea that my blog dies when the company dies was another major negative.

So what other options were there that fit my increasingly stringent criteria?

### Ghost

Enter [Ghost](https://ghost.org), a website which markets itself as essentially the more [principled and feature-rich version of Substack](https://ghost.org/vs/substack/) (which I believe they are). They are fully open source and you can run the blog software locally yourself, deploy it on a VPS of your choice, setup your own email provider, etc. If you choose to pay for them to host it for you, it's only $9 a month and that includes the ability to bring your own domain, email subscriptions, etc. A huge improvement to me, and a project and team that I was (and still am) very excited about.

They even have a marketplace of templates and integrations, and given their open-source spirit I was hopeful they'd have some sort of bitcoin integration on there — and there is one...that you have to pay for. It's called [Scribsat](https://scribsat.com/); here's the Ghost Forum [post](https://forum.ghost.org/t/a-new-bitcoin-payments-integration-scrib/36125/4) about it. They charge a monthly fee steeper than Ghost's hosting fees itself to allow you to accept bitcoin lightning payments on Ghost. That didn't really fit the bill for me, either, and I don't want to be forced to depend on another service to accept the payments for me. For what it's worth, this does seem to be a [hot topic](https://forum.ghost.org/t/bitcoin-payments/10514/37) on the Ghost Forum, and I hope that someone will take up the call of developing something people can use for this. Ghost is a great tool and company, [used by Bitcoiners](https://blog.lopp.net/), and would be powerful to many if properly combined with bitcoin payments.

I considered working on this myself, but there is significant overhead that I just didn't and don't have the time (for now) to take up.

For awhile, the lack of bitcoin-based payment options was worth it, and I paid for a full year's subscription even though I wasn't sure if I'd use it for long (I didn't, but I consider it a tithe to open-source software). I loved the writing and publishing experience, which was extremely simple, and there were a good number of default themes to choose from. However, none that I _loved_, and I found myself longing for more customizability. For most bloggers who can pay a few bucks a month or have the wherewithal to self-host, I would definitely recommend Ghost. 

### Inspiration Draws From Disparate Sources

> Shall I tell you the secret of the true scholar? It is this: Every man I meet is my master in some point, and in that I learn of him.

- [Ralph Waldo Emerson, _Greatness_](https://wist.info/emerson-ralph-waldo/65482/)

My website was hosted on Ghost for a couple months, and it actually allowed me to write an article or two and post a quote here and there, and I was starting to give up on monetizing it (was I ever really doing it for that anyway?).

But around this time I was coming into greater contact with online presences that helped me to think differently, and though they all differ radically in occupation, style, and personal beliefs, they share an energy for creating good things meant to _last_; a passion for thinking long-term and for following their hearts over easy money and fame. A desire to achieve greatness in some form or other, and to have the revenues of their considerable efforts paid in something deeper than cash.

One of those I stumbled across was [Luke Smith](https://lukesmith.xyz/), a thoroughly original person, whose unique admixture of Twitter-like meme humor, dead-serious power usage of FOSS-only tech, deep historical, philosophical, and linguistic knowledge, and opinionated take on Christianity fascinated me, even if I didn't agree with many of his opinions and means of presenting that information. It's rare to find a person occupying all those particular spheres simultaneously, particularly in technology. From him I learned to ask for more from my software, to seek and value the right to and practice of _ownership_, whether that's in owning your own land, owning your own money (bitcoin, being debt-free), or owning your own technology to the highest degree possible. He even [removed all credit card-based ways to donate to him](https://lukesmith.xyz/updates/retiring-fiat-donation-portal/) on his website, as they weren't in keeping with his principles. I used his tutorial website on becoming an [Internet Landlord](https://landchad.net/) by self-hosting a website on your own DNS, for example, to build and host the version of this site at the time of writing. Another thing that is important to him is to have technology be a _tool you use_, rather than you be _its' tool_. To that end, he helped encourage me to try to build and use software that will last, and focus less on the ephemeral. Not an easy pursuit in the software world, open source or otherwise!

Another figure who influenced this blog is [Henrik Karlsson](https://www.henrikkarlsson.xyz/), whose article [_A blog post is a very long and complex search query to find fascinating people and make them route interesting stuff to your inbox_](https://www.henrikkarlsson.xyz/p/search-query) had a deep impact on me and the direction of my thinking about how a blog should be made. It is excellent, both the idea and the read.

[Zig](https://ziglang.org/) creator Andrew Kelley, also comes to mind, whose article [_Why We Can't Have Nice Things_](https://andrewkelley.me/post/why-we-cant-have-nice-software.html) helped me realize the incredible waste that often goes into making products worse when money alone is the goal.

[Visakan Veerasamy](https://visakanv.com/)'s article [_We Were Voyagers_](https://visakanv.substack.com/p/we-were-voyagers) is also an amazing and deeply encouraging read, and while it didn't directly influence how I built this website, it further influenced the "do something useful to others with your life in a spirit of gratitude" approach I'm trying to take to life in general, and will have an effect on the prose and content of the site if nothing else.

But the final major influence was [gwern.net](https://gwern.net/), whose beautiful and carefully crafted website design is matched by its rich content and elegant prose. It's filled with a hundred little features, optimizations, and design decisions that make it a joy to use. For example, it has custom [page previews](https://www.mediawiki.org/wiki/Page_Previews) which allow you to see a preview of where a link will take you when hovering over it. It has tables of contents and footnotes for each article, and the footnotes become sidenotes on wide screens for convenience. He takes the time to design artsy [dropcaps](https://en.wikipedia.org/wiki/Initial) for each article. And something I found very interesting that I've never seen before, is his extensive use of local archives to fight against [linkrot](https://en.wikipedia.org/wiki/Link_rot), which is an important problem if we wish to preserve something of ourselves for the future. Read his [about page](https://gwern.net/about) for the site to learn more.

All told, Gwern's website appears to me an exercise in how to create an optimal personal website for the long-run. He summarizes the fundamental question of building a site from the link above:

> What does it take to present, for the long-term, complex, highly-referenced, link-intensive, long-form text online as effectively as possible, while conserving the reader’s time & attention?

This version of my site, though still nascent, is based on a fuzzy mesh of these influences, and I will make the attempt to improve it and make it more resilient and higher quality over time.

### Knowing the Place for the First Time 

Who was I kidding? I'm a _web developer_. I should've known from the beginning it would feel wrong to me to outsource that task, despite the work it may have taken. So after a year of exploration, I'm back at doing the same thing I did before — building the website in Sveltekit and MDsveX. But hopefully this time better, and having learned a lot about how to practically achieve that in addition to learning my own reasons for trying to do so in the first place.

Before, building my own website was a cool thing to put on my resume. But this time I have my _reasons_.

### What Now?

My primary reason for building this site is to document everything I do that I think might be of use to someone else (or my future self). I want something that I built myself and which I have full control over, whose format I have the freedom to modify or restructure at any time (which I couldn't do in my previous methods). I want something that allows me to publish articles, blogs, daily journals, quotes I find interesting, projects I'm working on, what have you, in as frictionless a manner as possible while still retaining maximum expressive possibilities. Which, in essence, means I have to build things myself, and that there will be a high up-front cost to doing so. 

So be it!

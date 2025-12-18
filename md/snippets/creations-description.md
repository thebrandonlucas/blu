# **Creations**

---

_More very fun things are on the way, stay tuned..._

---

## [nix.fun](https://nix.fun)

A work-in-progress website dedicated to helping people solve problems with [Nix](https://github.com/NixOS/nix).

---

## [Bitcoin QR Web Component: `bitcoin-qr`](https://bitcoin-qr-demo.netlify.app)

![Image of `bitcoin-qr` samples](/md/posts/contributions/bitcoin-qr.png)

_Add your company's image and style the QR to match!_

I created a [web component](https://developer.mozilla.org/en-US/docs/Web/API/Web_Components) to make it easy to create BIP 21 compatible QR codes with a lot of developer-and-user-friendly defaults. One problem I consistently ran into when developing lightning applications was having to repeatedly build a QR code component with HTTP polling to check for payment, in addition to making many UX decisions about when to use BIP 21 for `bitcoin:` and `lightning:` URI prefixes and how to handle query params. Additionally, I found myself reimplementing a component that did all this in each framework (i.e. React, Svelte) I was using. As far as I know, everyone who's building UIs in bitcoin has to keep redoing this work.

I decided it would be valuable (to myself, if nobody else) to build a universal web component that came with all this functionality out of the box with maximum configuration but opinionated defaults, that could be used in any [framework](https://qr-code-styling.com) or in pure HTML. And for extra fun, it's built on a framework that allows a lot of styling customization!

Feedback on this would be very much appreciated, please feel free to [open an issue](https://github.com/thebrandonlucas/bitcoin-qr) if you find a problem or have any suggestions for improvement!

<!-- - [lazynix](): A tool for getting things done the lazy way with Nix. Like [lazygit](https://github.com/jesseduffield/lazygit), but for Nix! -->
<!-- ## [NixOS dotfiles](#placeholder) -->
<!---->
<!-- My [NixOS](https://github.com/NixOS/nix) setup containing my [Hyprland](https://hypr.land/) , [`neovim`](https://neovim.io/), and [Home Manager](https://github.com/nix-community/home-manager) configs, as well as the programs I have installed. You can use this to get essentially the same exact desktop setup as me. -->

---

### Archive

**Old ideas and proof-of-concepts that never went anywhere (the vast majority of my projects) but that were very fun, interesting, or operating at the cutting edge in their time**

---

### [nostrlytics.com](https://github.com/thebrandonlucas/nostrlytics)

When the first major hype wave for [Nostr](https://nostr.com/) occurred and the Bitcoin community didn't know all the problems we'd face building on Nostr, I was learning the horrifyingly painful yet flexible [D3](https://d3js.org/) and decided to use a little bit of what I learned to build a little website with a chart that allowed you to input your public key and a relay websocket endpoint to view some basic statistics about your "profile".

Of course, all we Nostrlytes were taught a powerful lesson in network effects by the all-encompassing [Twitter/x.com](https://x.com) behemoth, and it hasn't really caught on to this day despite the huge amount of hype and developer effort in the Bitcoin community.

That said, I still believe that the public-key-based identity system, combined with Bitcoin micropayments for skin-in-the-game interactions and valueless bot-posts that thrive on X, Nostr is one of the simplest, freest, and most decentralized forms of communication we've invented that could actually work.

As behemoth centralized services continue to degrade and add anti-features due to their illusions of invincibility, these alternatives will hopefully become ever-more usable and appealing to broad audiences.

---

[Video LSAT](https://github.com/thebrandonlucas/video-lsat)

The first idea I was interested in when I discovered the magic of the [Lightning Network](https://lightning.network) was the idea of subscriptionless video streaming. The idea that you could simply pay-as-you-go, as opposed to the Subscription Hell of modernity, was hyper-appealing. People could save money, have no ads, and pay pennies to watch full length movies, and both creator and customer would be better off. It would utilize LSATs (now renamed [L402](https://www.l402.org/) after the HTTP status code) to accept Bitcoin Lightning payments to watch a video. That was the idea, anyway.

Aside from latency issues caused by the number of requests you'd need to do to make this work at the micro-scale (I was insane enough to try to do payments by the second), I found that the real problem, like with most things, wasn't technological. It wasn't that we didn't _know how_ to do it or that _nobody had tried_. It was the horrifying realization that most people are pretty complacently fine with their ads (if it means they get to consume "for free" -- as if their both their time and data didn't hold immense value) and their subscriptions (which they often forgot they were paying for after signing up). The surest sign to me that Americans have far too much money for their own good, despite our incessant griping, is that we have so little imagination and will for how life could be better in every way if we were willing to make the smallest up-front sacrifice.

The most common response I got from people when I proposed this idea to them was "Why would I pay for what I can get for free?", without realizing that we are selling little pieces of our souls this way, and that the costs of actually watching a video would be so small it would actually be cheaper relative to the time saved.

Anyway, a competing project that did it better anyway emerged around the same time, [lightning.video](https://lightning.video/), and essentially became half a porn site, half a Bitcoin site. Such is life in the Bitcoin world.

---

### [SatGPT](https://github.com/thebrandonlucas/satgpt)

In the earlier days of the GPTs, the only way you could use them was to have a subscription from a big provider like ChatGPT. Taking a cue from the video-lsat project above, I built a little system under which the server company could simply take an API key for themselves and allow users to "top up" an account anonymously by paying in bitcoin micropayments. Very fun project whose idea was supplanted and done better by [ppq.ai](https://ppq.ai/), which is a service I love and highly recommend.

---

### [Micropayments Demo](https://github.com/thebrandonlucas/micropayments)

When I was helping mentor at the 2023 MIT Bitcoin Hackathon, I built a simple demo app to show how to use micropayments with Lightning (on LND/Voltage nodes).

---

### [BLUCoin](https://github.com/thebrandonlucas/BLUCoin)

After reading Jimmy Song's [Programming Bitcoin](https://github.com/jimmysong/programmingbitcoin) book, I decided to build a minimal bitcoin-based cryptocurrency from scratch with Python, which was an immensely gratifying and difficult experience.

---

### [thebestme](https://github.com/thebrandonlucas/thebestme)

I made an attempt by building a mental health app in React Native designed to help people take control of their mental health by utilizing thought-challenging journaling techniques, habit tracking, and mood tracking.

---

### [Combat Deepfakes](https://github.com/thebrandonlucas/combat-deepfakes)

Back when [Dapps]() were all the rage with Ethereum and before I became disillusioned with it in favor of Bitcoin, [Deepfakes]() were becoming a major concern as the first machine learning technology which could convincingly create fake face swapping videos. I realized we could use the blockchain to create a time-stamping system in which all that was needed to "prove" which video was the real one, was to hash the video and put it on the blockchain, and if another video came later attempting to claim _it_ was the real one, just compare the hash and timestamp of the original.

I thought this may become a cataclysmic problem in our present day, where perhaps politicians would be made to make proclamations of war or revenge porn videos (which are actually, sadly, real), but so far in 2025 this seems to have mainly been used to make funny meme videos and at worst cause very temporary political stirs which are quickly shut down, and in regards to the porn problem, so many people are either voluntarily naked online or have already had photos leaked anyway that the taboo of internet nudity associated with your face has been rapidly diluted, turning would-be reputation-enders into merely deeply embarrassing ephemeral mishaps.

So so far, this ended up not being anywhere near the problem I thought it would be, but perhaps the full ramifications of this have not yet come home to roost.

---

### [lightscameraalabama](https://lightscameraalabama.com)

While I was a student at University of Alabama I built a website in React.js to host historical videos for an Honors College program which encouraged students to make films about Alabama history.

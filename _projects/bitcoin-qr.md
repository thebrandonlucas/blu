---
title: "bitcoin-qr"
tagline: "A zero-dependency QR code web component for BIP-21 Bitcoin and Lightning payments."
url: "https://bitcoin-qr-demo.netlify.app"
repo: "https://github.com/thebrandonlucas/bitcoin-qr"
status: "maintained"
order: 5
---

<picture>
  <source srcset="/images/contributions/bitcoin-qr.avif" type="image/avif">
  <img src="/images/contributions/bitcoin-qr.webp" alt="Image of bitcoin-qr samples" width="800" height="443" loading="lazy">
</picture>

_Add your company's image and style the QR to match!_

I created a [web component](https://developer.mozilla.org/en-US/docs/Web/API/Web_Components) to make it easy to create BIP 21 compatible QR codes with a lot of developer-and-user-friendly defaults. One problem I consistently ran into when developing lightning applications was having to repeatedly build a QR code component with HTTP polling to check for payment, in addition to making many UX decisions about when to use BIP 21 for `bitcoin:` and `lightning:` URI prefixes and how to handle query params. Additionally, I found myself reimplementing a component that did all this in each framework (i.e. React, Svelte) I was using. As far as I know, everyone who's building UIs in bitcoin has to keep redoing this work.

I decided it would be valuable (to myself, if nobody else) to build a universal web component that came with all this functionality out of the box with maximum configuration but opinionated defaults, that could be used in any [framework](https://qr-code-styling.com) or in pure HTML. And for extra fun, it's built on a framework that allows a lot of styling customization!

Feedback on this would be very much appreciated, please feel free to [open an issue](https://github.com/thebrandonlucas/bitcoin-qr) if you find a problem or have any suggestions for improvement!

---
title: <bitcoin-qr/> - A Zero-Dependency Web Component for Stylish BIP-21 Payments
description: A QR code web component for Bitcoin on-chain, Lightning, and unified BIP-21 payments
date: 2025-02-21
tags: bitcoin
---

<span class="flex justify-center w-[100px]">
<img src="/images/blog/bitcoin-qr/qr.webp" alt="Bitcoin QR Example" width="594" height="596" loading="lazy">
</span>

When developing a Bitcoin payment flow, there are multiple ways a user can expect to be able to pay. They might want to pay an on-chain address or Lightning invoice, they may be scanning a QR Code from their phone, copy/pasting from a wallet, or using a [WebLN](https://www.webln.guide/) browser extension. Creating an intuitive interface that also captures all the possible ways a user can pay is one of the fundamental UX challenges of developing an application that can receive payments in Bitcoin.

This flexibility opens up many [exciting use cases](https://blu.cx/articles/bitcoin/micropayments), but often comes at the cost of being able to easily develop a smooth experience for the user. The greater the developer's cognitive load, the more difficult it is to create intuitive UX.

This project aims to provide everything needed to allow standard Bitcoin & Lightning Network payments out of the box. It handles creating the proper [URIs](https://github.com/bitcoin/bips/blob/master/bip-0021.mediawiki) from just an address or invoice, and favors creating unified URIs whenever possible. Styles are highly customizable and images can be embedded. It also includes polling functionality -- a callback can be passed as a property of the element to periodically check for payment.

Check it out on [Github](https://github.com/thebrandonlucas/bitcoin-qr) and feel free to play around with the options and create your own [here](https://bitcoin-qr.blu.cx).

In addition, because it's a [web component](https://developer.mozilla.org/en-US/docs/Web/API/Web_components), you should just be able to drop it into any framework and have it work, whether it's pure HTML, Sveltekit, React, making it very versatile. Examples are included in the Github repo.

Here's a quick demo of how to use it in Sveltekit:

Install:

```sh
yarn add bitcoin-qr
```

Then:

```svelte
<script lang="ts">
  import { defineCustomElements } from 'bitcoin-qr/loader';

  defineCustomElements();
</script>

<bitcoin-qr
 id="qr"
 width="300"
 height="300"
 bitcoin="bc1p4mqqpxdyg3l0tvpv9xaesw5rsqv7fqpcn9ydawx3e8yr4enmc3qq7m59vd"
 lightning="lno1zrxq8pjw7qjlm68mtp7e3yvxee4y5xrgjhhyf2fxhlphpckrvevh50u0q2a8y2qt9jeu3pj7p3u58rxs98yu93dxjlmy3eqp24qze09anfr6cqszm40686ujqq7t9jsjjf42tl2pryv3ds9f4hm6hysk7lvswdm70ntsqvlgc5nm4px6k3q2wmj4xun784sss2jn00q0w4dhydmln92wvash6jckffu0wmetwptj38f5g09k8pznuk4wq2df046yv0c5m3dakwgfz5ths2ymm3z6vnehvxj6urcarufa7uecwqqst9x4063hdpxq4frmupnsam9ahg"
 parameters="amount=0.00001&label=bitcoin-qr.blu.cx&message=bitcoin-qr.blu.cx"
 image="./assets/bitcoin.svg"
 is-polling="false"
 poll-interval="1000"
 type="svg"
 corners-square-color="#000000"
 corners-dot-color="#000000"
 corners-square-type="extra-rounded"
 dots-type="classy-rounded"
 dots-color="#000000"
 debug="true"
 poll-callback={callbackExample}
/>
```

I built this about a year ago but didn't post about it because there was more I wanted to do and test before putting it out there. But there's always something else to do, isn't there?

If you find any issues, feature requests, or suggestions for improvement, feel free to [create an issue](https://github.com/thebrandonlucas/bitcoin-qr/issues/new) in Github.

Hope this saves you some time!

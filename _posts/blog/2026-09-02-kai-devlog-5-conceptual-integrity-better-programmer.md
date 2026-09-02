---
title: "Kai Devlog #5: Conceptual Integrity and Being a Better Programmer"
description: Building Kai for the long term through conceptual integrity, better tools, deliberate practice, and dogfooding.
date: 2026-09-02
tags: nix software open-source
layout: "Post"
---

> In the beginning all you want are results, in the end all you want is control.
>
> [Eskil Steenberg](https://www.youtube.com/@eskilsteenberg), [How I Program in C](https://www.youtube.com/watch?v=443UNeGrFoM)

<!-- Keep adjacent quotations as separate blockquotes. -->

> Life is long enough, and it has been given in sufficiently generous measure to allow the accomplishment of the very greatest things if the whole of it is well invested.
>
> Seneca, [_On the Shortness of Life_](https://standardebooks.org/ebooks/seneca/dialogues/aubrey-stewart)

<!-- Keep adjacent quotations as separate blockquotes. -->

> Most European cathedrals show differences in plan or architectural style between parts built in different generations by different builders. The later builders were tempted to "improve" upon the designs of the earlier ones, to reflect both changes in fashion and differences in individual taste. So the peaceful Norman transept abuts and contradicts the soaring Gothic nave, and the result proclaims the pridefulness of the builders as much as the glory of God.
> Against these, the architectural unity of Reims stands in glorious contrast. The joy that stirs the beholder comes as much from the integrity of the design as from any particular excellences. As the guidebook tells, this integrity was achieved by the self-abnegation of eight generations of builders, each of whom sacrificed some of his ideas so that the whole might be of pure design.
> Even though they have not taken centuries to build, most programming systems reflect conceptual disunity far worse than that of cathedrals [...] I will contend that conceptual integrity is *the* most important consideration in system design. It is better to have a system omit certain anomalous features and improvements, but to reflect one set of design ideas, than to have one that contains many good but independent and uncoordinated ideas.
> 
> Fred Brooks, [_The Mythical Man-Month_](https://en.wikipedia.org/wiki/The_Mythical_Man-Month)

![Reims Cathedral](/images/blog/kai-devlog-5/reims-cathedral.jpg)

This update might be a bit unusual, as I want to write an update but also some a little more personal about my experience of programming.

Working on Kai is making me a better programmer. I can feel it. There are two things that are true of Kai that were never true of a programming project for me before:

1. I'm building something from scratch as its progenitor, that
2. Is completely open source, that
3. I want to last a long time

I've taken serious aim at all but (3) before, but the longer I live the more Karl Popper's maxim of working on long-term problems speaks to me:

> I think that there is only one way to science - or to philosophy, for that matter: to meet a problem, to see its beauty and fall in love with it; to get married to it and to live with it happily, till death do ye part - unless you should meet another and even more fascinating problem or unless, indeed, you should obtain a solution. But even if you do obtain a solution, you may then discover, to your delight, the existence of a whole family of enchanting, though perhaps difficult, problem children, for whose welfare you may work, with a purpose, to the end of your days.
> 
> Karl Popper, [Realism and the Aim of Science](https://www.routledge.com/Realism-and-the-Aim-of-Science-From-the-Postscript-to-The-Logic-of-Scientific-Discovery/BartleyIII-Popper/p/book/9780415084000)

By taking Kai _seriously_, by striving to make something that provides as close to a _strictly better_ experience in using computers (to the extent achievable, there's [*No Silver Bullet*](https://www.cgl.ucsf.edu/Outreach/pc204/NoSilverBullet.html)), I am forced to think harder than I ever have about _what_ I'm building and _why_, the alignment between my highest-level end-goals and day to day tasks, how to make incremental progress every day which is aligned with these goals, how to maintain motivation, etc.

The genuine attempt to build something great is a forcing function for practices which lead to mastery.

As such, I've been doing a lot of reading (and more writing than I've ever done before!).

Sometimes I make mistakes or take some shortcuts of course. I think it can be very helpful to make something badly at first and just *get it out there*, share it, and get feedback from other really smart people in the community.

Kai is already starting to get *fun*, *real*, and *useful*, so I'm working to ensure it stays that way for a long time.

There's been two releases since the [last update](/posts/blog/2026-08-17-kai-devlog-4-environment-task-build-workflow): [προιεναι - 0.0.5](https://github.com/thebrandonlucas/kai/releases/tag/v0.0.5) (means "to proceed") and [ετυγχανε - 0.0.6](https://github.com/thebrandonlucas/kai/releases/tag/v0.0.6) (means "it happened"), and a lot of changes in them.

So many changes, where to start? Let's just follow [Stephen King's](https://stephenking.com/works/nonfiction/on-writing-a-memoir-of-the-craft.html) advice for novels on this one, and just _skip the boring stuff_.

## External Features!

Let's start with the fun stuff relevant to *you*, dear reader. Here are the new Kai commands added to the `StdPlugin` since the last update.

### Source

Not all things that a project needs are always in `nixpkgs`. Sometimes you need to declare an external link to a URL `tar` or something, as was the case for me with `aion` (also built in Roc), where I had to declare `bitcoin-qr` (a QR code NPM package I wrote for adding bitcoin payments to your site) URL as a source as this isn't on `nixpkgs`. This is really useful and makes Kai far more flexible!

```Kaifile
source bitcoin-qr {
  url: "tarball+https://registry.npmjs.org/bitcoin-qr/-/bitcoin-qr-1.4.1.tgz"
}

build aion {
  environment: cli
  source: "src/aion.roc"
  output: "aion"
}
```

### Machine

The `machine` block allows us to define full NixOS closures which we can then deploy or activate (for already-extant NixOS machines), which when combined with Kai can run services on startup or have particular packages installed.

Invoke with `kai machine <name>`

```Kaifile
# Build a typed NixOS deployment closure with `kai machine agent`.
environment server {
  packages: ["curl"]
}

machine <name> {
  environment: server
  system: "x86_64-linux"
  users: ["<name>"]
  services: ["openssh"]
}
```

### Image

That's great, but what if we don't already have a machine and want to create a *bootable* NixOS image? You can do that too via the `image` command! Which builds a generic QCOW2 image from a `machine` definition. For example, `kai image agent` turns the `agent` machine in your `Kaifile` into a portable image that a cloud provider can import.

I was able to test and verify this works on Digital Ocean via `aion` (below). The definition looks the same as machine, but it is invoked via `kai image <name>`:

```Kaifile
# Build a generic QCOW2 image from the same machine definition.
environment server {
  packages: ["curl"]
}

machine <name> {
  environment: server
  system: "x86_64-linux"
  users: ["<name>"]
  services: ["openssh"]
}
```

### Service

Services are basically programs that run on startup and just continue running in the background. Caddy is a good example: You just want a web server that's always on and routing requests to your sites. A crucial prerequisite if Kai is going to be useful in spinning up NixOS machines on desktop or in the cloud.

Example:

```Kaifile
# A service turns an executable build artifact into a NixOS systemd service.
environment cow {
  packages: ["cowsay"]
}

build cow {
  environment: cow
  run: ["sh", "-c", "cp \"$(command -v cowsay)\" cow"]
  output: "cow"
}

service cow {
  artifact: "cow"
  secrets: []
  restart: on-failure
}
```

### Secret

A secret is basically an environment variable in either your shell, or machine, etc. This allows people to have the same machine but have behavior change based on the environment variables they set or have them set API keys or whatnot that allow them to use services. For example, I used `aion` to spin up a machine that ran [`pi`](https://pi.dev) coding agent connected to my [ppq.ai](https://ppq.ai) API key. So in one command I could spin up a NixOS machine based on a `Kaifile` that had an agent running on it!

Example:

```Kaifile
environment cow {
  packages: ["cowsay"]
}

# Build the "cow" program artifact
build cow {
  environment: cow
  run: ["sh", "-c", "printf '#!%s\\ntest -s \"$CREDENTIALS_DIRECTORY/message\"\\nexec %s \"secret loaded\"\\n' \"$(command -v sh)\" \"$(command -v cowsay)\" > cow && chmod +x cow"]
  output: "cow"
}

# Secret values stay outside the Kaifile. For this example, put
# "classified moo" in /run/kai/secrets/message on the machine.
secret message {
  provision: runtime
}

# Systemd passes the file to the service without exposing its contents.
service cow {
  artifact: "cow"
  secrets: ["message"]
  restart: on-failure
}
```

## Internal Updates

## Plugin Overhaul (again)

I once more redid the Plugin system, and I'll frankly probably do it again. Getting this right is really important because it's where anyone (yes, *you!*) can add your own code to Kai to create your own plugins and features outside of `std`. I won't yet go into the details because it isn't *quite* there yet, but suffice to say that I've spent a lot of time making this much more self-documenting and a better abstraction. My goal is to get to the point where new users can "just dive in" making and experimenting with their own plugins.

## Tidy.roc

[matklad](https://matklad.github.io/) has a wonderful [article](https://matklad.github.io/2025/12/06/mechanical-habits.html#Tidy-Script) on automating desired patterns of behavior for your codebase via a [tidy](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/tidy.zig) script they made at [TigerBeetle](https://tigerbeetle.com/). This is a really cool concept and one I wished I'd considered sooner. Basically, imagine you just wrote your own linter, but not merely to enforce generic code style rules, but also to enforce *invariants* that you seek to ensure your code maintains, without you having to manually ensure it. This is essentially another additional layer of ensuring conceptual integrity for the project, for whatever invariants you care about.

I started simple in Kai, just adding a `Tidy.roc` which enforces:

1. Every code module has a top-level explainer comment
2. Limit line length to 80 (some really long strings were getting hard to read)

Tigerbeetle's `tidy.zig` does so much more, of course, and some things I'd like to do, like ensuring large blobs don't get committed (once they're merged in that history, they're hard to remove!).

But the real value is that I now have a script that I can edit to analyze my codebase on every commit and ensure nothing has violated a growing list specific list of invariants!

## Guix Shell

[_The Mythical Man-Month_](https://en.wikipedia.org/wiki/The_Mythical_Man-Month) talks a lot about the importance of maintaining Conceptual Integrity in a program, and much of my research and thinking around Kai has evolved around this concept. Conceptual Integrity is the idea that your program should be _aligned_ conceptually around what it's supposed to be doing, and that this drifts as programs grow over time because exceptions are made

He suggests multiple implementations as a means to do ensure the design does what you want and is not too tied to your specific implementation. After all, one thing we're trying to explore with Kai is the bounds of a *generic* determinate system -- we need not and should not repeat Nix's mistakes or tie ourselves too closely to their architectural mistakes.

So, just as a proof of concept for now that Kai will indeed work with two systems, I added just a single Guix shell command, which proved out that the `command`/`backend`/`implementation` architecture works for both Nix and Guix!

You can compile it with `nix run .#xkai -- build plugins/guix/GuixPlugin.roc`.

Then run `./kai shell guix`.

One day, I hope this flexibility will allow us to surgically replace problematic parts of Nix, in an incremental and backward compatible way, with our own implementation of a determinate system!

## Fuzzer

I've never fuzzed code before, and I'll admit to ignorance on a lot of the theory and practice, especially with regards to practical benefit. But with [Luke Boswell's](https://github.com/lukewilliamboswell) new [Roc fuzzer library](https://github.com/lukewilliamboswell/roc-fuzz), and given that it was just a small bit of code surface to run for my parser (which fuzzers are apparently pretty good for), I decided to give it a try. Right now it's only implemented for a portion of the parsing code, but it's nice to know I have a way of easily and automatically testing thousands of inputs to the parser!

## Dogfooding Kai

So far I've created two in-progress greenfield projects with Kai with the robot. This has proven a lot of the use case for Kai. But I'll also be adding it to extant projects like [lyceum.quest](https://lyceum.quest/), [conllu.lyceum.quest](https://conllu.lyceum.quest/), and this personal website, to prove that Kai can be used both for hosting and deployments, as well as developer environments and builds.

### Aion

I built a *very* vibe coded (use at your own risk!) tool to dogfood Kai with that I actually also really wanted for myself, which allowed me to spin up NixOS servers on [DigitalOcean](https://www.digitalocean.com/) at-will which spin up machines according to their Kai configuration. With this I was able, for example, to spin up an agent that "just works" and allows me to build things on that box with environment secret variables, services, packages, and just declarative computer setups in general, via just a single `Kaifile`!

This feels like a huge milestone, because one of the goals of Kai is to be able to augment/replace the traditional interface of using NixOS. If you can spin up easy to read declarative, version-controllable operating systems easily, it's a massive game-changer for the headache of maintaining and remembering how you set up software environments. Your operating system setup becomes self-documenting, portable, shareable, trivially modifiable, trivially rollback-able, and now, because it's not written in Nix, understandable!

The greater eventual ambition with this will be to allow people to use something like a `KaiOS` as a *desktop* as well, just like you can with NixOS. Then, maybe we can steal some of the hope from Omarchy and prove to DHH that Nix-for-Desktop *can* be made easy ;)

There are a lot of knobs to think about before doing this in earnest, but we've already come a long way.

It's completely open source and you can use it with your own Digital Ocean account (they're one of the few that allow you to spin up custom NixOS servers).

If people are interested in something they don't have to manage themselves I'd consider spinning this up into a paid service on the Ghost model (that is, open source and you can do everything yourself, but paid/managed/hosted version for allowing you to spin up out-of-the-box products on the fly if you don't want to worry about everything yourself).

### Gump

With [all](https://github.blog/news-insights/company-news/addressing-githubs-recent-availability-issues/) [the](https://github.blog/news-insights/company-news/an-update-on-github-availability/) [recent](https://github.blog/news-insights/company-news/github-availability-report-july-2026/) [problems](https://blog.incidenthub.cloud/github-actions-pages-outage-aug-6-2026) [with](https://github.blog/news-insights/company-news/the-august-17-outage-and-the-work-ahead) [Github](https://www.theverge.com/news/757461/microsoft-github-thomas-dohmke-resignation-coreai-team-transition) [lately](https://mitchellh.com/writing/ghostty-leaving-github), I figured I'd try my hand at a (again, *very vibecoded*) version-control system with a few twists.

I'm calling it [Gump](https://github.com/thebrandonlucas/gump) (short for `git dump`!). The goals are:

1. Self-hostable alt to Github
2. Allows for portable *projects*, not just portable *code*. i.e., issues, pull requests, wiki updates, etc. should all be concepts built into and portable with the VCS, like [Fossil](https://fossil-scm.org/) but for decentralized work like `git`.
3. Treats `jj` concepts as first-class as opposed to `git`. Like Nix, most people who've spent the time to figure out `jj` seem to far prefer it as a major innovation over `git`. Plus, unlike Nix but very much like Kai, `jj` is completely backward compatible with `git` and your teammates don't even need to know you're using it.  it on the concepts behind `jj`  (which, like with Nix, most who've taken the time to actually learn and use it *love* it, but there is a curve).
4. Easy to use CLI, usable by agents with configurable permissions

The main goal, of course, is simply to work on Kai. It's going to be extremely opinionated and bespoke to my wants, if I keep working on it at all. It's going to do weird stuff like probably only use public key encryption for auth (the fact that most still do "check your inbox for an email code" is insane and backward). Or take [matklad's](https://matklad.github.io/) advice of [queueing PR merges by default](https://matklad.github.io/2023/06/18/GitHub-merge-queue.html) instead of waiting for the merge button to be green, then reviewing, then clicking merge.

Who knows? Maybe this will even lead to building a `jj`-based generic `magit` style editing experience too. There's so much to improve upon.

There are a lot of [problems we forgot](https://www.scattered-thoughts.net/writing/pain-we-forgot) because we were all just using `git` and Github so long that we forgot to question many basic assumptions.

There are of course a whole host of things Github does really well that would be extremely difficult to replicate, but it's also been really bad lately and the coding world is beginning to wake up to the idea that maybe it was not-so-great idea to make all of open source code in the world dependent on a single company.

I don't want to distract too much from Kai though, and if I actually start using/depending on this I'll need to throw it away because Kai development comes first and foremost and I need to stay focused on the bigger goal, but still, this is a fun idea to pursue.

## Bootstrapping and Playing with Kai

You can try Kai without installing it by running `nix run github:thebrandonlucas/kai -- version`. A project can also use a small `Kaifile.bootstrap` to build its own project-local `./kai`, then use that binary for every development, build, and deployment workflow from then on. That is how Aion and Gump keep their custom Kai plugins reproducible without requiring a global installation.

## Notes and Learnings

### Making Code Smaller

[Jonathan Blow](https://www.youtube.com/watch?v=JjDsP5n2kSM) has a talk where he has an interesting section about how "deleting code is always a good thing". I'm not sure I agree completely, but a common theme I'm noticing in all these investigations is that conceptual integrity, and an understanding of the entire system is paramount to maintaining good code.

One aspect of understanding things well is having less things to understand. Deleting code while keeping it readable is one way to do this. This also means deleting anything that feels superfluous, inessential, etc. It means careful abstraction when helpful, and no abstraction when not.

Lines of code I think can generally be a helpful metric for whether code is getting smaller but it's not the full story. If your code is very DRY but opaque, the true workings of it buried under layers and layers of indirection, what was the point?

## Testing Must Be Done Up Front

SQLite creator [Richard Hipp](https://www.sqlite.org/crew.html) says in his excellent [Software Should Work](https://www.youtube.com/watch?v=V_qzqY1bb7I) talk about making SQLite *probably* the most-used piece of software in the world are:

1. Extreme portability. As Hipp says, "it's just a file you can email to your friends!"
2. It just works. He primarily attributes this to an *extreme* approach to testing. In fact, there is far more test code in SQLite than code being tested!

I will admit with some shame that I do not have any test yet other than a single integration test that doesn't block CI. At first, I just blindly told the bot to add tests "in the style of ['How to Test'](https://matklad.github.io/2021/05/31/how-to-test.html)" which was silly and lazy and didn't solve my essential problem: Helping to know *what* my code did (free documentation) and more importantly give me *confidence* that it worked.

If I have confidence that what I have works and that I'm building on a solid foundation.

The main reason I don't have much testing is that I'm heavily debating and considering my strategy. *How to Test* says that tests should be cheap, operate at the [boundaries](https://www.destroyallsoftware.com/talks/boundaries) of your interface, operate only on data (i.e. only do CPU work, no I/O), and therefore be *fast*, that they should be very easy to maintain (or else you won't want to do them), and more.

That's a lot of things to think about! Roc thankfully makes much of that easy by having a `!` marker to declare effect*ful* and effect*free* (pure) code, and so if you just trivially separate the code which performs effects from the code which just operates on pure data (same input always results in same output). This means if you just test the pure functions your tests will run fast. But I was finding that my tests were adding a lot of surface area, that I didn't understand very well how they worked or what they were doing, and they therefore didn't give me much confidence and in fact hampered my understanding of the code.

So, in the meantime, I wrote a `zig build kaifiles` command which just runs all the Kaifiles in the `examples` folder end-to-end. I figured that since the examples demonstrate and run through basically all syntax using the simple `cowsay` program, having those work and actually seeing their output gives me a lot of confidence that at least the happy path is consistently working. I didn't block `zig build ci` with these since they're niether pure nor fast, which may be a mistake, and that has bitten me (while writing this, I realized the command failed because I hadn't run it in awhile!), so I may change that.

But a major next step for me is figuring out and working hard on the right fast test boundary so I can start building more confidence moving forward that Kai doesn't have many bugs.

I should probably also add an invariant to `tidy.roc` to verify that every block of Kai's `StdPlugin` `Kaifiles` are used. As we add new blocks, the examples won't include them all automatically without some rule.

## Dependency Cultures

[Richard Feldman's](https://github.com/rtfeldman) [_Dependency Cultures_](https://www.youtube.com/watch?v=E82ly38YEEQ) talk at [Software Should Work](https://softwareshould.work/) really took me out of my Javascript bubble and got me asking deeper questions about what tools I should be using.

There are real downsides to the Tigerbeetle approach of manually maintaining _all_ of your own tools and needing to understand _everything_ about your program. I don't have a great grasp of assembly or the theory of electricity and yet I can still write code to make computers do things. Tools and dependencies do exist for a reason.

*But*.

There are two edges to this sword. If you take a short enough view, never having sought or gained a deeper understanding of how the things you use work, you'll always be spending your time learning things which don't last and are always changing.

The more time I've spent in the room with the creators of great things, they tend to have a deep understanding of the foundational structures of the tools they use and are building on, and as a result are much more versatile and capable. As new technologies slowly die in favor of newer technologies, they are less and less affected, because the deeper down into the foundations you go.

There's a line between the practical utility of leveraging new technologies and the foundational stability of learning the old ones, and I think in tech by our very nature we're drawn to the former more than we generally should be.

Often, if you think about the software you love the most that's lasted the longest, it's usually by people who spend a lot of time learning *deeply*.

## The Tools You're Using Are Enough

Relatedly, one of matklad's articles linked to a [John Carmack](https://twitter.com/id_aa_carmack/status/989951283900514304) discussion about "just using the tools you already have". Since this is being built in a language for which the compiler is being rebuilt, I run into a lot of bugs. So, because:

a) I'm excited to help in some small way contribute to this great new language
b) I want to use more reliable, fast tools (who doesn't?) and Roc's model fits that well
c) There's less mental overhead and more conceptual integrity in using one tool
d) It's fun and I get to do a bunch of mini-projects in one in the language.
e) Not all code is equally important. The code that checks your code is less important than the primary code, and I don't need to anguish over every tiny detail.

## Trunk-based Development

[This article](https://web.archive.org/web/20220517144332/https://ourmachinery.com/post/step-by-step-programming-incrementally/) struck an idea in my mind that I can't get out: every commit should add value to the codebase. This is *hard* to think about how to do properly, since features rarely lend themselves to single-commit completion! But there are tricks to do so for bigger features as noted in the article, and even in reviewing agent constructed code the idea of constantly merging things to `master` has been helping tremendously in avoiding merge not only cumbersome merge conflicts but just keeping the program all in my head, which is becoming more and more important as features keep getting added. The rapid development speed increases in adding more features provided by agents means that a lot of discipline is required to monitor them, reign them in, maintain control over what the code should actually be doing, and simplifying it. Agents have a huge bias in favor of bloat, and I've actually found it pretty hard to have them keep things *simple*, *small*, and *easy to understand*. Trunk-based development helps by reducing the number of concepts I'm having to keep up with at once.

## Thoughts on Commits

Different projects have different philosophies on what a commit is, it seems, which has consequences for how your repo history is written and what history you allow to be merged. Mitchell Hashimoto, for example, thinks 1 PR equals 1 commit. Therefore a commit is the mergeable, PRable unit of change. So, the process would be something like: work on your feature locally, adding WIP commits or whatever as you go, then, amending, rebasing, fixup'ing, etc. when you're done into a single commit that you push and merge.

[According](https://mitchellh.com/writing/contributing-to-complex-projects) to Hashimoto, that final mergeable product should be +50/-50 ideally (easy to review, small incremental change) but no greater than +500/-500 (beyond that it starts getting difficult for a human to review).

Matklad has a looser [definition](https://matklad.github.io/2023/12/31/git-things.html), in that commit history can show the *progress* of how the final idea came to be. So a commit doesn't need to necessarily be an isolated independent unit of work, the merge commit can be that, but it should tell a cohesive, easy to understand *story* about how you got there (and therefore you should still rebase/amend/fixup your WIP or exploration commits into something comprehensible by later review). He finds this useful as you can more easily trace the *why* and *how* for features and bugs when doing `git blame`, and if you have the merge commits, you already have the "final commit" at which that feature got merged.

I've been tending to favor Matklad's approach on this, and trying to balance/reconcile that with [this article](https://web.archive.org/web/20220517144332/https://ourmachinery.com/post/step-by-step-programming-incrementally/)'s trunk-based development approach where each commit can still provide independent value.

Also, I just started using [`jj`](https://jj-vcs.github.io/jj/latest/), the new darling VCS of most who take the time to use it, it seems, and that also requires a huge rethinking of how to do all these things.

Regardless, I'm trying to pay much more attention now to the utility of the history.

## AI Use

### Matklad's "Loop Closing" Strategy

Vibe coding has been both great and terrible for me. It's difficult to find the right middle ground between having the robot do everything for you and doing everything yourself old-school. Obviously typing every `for` loop yourself should no longer be necessary. But I do think I should at least read every loop, and if I can't understand the code (which I frequently can't) that's a red flag for me. This is becoming increasingly important and increasingly my bar: if I can't understand the code as I read through it, it's not good enough. This means that I either need to add comments (I plan on adding *many* more comments as part of cleaning up this codebase) or name variables something better, or either abstract more or even sometimes abstract less (abstracting can [make internals unnecessarily opaque](https://matklad.github.io/2020/08/15/concrete-abstraction.html)).

But one strategy I've been trying that's been working as a nice middle ground (though I still need a bit more discipline) is:

1. Create a `.gitignore`'d directory called `plans`.
2. Inside `plans`, create a folder for `my-feature-plan` or `my-bug-fix`
3. Inside `my-feature-plan`, create a `spec.md`
4. Describe, in as much detail with as many real and specific examples you can of how you'd like the thing to work, the feature, fix, or refactor
5. Tell the AI to create a `plan.md` which follows repository rules and splits the work into small, reviewable, independently value-adding chunks (Using [Mitchell Hashimoto's](https://mitchellh.com/writing/contributing-to-complex-projects) rule of +50/-50, no more than +500/-500 -- a human (me!) has to read all the code after all!). Tell it to give examples of what it intends to do
6. Review and refine that plan (I always find I underspecify and the AI didn't get what I meant exactly)
7. Tell it "Do first chunk", review that chunk, merge into `master`. Sometimes if I've got multiple things going I'll be lazy and just have it do all the chunks at once but even with all the invariants, CI checks on every commit, and commit rules, I find this still bites me and I have to end up having it redo things. So I'm becoming more convinced that smaller chunks, each reviewed by a human before moving on, is still the way.

## Focus, Motivation, Mistakes

### Focus Focus Focus!

Focusing, for me, is *really hard*. I am constantly mentally bombarded with messages from friends and family (a good thing in and of itself, but it shreds my attention if I find myself constantly checking/waiting for replies as a kneejerk reaction to not working), emails (usually useless), Twitter (maybe 5-10% useful per unit time with careful curation), etc.

I have to play all sorts of tricks on myself because the internet as it stands is adversarial by default: that is, more helpful than harmful to my overall happiness and effectiveness unless I actively take steps to make it a positive. I have to *work* to make a computer a net positive for me (which is a big part of what I want Kai to help with), despite it being a universal constant in my life.

### Maintaining Motivation

Read [this](https://www.scattered-thoughts.net/writing/setting-goals) fantastic blog on programming and just a lot of good general life advice.

Sometimes, I'll find that reading and re-reading my code with the purpose of refactoring just doesn't sound fun. Or thinking about testing strategy or whatever. And then I don't want to do it. And then I find myself trying to reach for Yet Another Side Project instead of just making the software I want most (Kai) great.

I'm trying to employ several tricks to get around this, such as:
- Work in smaller and smaller chunks
- Walk away from the computer when tired and, if I still want to feel like I'm making progress, read a book on programming that would help (e.g. *The Mythical Man-Month* or *The Cathedral and the Bazaar*) read a blog article, or watch a talk
- Sharing! Writing blog posts takes a lot of effort, even relatively simple or sloppy, plain-English ones like this one. But even just slight positive feedback from real humans who would like to use this is uber-motivating. And, it helps me think through things at a high-level again and remind myself what I'm really trying to do and forces me to understand the system I built better.
- Frequent releases (Mechanical Habits)
- Working on automating *processes*. E.g. creating a release script which makes releasing as simple as `zig build release ...`
- Releasing frequently. Doing "the whole vertical" from top to bottom for every small change or small set of changes, that is, writing code, running it, testing it, releasing it, and writing about it, all frequently, makes the whole process run smoother and be less stressful. If you deploy every small change to prod every day, prod deploys accumulate less cruft, become muscle memory, and each one has a lower surface area for problems. [Many eyes make all bugs shallow](http://www.catb.org/~esr/writings/cathedral-bazaar/cathedral-bazaar/) much faster in that case. Plus, it's more exciting for both you and people who like your project!
- Dogfood your project into another project. I can't tell you how exciting it was to just say to an agent: "Build thing X. For anything that isn't code itself, you are only allowed to use `kai`. No bash scripts, no `python` helpers, no `nix`. Just `kai`" and have it work! It's a bit clunky, but in Aion and Gump, you really can do everything you need to do, from develop to deploy, using Kai!

Some other great sources I'm borrowing from are:
- [matklad's How to Test](https://matklad.github.io/2021/05/31/how-to-test.html)
- [Mitchell Hashimoto](https://mitchellh.com/)

### Mistakes

I've already found myself making a lot of mistakes with Kai:

- Overreliance on AI. It takes a lot of discipline to not just keep building and instead fixing what you already have and trying to make it great. That said, if I spend a whole year working on Kai in isolation, just to rip it apart and throw it away in favor of some new implementation when someone points out a completely better architecture, I won't feel bad about not trying to achieve *perfection* on the first go before even sharing it. 
- Not reading code enough ([Don't write bugs!](https://www.teamten.com/lawrence/programming/dont-write-bugs.html)). And, as a result, having some of the internals of things like the parser or assembler remain a bit fuzzy in my brain.
- Getting distracted. I think it was an overall positive to vibe code [Aion](https://github.com/thebrandonlucas/aion) and [Gump](https://github.com/thebrandonlucas/gump) (and vibing was *absolutely* the correct decision in their case -- anything more would have meant spending an unjustifiable amount of time on two projects I may might 1. throw away or 2. distract from Kai too much).

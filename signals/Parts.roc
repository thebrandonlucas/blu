import pf.Engine exposing [Attr, Elem, Signal]
import blu.Site
import BluStore

## The pieces every page is made of: elements, links, the bar and the
## footer. Each is the markup site.roc writes for the same piece, so the app's
## page is the static page it replaces.
Parts := [].{

	## An element with a class ("" for none).
	el : Str, Str, List(Elem(ctx)) -> Elem(ctx)
	el = |tag, cls, children| Engine.element(tag, Parts.classes(cls), children)

	classes : Str -> List(Attr(ctx))
	classes = |cls| if cls.is_empty() { [] } else { [Engine.class(cls)] }

	## An element holding a text that follows a value.
	text_el : Str, Str, Signal(ctx, Str) -> Elem(ctx)
	text_el = |tag, cls, text| Engine.element(tag, Parts.classes(cls), [Engine.text_s(text)])

	## `body` when `show` holds, else nothing.
	maybe : Signal(ctx, Bool), (() -> Elem(ctx)) -> Elem(ctx)
	maybe = |show, body| Engine.when(show, body, || Engine.text(""))

	## Whether a link stays in the app: an address on this site that is a
	## page, not a feed, and has no fragment for the browser to scroll to.
	## Every other link is followed by the browser, which for a page of the
	## site loads its static copy, where the app starts again.
	inside : Str -> Bool
	inside = |href| href.starts_with("/") and !href.contains("#") and !href.ends_with(".xml")

	## A link with a fixed label, class and address.
	link : Str, Str, Str -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	link = |label, cls, href|
		if Parts.inside(href) {
			Engine.element("a", Parts.classes(cls).concat([Engine.attr("href", href), Engine.on("click:prevent", BluStore.go(href))]), [Engine.text(label)])
		} else {
			Engine.element("a", Parts.classes(cls).concat([Engine.attr("href", href)]), [Engine.text(label)])
		}

	## A link whose label and address follow values.
	link_s : Signal(ctx, Str), Str, Signal(ctx, Str) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	link_s = |label, cls, href|
		Engine.when(
			href.map(Parts.inside),
			|| Engine.element("a", Parts.classes(cls).concat([Engine.attr_s("href", href), Engine.on("click:prevent", BluStore.go_by(href))]), [Engine.text_s(label)]),
			|| Engine.element("a", Parts.classes(cls).concat([Engine.attr_s("href", href)]), [Engine.text_s(label)]),
		)

	## Links with " · " between them.
	links : List({ href : Str, label : Str }) -> List(Elem(ctx))
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	links = |list|
		list.map(|l| Parts.link(l.label, "", l.href)).intersperse(Engine.text(" · "))

	## The body of a document, as site.roc's HTML for it, in an element of
	## class `cls`. The `blu-markup` element (site.js) puts the HTML in place,
	## and hands a click on a link to another page of the site back as a
	## change, which goes there.
	markup : Str, Signal(ctx, Str) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	markup = |cls, html| Engine.element("blu-markup", Parts.classes(cls).concat([Engine.attr_s("data-html", html), Engine.on("change", BluStore.go_to({}))]), [])

	crest : {} -> Elem(ctx)
	crest = |{}| Engine.element("img", [Engine.attr("src", "/images/favicon.webp"), Engine.attr("alt", ""), Engine.attr("width", "59"), Engine.attr("height", "80")], [])

	## The site's navigation, marking the area `area` names.
	nav : Signal(ctx, Str) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	nav = |area|
		Engine.element(
			"nav",
			[Engine.class("site-nav"), Engine.attr("aria-label", "Site")],
			Site.nav_links.map(
				|l| Engine.element("a", [Engine.attr("href", l.href), Engine.attr_s("aria-current", area.map(|a| if a == l.area { "page" } else { "" })), Engine.on("click:prevent", BluStore.go(l.href))], [Engine.text(l.label)]),
			),
		)

	## The bar atop every page but the home page.
	top_bar : Signal(ctx, Str) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	top_bar = |area|
		Parts.el(
			"header",
			"top-bar",
			[
				Engine.element("a", [Engine.class("home-link"), Engine.attr("href", "/"), Engine.on("click:prevent", BluStore.go("/"))], [Parts.el("span", "crest-small", [Parts.crest({})]), Parts.el("span", "blackletter", [Engine.text(Site.site_name)])]),
				Parts.nav(area),
			],
		)

	## The footer, with the year the site was built in.
	footer : Signal(ctx, Str) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	footer = |year|
		Parts.el(
			"footer",
			"site-footer",
			[
				Engine.element("a", [Engine.class("crest-small"), Engine.attr("href", "/"), Engine.attr("aria-label", "Home"), Engine.on("click:prevent", BluStore.go("/"))], [Parts.crest({})]),
				Parts.el("p", "", Parts.links(Site.footer_links)),
				Parts.el("p", "copyright", [Engine.text("© "), Parts.text_el("span", "", year), Engine.text(" ${Site.site_name}")]),
			],
		)

	section_head : Str, Str, Str -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	section_head = |title, href, label|
		Parts.el("div", "section-head", [Parts.el("h2", "", [Engine.text(title)]), Parts.link("${label} →", "", href)])

	feed_link : Signal(ctx, Str) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	feed_link = |href| Parts.el("p", "feed", [Parts.link_s(Engine.const("RSS feed"), "", href)])

	dagger : {} -> Elem(ctx)
	dagger = |{}| Engine.element("span", [Engine.class("dagger"), Engine.attr("aria-hidden", "true")], [Engine.text("†")])
}

expect Parts.inside("/posts/blog/x/")
expect !Parts.inside("/posts/journal/2026/10/13/#10-49")
expect !Parts.inside("https://github.com/thebrandonlucas")
expect !Parts.inside("/rss.xml")

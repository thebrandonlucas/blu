import pf.Engine exposing [Elem, RowRef, Signal]
import blu.Dates
import blu.Route
import blu.Site exposing [Data, Entry]
import blu.Text
import BluStore
import Model
import Parts

## Each kind of page, drawn from what `Model` works out for it. A page is
## one branch of the root's `switch`: its kind fixes its structure, and the
## page it shows (which post, which day) arrives as values, so moving
## between two posts rewrites the texts and links that differ and keeps the
## rest.
Pages := [].{

	## What a page is drawn from: the data and the page.
	At : { data : Data, page : Route.Page }

	## The branch for a kind of page.
	view : Model.Kind, Signal(ctx, At) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	view = |kind, at|
		match kind {
			Waiting => Engine.text("")
			Home => Pages.home(at.map(|a| Model.home(a.data)), at.map(|a| Dates.year_of(a.data.today)))
			Post => Pages.post(at)
			Quote => Pages.quote_page(at)
			Project => Pages.project_page(at)
			Plain => Pages.plain(at)
			Writing => Pages.index(at, Pages.writing(at))
			Section => Pages.index(at, Pages.section(at))
			Journal => Pages.index(at, Pages.journal(at))
			Month | Day => Pages.index(at, Pages.journal_page(at))
			Quotes => Pages.index(at, [Engine.element("div", [Engine.class("quotes")], [Engine.each(at.map(|a| a.data.quotes.map(Model.quote)), |q| q.entry.url, |row| Pages.quote_block(row.item(), Engine.const(Bool.True)))])])
			Projects => Pages.index(at, [Pages.project_cards(at.map(|a| Model.projects(a.data))), Parts.el("p", "more", [Parts.link("Older projects and experiments", "", "/archive/")])])
			Tags => Pages.index(at, [Pages.tag_cloud(at.map(|a| Model.tags(a.data.writing)))])
			Tag => Pages.index(at, [Pages.entries(at.map(|a| Model.listed(a.data, a.page))), Parts.el("p", "more", [Parts.link("All tags", "", "/tags/")])])
			Changelog => Pages.index(at, [Pages.commits(at.map(|a| Model.commits(a.data)))])
			NotFound => Pages.index(at, [Parts.el("p", "more", [Parts.link("All writing", "", "/writing/")])])
		}

	year : Signal(ctx, At) -> Signal(ctx, Str)
	year = |at| at.map(|a| Dates.year_of(a.data.today))

	area : Signal(ctx, At) -> Signal(ctx, Str)
	area = |at| at.map(|a| Model.area(a.page))

	# -----------------------------------------------------------------------
	# Pages

	home : Signal(ctx, Model.Home), Signal(ctx, Str) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	home = |h, built|
		Engine.element(
			"div",
			[Engine.class("page wide")],
			[
				Parts.el(
					"header",
					"masthead",
					[
						Engine.element("a", [Engine.attr("href", "/"), Engine.class("crest"), Engine.on("click:prevent", BluStore.go("/"))], [Parts.crest({})]),
						Parts.el("h1", "blackletter", [Engine.text(Site.site_name)]),
						Engine.element("p", [Engine.class("greek"), Engine.attr("lang", "grc")], [Engine.text(Site.greek_name)]),
						Parts.el("p", "tagline", [Engine.text("Writing on software, history and philosophy; building "), Parts.link("Kai", "", "/projects/kai/"), Engine.text(" and "), Parts.link("Lyceum", "", "/projects/lyceum/"), Engine.text(".")]),
						Parts.nav(Engine.const("home")),
					],
				),
				Parts.maybe(
					h.map(|m| !m.featured.is_empty()),
					|| Parts.el("section", "home-featured", [Parts.section_head("Featured", "/writing/", "All writing"), Pages.featured(h.map(|m| m.featured))]),
				),
				Parts.el(
					"section",
					"home-writing",
					[
						Parts.section_head("Latest", "/writing/", "All writing"),
						Parts.maybe(h.map(|m| m.has_lead), || Pages.lead(h.map(|m| m.lead))),
						Pages.entries(h.map(|m| m.latest)),
					],
				),
				Parts.maybe(
					h.map(|m| !m.fragments.is_empty()),
					|| Parts.el(
						"section",
						"home-journal",
						[
							Parts.section_head("Journal", "/posts/journal/", "The whole journal"),
							Parts.el(
								"ul",
								"fragments",
								[
									Engine.each(
										h.map(|m| m.fragments),
										|f| f.url,
										|row| Parts.el("li", "", [Parts.link_s(row.field(|f| f.date), "date", row.field(|f| f.url)), Parts.text_el("p", "", row.field(|f| f.excerpt))]),
									),
								],
							),
						],
					),
				),
				Parts.el("section", "home-building", [Parts.section_head("Building", "/projects/", "All projects"), Pages.project_cards(h.map(|m| m.projects))]),
				Parts.maybe(h.map(|m| m.has_quote), || Parts.el("section", "home-quote", [Pages.quote_block(h.map(|m| m.quote), Engine.const(Bool.False))])),
				Parts.el(
					"section",
					"home-about",
					[
						Parts.section_head("About", "/about/", "More about me"),
						Parts.el(
							"p",
							"",
							[
								Engine.text("I'm a software engineer, mostly in Bitcoin: Lightning payments at "),
								Parts.link("Voltage", "", "https://voltage.cloud"),
								Engine.text(" and privacy at "),
								Parts.link("Payjoin", "", "https://payjoin.org"),
								Engine.text(". I'm learning Ancient Greek, and read history and philosophy."),
							],
						),
						Parts.el("p", "also", Parts.links(Site.also_links)),
					],
				),
				Parts.footer(built),
			],
		)

	## The newest piece, at the head of the home page's list.
	lead : Signal(ctx, Entry) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	lead = |e|
		Parts.el(
			"article",
			"lead",
			[
				Pages.kicker(e),
				Parts.el("h2", "", [Parts.link_s(e.map(|x| x.title), "", e.map(|x| x.url))]),
				Parts.text_el("p", "", e.map(|x| x.description)),
				Engine.element("a", [Engine.class("more"), Engine.attr_s("href", e.map(|x| x.url)), Engine.on("click:prevent", BluStore.go_by(e.map(|x| x.url)))], [Engine.text("Read "), Parts.dagger({})]),
			],
		)

	post : Signal(ctx, At) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	post = |at| {
		p = at.map(|a| Model.post(a.data, Model.entry_of(a.page)))
		e = p.map(|x| x.entry)
		Engine.element(
			"div",
			[Engine.class("page narrow")],
			[
				Parts.top_bar(Pages.area(at)),
				Engine.element(
					"article",
					[Engine.class_s(e.map(|x| "piece ${x.kind}"))],
					[
						Parts.el(
							"header",
							"",
							[
								Pages.kicker(e),
								Parts.maybe(p.map(|x| x.heading), || Parts.text_el("h1", "", e.map(|x| x.title))),
								Engine.element("p", [Engine.class("meta")], [Engine.element("time", [Engine.attr_s("datetime", e.map(|x| x.date))], [Engine.text_s(e.map(|x| Dates.long_date(x.date)))]), Engine.text_s(p.map(|x| x.meta))]),
								Parts.maybe(p.map(|x| !x.standfirst.is_empty()), || Parts.text_el("p", "standfirst", p.map(|x| x.standfirst))),
							],
						),
						Parts.maybe(
							p.map(|x| !x.series.is_empty()),
							|| Parts.el(
								"aside",
								"series",
								[
									Parts.text_el("p", "kicker", p.map(|x| x.series)),
									Parts.el(
										"ol",
										"",
										[
											Engine.each(
												p.map(|x| x.in_series),
												|s| s.url,
												|row| Engine.element(
													"li",
													[Engine.class_s(row.field(|s| if s.here { "here" } else { "" }))],
													[Engine.when(row.field(|s| s.here), || Engine.text_s(row.field(|s| s.title)), || Parts.link_s(row.field(|s| s.title), "", row.field(|s| s.url)))],
												),
											),
										],
									),
								],
							),
						),
						Parts.maybe(
							p.map(|x| !x.toc.is_empty()),
							|| Parts.el(
								"details",
								"toc",
								[
									Parts.el("summary", "", [Engine.text("Contents")]),
									Parts.el("ol", "", [Engine.each(p.map(|x| x.toc), |h| h.url, |row| Engine.element("li", [Engine.class_s(row.field(|h| h.level))], [Parts.link_s(row.field(|h| h.title), "", row.field(|h| h.url))]))]),
								],
							),
						),
						Parts.markup("markdown", e.map(|x| x.html)),
						Parts.el(
							"footer",
							"",
							[
								Parts.maybe(
									p.map(|x| !x.project.url.is_empty()),
									|| Parts.el("aside", "project-note", [Engine.text("Part of "), Parts.link_s(p.map(|x| x.project.title), "", p.map(|x| x.project.url)), Engine.text(": "), Engine.text_s(p.map(|x| x.project.tagline))]),
								),
								Pages.tag_links(e.map(|x| x.tags)),
								Parts.el("nav", "neighbours", [Pages.neighbour(p.map(|x| x.older), "Older", "older"), Pages.neighbour(p.map(|x| x.newer), "Newer", "newer")]),
							],
						),
					],
				),
				Parts.footer(Pages.year(at)),
			],
		)
	}

	neighbour : Signal(ctx, Model.Link), Str, Str -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	neighbour = |l, label, cls|
		Engine.when(
			l.map(|x| !x.url.is_empty()),
			|| Engine.element("a", [Engine.class(cls), Engine.attr_s("href", l.map(|x| x.url)), Engine.on("click:prevent", BluStore.go_by(l.map(|x| x.url)))], [Parts.el("span", "kicker", [Engine.text(label)]), Engine.text_s(l.map(|x| x.title))]),
			|| Parts.el("span", cls, []),
		)

	quote_page : Signal(ctx, At) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	quote_page = |at|
		Engine.element(
			"div",
			[Engine.class("page narrow")],
			[
				Parts.top_bar(Pages.area(at)),
				Parts.el("article", "piece quote", [Pages.quote_block(at.map(|a| Model.quote(Model.entry_of(a.page))), Engine.const(Bool.True))]),
				Parts.footer(Pages.year(at)),
			],
		)

	## A quote, with who said it and, when `dated`, a link to its own page.
	quote_block : Signal(ctx, Model.Quote), Signal(ctx, Bool) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	quote_block = |q, dated|
		Parts.el(
			"figure",
			"quotation",
			[
				Parts.el("blockquote", "", [Parts.markup("", q.map(|x| x.entry.html))]),
				Parts.el(
					"figcaption",
					"",
					[
						Engine.text("— "),
						Engine.when(q.map(|x| x.link.is_empty()), || Engine.text_s(q.map(|x| x.source)), || Parts.link_s(q.map(|x| x.source), "", q.map(|x| x.link))),
						Parts.maybe(dated, || Parts.el("span", "when", [Engine.text(" · "), Parts.link_s(q.map(|x| x.date), "", q.map(|x| x.entry.url))])),
					],
				),
			],
		)

	project_page : Signal(ctx, At) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	project_page = |at| {
		p = at.map(|a| Model.project(a.data, Model.entry_of(a.page)))
		e = p.map(|x| x.entry)
		Engine.element(
			"div",
			[Engine.class("page narrow")],
			[
				Parts.top_bar(Pages.area(at)),
				Parts.el(
					"article",
					"piece project",
					[
						Parts.el(
							"header",
							"",
							[
								Parts.el("p", "kicker", [Parts.link("Projects", "", "/projects/"), Pages.badge(e)]),
								Parts.text_el("h1", "", e.map(|x| x.title)),
								Parts.text_el("p", "standfirst", e.map(|x| x.tagline)),
								Parts.maybe(
									p.map(|x| !x.links.is_empty()),
									|| Parts.el(
										"p",
										"links",
										[
											Engine.each(
												p.map(|x| x.links),
												|l| l.label,
												|row| Engine.element(
													"span",
													[],
													[
														Engine.text_s(row.field(|l| l.before)),
														Parts.link_s(row.field(|l| l.label), "", row.field(|l| l.href)),
													],
												),
											),
										],
									),
								),
							],
						),
						Parts.markup("markdown", e.map(|x| x.html)),
						Parts.maybe(
							p.map(|x| !x.posts.is_empty()),
							|| Parts.el("section", "related", [Parts.text_el("h2", "", e.map(|x| "Writing about ${x.title}")), Pages.entries(p.map(|x| x.posts))]),
						),
					],
				),
				Parts.footer(Pages.year(at)),
			],
		)
	}

	badge : Signal(ctx, Entry) -> Elem(ctx)
	badge = |e| Parts.maybe(e.map(|x| !x.status.is_empty()), || Parts.text_el("span", "badge", e.map(|x| x.status)))

	plain : Signal(ctx, At) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	plain = |at| {
		e = at.map(|a| Model.entry_of(a.page))
		Engine.element(
			"div",
			[Engine.class("page narrow")],
			[
				Parts.top_bar(Pages.area(at)),
				Parts.el("article", "piece page", [Parts.el("header", "", [Parts.text_el("h1", "", e.map(|x| x.title))]), Parts.markup("markdown", e.map(|x| x.html))]),
				Parts.footer(Pages.year(at)),
			],
		)
	}

	## An index page: a heading, a line on what it lists, and the list.
	index : Signal(ctx, At), List(Elem(ctx)) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	index = |at, content| {
		i = at.map(|a| Model.index(a.page))
		Engine.element(
			"div",
			[Engine.class("page narrow")],
			[
				Parts.top_bar(Pages.area(at)),
				Parts.el(
					"main",
					"index",
					List.concat(
						[
							Parts.el(
								"header",
								"",
								[
									Parts.text_el("h1", "", i.map(|x| x.title)),
									Parts.maybe(i.map(|x| !x.intro.is_empty()), || Parts.text_el("p", "standfirst", i.map(|x| x.intro))),
								],
							),
						],
						content,
					),
				),
				Parts.footer(Pages.year(at)),
			],
		)
	}

	writing : Signal(ctx, At) -> List(Elem(ctx))
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	writing = |at| {
		chosen = at.map(|a| Site.featured(a.data.writing))
		[
			Parts.maybe(chosen.map(|c| !c.is_empty()), || Parts.el("section", "featured-block", [Parts.el("h2", "", [Engine.text("Featured")]), Pages.featured(chosen)])),
			Parts.el("p", "sections", Parts.links(Site.section_links)),
			Engine.each(
				at.map(|a| Model.years(a.data.writing)),
				|y| y.year,
				|row| Parts.el("section", "year", [Parts.text_el("h2", "", row.field(|y| y.year)), Pages.entries(row.field(|y| y.entries))]),
			),
		]
	}

	section : Signal(ctx, At) -> List(Elem(ctx))
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	section = |at| [
		Pages.entries(at.map(|a| Model.listed(a.data, a.page))),
		Parts.feed_link(at.map(|a| "/posts/${Route.section(a.page)}/rss.xml")),
	]

	journal : Signal(ctx, At) -> List(Elem(ctx))
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	journal = |at| [
		Engine.each(
			at.map(|a| Model.months(a.data.writing)),
			|m| m.month,
			|row| Parts.el("section", "month", [Parts.el("h2", "", [Parts.link_s(row.field(|m| m.title), "", row.field(|m| m.url))]), Pages.day_groups(row.field(|m| m.days))]),
		),
		Parts.feed_link(Engine.const("/posts/journal/rss.xml")),
	]

	## A month's or a day's page of the journal.
	journal_page : Signal(ctx, At) -> List(Elem(ctx))
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	journal_page = |at| {
		days = at.map(|a| Model.journal_days(a.data, a.page))
		month = at.map(
			|a|
				match a.page {
					Day(d) => Dates.month_of(d)
					_ => ""
				},
		)
		[
			Engine.when(
				month.map(Str.is_empty),
				|| Pages.day_groups(days),
				|| Engine.element("div", [Engine.class("fragments-of-day")], [Engine.each(days.map(|ds| ds.join_map(|d| d.fragments)), |f| f.entry.url, |row| Pages.fragment(row.item()))]),
			),
			Parts.el(
				"p",
				"more",
				[
					Parts.maybe(month.map(|m| !m.is_empty()), || Engine.element("span", [], [Parts.link_s(month.map(Dates.month_name), "", month.map(Site.month_url)), Engine.text(" · ")])),
					Parts.link("The whole journal", "", "/posts/journal/"),
				],
			),
		]
	}

	## Journal entries under a heading for each day.
	day_groups : Signal(ctx, List(Model.Day)) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	day_groups = |days|
		Engine.element(
			"div",
			[Engine.class("days")],
			[
				Engine.each(
					days,
					|d| d.date,
					|row| Parts.el(
						"section",
						"day",
						[
							Parts.el("h3", "", [Parts.link_s(row.field(|d| d.title), "", row.field(|d| d.url))]),
							Engine.each(row.field(|d| d.fragments), |f| f.entry.url, |frag| Pages.fragment(frag.item())),
						],
					),
				),
			],
		)

	## One journal entry: when it went out (its link), the project it's
	## about, and what it says.
	fragment : Signal(ctx, Model.Fragment) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	fragment = |f|
		Engine.element(
			"article",
			[Engine.class("fragment"), Engine.attr_s("id", f.map(|x| x.id))],
			[
				Parts.el(
					"header",
					"",
					[
						Engine.element("a", [Engine.class("date"), Engine.attr_s("href", f.map(|x| x.entry.url)), Engine.attr("title", "Link to this entry")], [Engine.text_s(f.map(|x| x.when))]),
						Parts.maybe(f.map(|x| !x.project.is_empty()), || Parts.link_s(f.map(|x| x.project), "entry-project", f.map(|x| "/projects/${x.project}/"))),
					],
				),
				Parts.markup("markdown", f.map(|x| x.entry.html)),
			],
		)

	# -----------------------------------------------------------------------
	# Lists

	## Pieces of writing: when, what, which kind, and what it is about.
	entries : Signal(ctx, List(Entry)) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	entries = |list| Engine.element("ul", [Engine.class("entries")], [Engine.each(list, |e| e.url, Pages.entry)])

	entry : RowRef(ctx, Entry) -> Elem(Engine.Row(ctx, Entry))
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	entry = |row|
		Parts.el(
			"li",
			"entry",
			[
				Engine.element("time", [Engine.attr_s("datetime", row.field(|e| e.date))], [Engine.text_s(row.field(|e| Dates.short_date(e.date)))]),
				Parts.el(
					"div",
					"",
					[
						Parts.link_s(row.field(|e| e.title), "title", row.field(|e| e.url)),
						Parts.text_el("span", "kind", row.field(Site.kind_label)),
						Parts.maybe(row.field(|e| !e.description.is_empty()), || Parts.text_el("p", "", row.field(|e| e.description))),
					],
				),
			],
		)

	featured : Signal(ctx, List(Entry)) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	featured = |list|
		Engine.element(
			"ul",
			[Engine.class("featured")],
			[
				Engine.each(
					list,
					|e| e.url,
					|row| Parts.el(
						"li",
						"featured-card",
						[
							Parts.el("p", "kicker", [Engine.text_s(row.field(Model.featured_kicker)), Engine.element("time", [Engine.attr_s("datetime", row.field(|e| e.date))], [Engine.text_s(row.field(|e| Dates.short_date(e.date)))])]),
							Parts.el("h3", "", [Parts.link_s(row.field(|e| e.title), "", row.field(|e| e.url))]),
							Parts.text_el("p", "", row.field(|e| Text.clip(e.description, 220))),
						],
					),
				),
			],
		)

	project_cards : Signal(ctx, List(Model.Project)) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	project_cards = |list|
		Engine.element(
			"ul",
			[Engine.class("projects")],
			[
				Engine.each(
					list,
					|p| p.entry.url,
					|row| {
						p = row.item()
						e = p.map(|x| x.entry)
						Parts.el(
							"li",
							"project-card",
							[
								Parts.el("h3", "", [Parts.link_s(e.map(|x| x.title), "", e.map(|x| x.url)), Pages.badge(e)]),
								Parts.text_el("p", "", e.map(|x| x.tagline)),
								Parts.maybe(p.map(|x| !x.latest.url.is_empty()), || Parts.el("p", "latest", [Engine.text("Latest: "), Parts.link_s(p.map(|x| x.latest.title), "", p.map(|x| x.latest.url))])),
							],
						)
					},
				),
			],
		)

	tag_cloud : Signal(ctx, List(Model.Tag)) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	tag_cloud = |list|
		Engine.element(
			"ul",
			[Engine.class("tag-cloud")],
			[Engine.each(list, |t| t.tag, |row| Parts.el("li", "", [Parts.link_s(row.field(|t| t.tag), "", row.field(|t| t.url)), Parts.text_el("span", "count", row.field(|t| t.count))]))],
		)

	commits : Signal(ctx, List(Model.Commit)) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	commits = |list|
		Engine.element(
			"ol",
			[Engine.class("commits")],
			[
				Engine.each(
					list,
					|c| c.hash,
					|row| Parts.el(
						"li",
						"",
						[
							Parts.text_el("time", "", row.field(|c| c.date)),
							Engine.text(" "),
							Engine.element("a", [Engine.attr_s("href", row.field(|c| c.url))], [Engine.text_s(row.field(|c| c.subject))]),
						],
					),
				),
			],
		)

	kicker : Signal(ctx, Entry) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	kicker = |e| Parts.el("p", "kicker", [Parts.link_s(e.map(|x| Site.section_title(x.section)), "", e.map(|x| Site.section_url(x.section)))])

	tag_links : Signal(ctx, List(Str)) -> Elem(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	tag_links = |tags|
		Parts.maybe(
			tags.map(|t| !t.is_empty()),
			|| Engine.element(
				"p",
				[Engine.class("tags")],
				[Engine.each(tags, |t| t, |row| Engine.element("span", [], [Parts.link_s(row.key().map(|t| "#${t}"), "", row.key().map(|t| "/tags/${t}/")), Engine.text(" ")]))],
			),
		)
}

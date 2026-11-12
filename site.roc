app [site] { pf: platform "../folio/platform/main.roc", blu: "packages/blu/main.roc" }

# blu.cx: what I'm writing, then what I'm building, then who I am.
#
# Content lives in Markdown files (Quill publishes them):
#   _posts/articles|blog|journal/YYYY-MM-DD-slug.md   writing
#   _posts/quotes/YYYY-MM-DD-who.md                   quotes (source, link)
#   _projects/slug.md                                 projects (tagline, url, repo, order)
#   _pages/slug.md                                    about, books, talks, …
# Front matter this site reads: title, description, date, tags, status,
# type (article, post, fragment, quote), series, project, featured, and for
# projects tagline, url, repo, status, order.
#
# Every page is written here as HTML, so it reads without JavaScript and
# shares well. The roc-signals app under signals/ then draws the same pages
# in the browser from data/site.json, which this program also writes, and
# moves between them without loading another page. What the pages ask of
# the documents is in packages/blu/, which both programs use.

import pf.Folio
import pf.Html
import blu.Data
import blu.Dates
import blu.Site exposing [Entry]
import blu.Text

site_url = Site.site_url
site_name = Site.site_name

site : Folio.Input -> List(Folio.Page)
site = |input| {
	data = Site.data(input.today, input.docs.keep_if(|d| visible(d, input.today)).map(entry), input.commits.take_first(50))
	writing = data.writing
	quotes = data.quotes
	projects = data.projects
	pages = data.pages
	# The app's files change with each commit; this keeps browsers from mixing builds.
	build = match input.commits.first() {
		Ok(c) => Str.from_utf8_lossy(c.hash.to_utf8().take_first(12))
		Err(_) => input.today
	}
	shell = |s| page_shell(s, build)
	List.join(
		[
			[{ path: "index.html", body: shell(home(data)) }],
			writing.keep_if(|i| i.section != "journal").map(|i| { path: "${strip_slashes(i.url)}/index.html", body: shell(post_page(i, data)) }),
			# A journal entry lives on its day's page; its own old address points there.
			writing.keep_if(|i| i.section == "journal").map(|i| { path: "posts/journal/${i.stem}/index.html", body: redirect(i.url) }),
			Site.days(writing).map(|d| { path: "${strip_slashes(Site.day_url(d))}/index.html", body: shell(day_page(d, writing)) }),
			quotes.map(|q| { path: "${strip_slashes(q.url)}/index.html", body: shell(quote_page(q)) }),
			projects.map(|p| { path: "${strip_slashes(p.url)}/index.html", body: shell(project_page(p, writing)) }),
			pages.map(|p| { path: "${strip_slashes(p.url)}/index.html", body: shell(plain_page(p)) }),
			[
				{ path: "writing/index.html", body: shell(writing_index(writing)) },
				{ path: "posts/index.html", body: shell(writing_index(writing)) },
				{ path: "posts/articles/index.html", body: shell(section_index("articles", writing)) },
				{ path: "posts/blog/index.html", body: shell(section_index("blog", writing)) },
				{ path: "posts/journal/index.html", body: shell(journal_index(writing)) },
				{ path: "quotes/index.html", body: shell(quotes_index(quotes)) },
				{ path: "projects/index.html", body: shell(projects_index(projects, writing)) },
				{ path: "tags/index.html", body: shell(tags_index(writing)) },
				{ path: "changelog/index.html", body: shell(changelog(data.commits)) },
				{ path: "404.html", body: shell(not_found) },
				{ path: "rss.xml", body: feed("", writing) },
				{ path: "sitemap.xml", body: sitemap(List.join([writing.keep_if(|i| i.section != "journal"), quotes, projects, pages])) },
				{ path: "data/site.json", body: Data.encode(data) },
			],
			Site.writing_sections.map(|s| { path: "posts/${s}/rss.xml", body: feed(s, writing.keep_if(|i| i.section == s)) }),
			Site.tags_of(writing).map(|t| { path: "tags/${t}/index.html", body: shell(tag_page(t, writing)) }),
			Site.months(writing).map(|m| { path: "${strip_slashes(Site.month_url(m))}/index.html", body: shell(month_page(m, writing)) }),
			Site.legacy_months.map(|l| { path: "${l.path}/index.html", body: shell(month_page(l.month, writing)) }),
			Site.legacy_redirects.map(|r| { path: "${r.from}/index.html", body: redirect(r.to) }),
		],
	)
}

# ---------------------------------------------------------------------------
# Reading the documents

visible : Folio.Doc, Str -> Bool
visible = |doc, today| {
	status = Folio.field(doc, "status")
	in_place = doc.dir.starts_with("_posts/") or doc.dir == "_pages" or doc.dir == "_projects"
	in_place
	and doc.dir != "_posts/snippets"
	and doc.stem != "index"
	and status != "draft"
	and status != "private"
	and (doc.date.is_empty() or Dates.date_num(doc.date) <= Dates.date_num(today))
}

entry : Folio.Doc -> Entry
entry = |doc| {
	section =
		if doc.dir == "_pages" {
			"page"
		} else if doc.dir == "_projects" {
			"project"
		} else {
			doc.dir.drop_prefix("_posts/")
		}
	given = Folio.field(doc, "type")
	kind =
		if !given.is_empty() {
			given
		} else {
			match section {
				"articles" => "article"
				"journal" => "fragment"
				"quotes" => "quote"
				"page" => "page"
				"project" => "project"
				_ => "post"
			}
		}
	id = doc.stem.drop_prefix("${doc.date}-")
	url =
		match section {
			"page" => "/${doc.slug}/"
			"project" => "/projects/${doc.slug}/"
			"journal" => "${Site.day_url(doc.date)}#${id}"
			_ => "/posts/${section}/${doc.stem}/"
		}
	# Journal entries are plain: no titles, only their day and time.
	written = if section == "journal" { "" } else { Folio.field(doc, "title") }
	title =
		if !written.is_empty() {
			written
		} else if kind == "quote" {
			Folio.field(doc, "source")
		} else {
			Dates.long_date(doc.date)
		}
	described = Folio.field(doc, "description")
	description = if described.is_empty() { Folio.field(doc, "tagline") } else { described }
	{
		section,
		kind,
		url,
		title,
		titled: !written.is_empty(),
		description: if description.is_empty() { Text.clip(doc.excerpt, 200) } else { description },
		described: !described.is_empty(),
		tags: Folio.words_of(doc, "tags").map(Str.with_ascii_lowercased),
		stem: doc.stem,
		slug: doc.slug,
		date: doc.date,
		time: Folio.field(doc, "time"),
		updated: doc.updated,
		words: doc.words,
		excerpt: doc.excerpt,
		html: doc.html,
		toc: doc.toc,
		series: Folio.field(doc, "series"),
		project: Folio.field(doc, "project"),
		featured: Folio.field(doc, "featured") == "true",
		source: Folio.field(doc, "source"),
		link: Folio.field(doc, "link"),
		tagline: Folio.field(doc, "tagline"),
		visit: Folio.field(doc, "url"),
		repo: Folio.field(doc, "repo"),
		status: Folio.field(doc, "status"),
		order: U64.from_str(Folio.field(doc, "order")) ?? 99,
	}
}

# Journal entries under a heading for each day, newest first.
day_groups : List(Entry) -> Str
day_groups = |entries|
	Str.join_with(
		Site.days(entries).map(
			|d|
				Html.el(
					"section",
					[cls("day")],
					[
						Html.el("h3", [], [Html.link(Site.day_url(d), Dates.long_date(d))]),
						Str.join_with(entries.keep_if(|i| i.date == d).map(fragment_full), ""),
					],
				),
		),
		"",
	)

# ---------------------------------------------------------------------------
# Pages

home : Site.Data -> Shell
home = |data| {
	writing = data.writing
	pieces = Site.pieces(writing)
	fragments = Site.fragments(writing)
	lead =
		match pieces.first() {
			Ok(first) =>
				Html.el(
					"article",
					[cls("lead")],
					[
						kicker(first),
						Html.el("h2", [], [Html.link(first.url, first.title)]),
						Html.el("p", [], [Html.text(first.description)]),
						Html.el("a", [cls("more"), Html.a("href", first.url)], ["Read ", dagger]),
					],
				)

			Err(_) => ""
		}
	latest = pieces.drop_first(1).take_first(7)
	chosen = Site.featured(writing)
	quote =
		match data.quotes.first() {
			Ok(q) => Html.el("section", [cls("home-quote")], [quote_block(q, False)])
			Err(_) => ""
		}
	body = Str.join_with(
		[
			Html.el(
				"header",
				[cls("masthead")],
				[
					Html.el("a", [Html.a("href", "/"), cls("crest")], [crest]),
					Html.el("h1", [cls("blackletter")], [site_name]),
					Html.el("p", [cls("greek"), Html.a("lang", "grc")], [Site.greek_name]),
					Html.el("p", [cls("tagline")], ["Writing on software, history and philosophy; building ", Html.link("/projects/kai/", "Kai"), " and ", Html.link("/projects/lyceum/", "Lyceum"), "."]),
					nav("home"),
				],
			),
			if chosen.is_empty() {
				""
			} else {
				Html.el("section", [cls("home-featured")], [section_head("Featured", "/writing/", "All writing"), featured_list(chosen)])
			},
			Html.el(
				"section",
				[cls("home-writing")],
				[
					section_head("Latest", "/writing/", "All writing"),
					lead,
					Html.el("ul", [cls("entries")], latest.map(entry_item)),
				],
			),
			if fragments.is_empty() {
				""
			} else {
				Html.el(
					"section",
					[cls("home-journal")],
					[
						section_head("Journal", "/posts/journal/", "The whole journal"),
						Html.el("ul", [cls("fragments")], fragments.take_first(3).map(fragment_teaser)),
					],
				)
			},
			Html.el(
				"section",
				[cls("home-building")],
				[
					section_head("Building", "/projects/", "All projects"),
					Html.el("ul", [cls("projects")], data.projects.map(|p| project_card(p, writing))),
				],
			),
			quote,
			Html.el(
				"section",
				[cls("home-about")],
				[
					section_head("About", "/about/", "More about me"),
					Html.el(
						"p",
						[],
						[
							"I'm a software engineer, mostly in Bitcoin: Lightning payments at ",
							Html.link("https://voltage.cloud", "Voltage"),
							" and privacy at ",
							Html.link("https://payjoin.org", "Payjoin"),
							". I'm learning Ancient Greek, and read history and philosophy.",
						],
					),
					Html.el("p", [cls("also")], [Str.join_with(Site.also_links.map(|l| Html.link(l.href, l.label)), " · ")]),
				],
			),
			footer,
		],
		"",
	)
	{ title: site_name, description: Site.site_description, url: "/", kind: "website", published: "", body, wide: True }
}

post_page : Entry, Site.Data -> Shell
post_page = |i, data| {
	writing = data.writing
	in_series = Site.in_series(writing, i)
	project = data.projects.find_first(|p| Site.about_project(i, p))
	toc =
		if i.toc.len() >= 4 and i.kind != "fragment" {
			Html.el(
				"details",
				[cls("toc")],
				[
					Html.el("summary", [], ["Contents"]),
					Html.el(
						"ol",
						[],
						i.toc.map(
							|h| Html.el("li", [cls("toc-${U64.to_str(h.level)}")], [Html.link("#${h.id}", h.text)]),
						),
					),
				],
			)
		} else {
			""
		}
	series_box =
		if in_series.len() > 1 {
			Html.el(
				"aside",
				[cls("series")],
				[
					Html.el("p", [cls("kicker")], ["Series: ${Html.text(Site.series_name(i.series, in_series))}"]),
					Html.el(
						"ol",
						[],
						in_series.map(
							|w|
								if w.url == i.url {
									Html.el("li", [cls("here")], [Html.text(w.title)])
								} else {
									Html.el("li", [], [Html.link(w.url, w.title)])
								},
						),
					),
				],
			)
		} else {
			""
		}
	project_note =
		match project {
			Ok(p) =>
				Html.el(
					"aside",
					[cls("project-note")],
					["Part of ", Html.link(p.url, p.title), ": ", Html.text(p.tagline)],
				)

			Err(_) => ""
		}
	body = Str.join_with(
		[
			top_bar(i.section),
			Html.el(
				"article",
				[cls("piece ${i.kind}")],
				[
					Html.el(
						"header",
						[],
						[
							kicker(i),
							if i.titled or i.kind != "fragment" { Html.el("h1", [], [Html.text(i.title)]) } else { "" },
							meta_line(i),
							if !i.described or i.kind == "fragment" {
								""
							} else {
								Html.el("p", [cls("standfirst")], [Html.text(i.description)])
							},
						],
					),
					series_box,
					toc,
					Html.el("div", [cls("markdown")], [i.html]),
					Html.el("footer", [], [project_note, tag_links(i.tags), neighbours(i, writing)]),
				],
			),
			footer,
		],
		"",
	)
	{ title: "${i.title} · ${site_name}", description: i.description, url: i.url, kind: "article", published: i.date, body, wide: False }
}

# Older and newer pieces of the same section.
neighbours : Entry, List(Entry) -> Str
neighbours = |i, writing| {
	around = Site.neighbours(writing, i)
	link_to = |r, label, c|
		match r {
			Ok(w) => Html.el("a", [cls(c), Html.a("href", w.url)], [Html.el("span", [cls("kicker")], [label]), Html.text(w.title)])
			Err(_) => Html.el("span", [cls(c)], [])
		}
	Html.el("nav", [cls("neighbours")], [link_to(around.older, "Older", "older"), link_to(around.newer, "Newer", "newer")])
}

quote_page : Entry -> Shell
quote_page = |q| {
	body = Str.join_with([top_bar("quotes"), Html.el("article", [cls("piece quote")], [quote_block(q, True)]), footer], "")
	{ title: "${q.title} · ${site_name}", description: Text.clip(q.excerpt, 200), url: q.url, kind: "article", published: q.date, body, wide: False }
}

quote_block : Entry, Bool -> Str
quote_block = |q, dated| {
	cite = if q.link.is_empty() { Html.text(q.source) } else { Html.link(q.link, q.source) }
	Html.el(
		"figure",
		[cls("quotation")],
		[
			Html.el("blockquote", [], [q.html]),
			Html.el(
				"figcaption",
				[],
				[
					"— ",
					cite,
					if dated { Html.el("span", [cls("when")], [" · ", Html.link(q.url, Dates.long_date(q.date))]) } else { "" },
				],
			),
		],
	)
}

project_page : Entry, List(Entry) -> Shell
project_page = |p, writing| {
	posts = writing.keep_if(|w| Site.about_project(w, p))
	links = Str.join_with([link_if("Visit", p.visit), link_if("Source", p.repo)].drop_if(Str.is_empty), " · ")
	body = Str.join_with(
		[
			top_bar("project"),
			Html.el(
				"article",
				[cls("piece project")],
				[
					Html.el(
						"header",
						[],
						[
							Html.el("p", [cls("kicker")], [Html.link("/projects/", "Projects"), status_badge(p)]),
							Html.el("h1", [], [Html.text(p.title)]),
							Html.el("p", [cls("standfirst")], [Html.text(p.tagline)]),
							if links.is_empty() { "" } else { Html.el("p", [cls("links")], [links]) },
						],
					),
					Html.el("div", [cls("markdown")], [p.html]),
					if posts.is_empty() {
						""
					} else {
						Html.el("section", [cls("related")], [Html.el("h2", [], ["Writing about ${Html.text(p.title)}"]), Html.el("ul", [cls("entries")], posts.map(entry_item))])
					},
				],
			),
			footer,
		],
		"",
	)
	{ title: "${p.title} · ${site_name}", description: p.description, url: p.url, kind: "website", published: "", body, wide: False }
}

link_if : Str, Str -> Str
link_if = |label, href| if href.is_empty() { "" } else { Html.link(href, label) }

status_badge : Entry -> Str
status_badge = |p| if p.status.is_empty() { "" } else { Html.el("span", [cls("badge")], [Html.text(p.status)]) }

plain_page : Entry -> Shell
plain_page = |p| {
	body = Str.join_with(
		[
			top_bar("page"),
			Html.el(
				"article",
				[cls("piece page")],
				[
					Html.el("header", [], [Html.el("h1", [], [Html.text(p.title)])]),
					Html.el("div", [cls("markdown")], [p.html]),
				],
			),
			footer,
		],
		"",
	)
	{ title: "${p.title} · ${site_name}", description: p.description, url: p.url, kind: "website", published: "", body, wide: False }
}

writing_index : List(Entry) -> Shell
writing_index = |writing| {
	listing = Site.years(writing).map(
		|y|
			Html.el(
				"section",
				[cls("year")],
				[Html.el("h2", [], [y]), Html.el("ul", [cls("entries")], Site.in_year(writing, y).map(entry_item))],
			),
	)
	chosen = Site.featured(writing)
	index_page(
		"writing",
		"Writing",
		Site.writing_intro,
		[
			if chosen.is_empty() { "" } else { Html.el("section", [cls("featured-block")], [Html.el("h2", [], ["Featured"]), featured_list(chosen)]) },
			Html.el("p", [cls("sections")], [Str.join_with(Site.section_links.map(|l| Html.link(l.href, l.label)), " · ")]),
			Str.join_with(listing, ""),
		],
		"/writing/",
	)
}

section_index : Str, List(Entry) -> Shell
section_index = |section, writing|
	index_page(
		section,
		Site.section_title(section),
		Site.section_intro(section),
		[Html.el("ul", [cls("entries")], writing.keep_if(|i| i.section == section).map(entry_item)), feed_link("/posts/${section}/rss.xml")],
		"/posts/${section}/",
	)

journal_index : List(Entry) -> Shell
journal_index = |writing| {
	stream = Site.months(writing).map(
		|m|
			Html.el(
				"section",
				[cls("month")],
				[
					Html.el("h2", [], [Html.link(Site.month_url(m), Dates.month_name(m))]),
					day_groups(Site.in_month(writing, m)),
				],
			),
	)
	index_page("journal", "Journal", "Fragments: thoughts, ideas and notes, as they come.", [Str.join_with(stream, ""), feed_link("/posts/journal/rss.xml")], "/posts/journal/")
}

month_page : Str, List(Entry) -> Shell
month_page = |m, writing|
	index_page(
		"journal",
		Dates.month_name(m),
		"The journal for ${Dates.month_name(m)}.",
		[day_groups(Site.in_month(writing, m)), Html.el("p", [cls("more")], [Html.link("/posts/journal/", "The whole journal")])],
		Site.month_url(m),
	)

day_page : Str, List(Entry) -> Shell
day_page = |d, writing| {
	m = Dates.month_of(d)
	index_page(
		"journal",
		Dates.long_date(d),
		"The journal for ${Dates.long_date(d)}, newest first.",
		[
			Str.join_with(Site.on_day(writing, d).map(fragment_full), ""),
			Html.el(
				"p",
				[cls("more")],
				[Html.link(Site.month_url(m), Dates.month_name(m)), " · ", Html.link("/posts/journal/", "The whole journal")],
			),
		],
		Site.day_url(d),
	)
}

quotes_index : List(Entry) -> Shell
quotes_index = |quotes|
	index_page(
		"quotes",
		"Quotes",
		"Quotes I find interesting, each with the book, link or other source I read it in.",
		[Html.el("div", [cls("quotes")], quotes.map(|q| quote_block(q, True)))],
		"/quotes/",
	)

projects_index : List(Entry), List(Entry) -> Shell
projects_index = |projects, writing|
	index_page(
		"project",
		"Projects",
		"What I'm building.",
		[Html.el("ul", [cls("projects")], projects.map(|p| project_card(p, writing))), Html.el("p", [cls("more")], [Html.link("/archive/", "Older projects and experiments")])],
		"/projects/",
	)

tags_index : List(Entry) -> Shell
tags_index = |writing|
	index_page(
		"writing",
		"Tags",
		"",
		[
			Html.el(
				"ul",
				[cls("tag-cloud")],
				Site.tags_of(writing).map(
					|t| Html.el("li", [], [Html.link("/tags/${t}/", t), Html.el("span", [cls("count")], [U64.to_str(Site.tagged(writing, t).len())])]),
				),
			),
		],
		"/tags/",
	)

tag_page : Str, List(Entry) -> Shell
tag_page = |t, writing|
	index_page("writing", "Tagged ${t}", "", [Html.el("ul", [cls("entries")], Site.tagged(writing, t).map(entry_item)), Html.el("p", [cls("more")], [Html.link("/tags/", "All tags")])], "/tags/${t}/")

changelog : List(Site.Commit) -> Shell
changelog = |commits|
	index_page(
		"page",
		"Changelog",
		"The site's latest changes, from its git history.",
		[
			Html.el(
				"ol",
				[cls("commits")],
				commits.map(
					|c|
						Html.el(
							"li",
							[],
							[
								Html.el("time", [], [Dates.long_date(c.date)]),
								" ",
								Html.el("a", [Html.a("href", "https://github.com/thebrandonlucas/blu/commit/${c.hash}")], [Html.text(c.subject)]),
							],
						),
				),
			),
		],
		"/changelog/",
	)

not_found : Shell
not_found =
	index_page("page", "Not found", "There's nothing at this address. It may have moved; try the writing below.", [Html.el("p", [cls("more")], [Html.link("/writing/", "All writing")])], "/404.html")

index_page : Str, Str, Str, List(Str), Str -> Shell
index_page = |section, title, intro, content, url| {
	body = Str.join_with(
		[
			top_bar(section),
			Html.el(
				"main",
				[cls("index")],
				[
					Html.el("header", [], [Html.el("h1", [], [Html.text(title)]), if intro.is_empty() { "" } else { Html.el("p", [cls("standfirst")], [Html.text(intro)]) }]),
					Str.join_with(content, ""),
				],
			),
			footer,
		],
		"",
	)
	{ title: "${title} · ${site_name}", description: if intro.is_empty() { Site.site_description } else { intro }, url, kind: "website", published: "", body, wide: False }
}

# ---------------------------------------------------------------------------
# Pieces of pages

entry_item : Entry -> Str
entry_item = |i|
	Html.el(
		"li",
		[cls("entry")],
		[
			Html.el("time", [Html.a("datetime", i.date)], [Dates.short_date(i.date)]),
			Html.el(
				"div",
				[],
				[
					Html.el("a", [cls("title"), Html.a("href", i.url)], [Html.text(i.title)]),
					Html.el("span", [cls("kind")], [Site.kind_label(i)]),
					if i.description.is_empty() { "" } else { Html.el("p", [], [Html.text(i.description)]) },
				],
			),
		],
	)

fragment_teaser : Entry -> Str
fragment_teaser = |i|
	Html.el(
		"li",
		[],
		[
			Html.el("a", [cls("date"), Html.a("href", i.url)], [Dates.long_date(i.date)]),
			Html.el("p", [], [Html.text(Text.clip(i.excerpt, 240))]),
		],
	)

# One journal entry: when it went out (its link), the project it's about, and
# what it says. The day is the heading around it.
fragment_full : Entry -> Str
fragment_full = |i|
	Html.el(
		"article",
		[cls("fragment"), Html.a("id", Site.entry_id(i))],
		[
			Html.el(
				"header",
				[],
				[
					Html.el("a", [cls("date"), Html.a("href", i.url), Html.a("title", "Link to this entry")], [if i.time.is_empty() { "¶" } else { i.time }]),
					if i.project.is_empty() { "" } else { Html.el("a", [cls("entry-project"), Html.a("href", "/projects/${i.project}/")], [i.project]) },
				],
			),
			Html.el("div", [cls("markdown")], [i.html]),
		],
	)

project_card : Entry, List(Entry) -> Str
project_card = |p, writing| {
	latest =
		match writing.find_first(|w| Site.about_project(w, p)) {
			Ok(w) => Html.el("p", [cls("latest")], ["Latest: ", Html.link(w.url, w.title)])
			Err(_) => ""
		}
	Html.el(
		"li",
		[cls("project-card")],
		[
			Html.el("h3", [], [Html.link(p.url, p.title), status_badge(p)]),
			Html.el("p", [], [Html.text(p.tagline)]),
			latest,
		],
	)
}

kicker : Entry -> Str
kicker = |i| Html.el("p", [cls("kicker")], [Html.link(Site.section_url(i.section), Site.section_title(i.section))])

meta_line : Entry -> Str
meta_line = |i| {
	parts = [
		Html.el("time", [Html.a("datetime", i.date)], [Dates.long_date(i.date)]),
		Site.reading_time(i),
		Site.updated_note(i),
	]
	Html.el("p", [cls("meta")], [Str.join_with(parts.drop_if(Str.is_empty), " · ")])
}

tag_links : List(Str) -> Str
tag_links = |tags|
	if tags.is_empty() {
		""
	} else {
		Html.el("p", [cls("tags")], [Str.join_with(tags.map(|t| Html.link("/tags/${t}/", "#${t}")), " ")])
	}

section_head : Str, Str, Str -> Str
section_head = |title, href, label|
	Html.el("div", [cls("section-head")], [Html.el("h2", [], [title]), Html.el("a", [Html.a("href", href)], [label, " →"])])

feed_link : Str -> Str
feed_link = |href| Html.el("p", [cls("feed")], [Html.link(href, "RSS feed")])

nav : Str -> Str
nav = |here| {
	area = Site.nav_area(here)
	Html.el(
		"nav",
		[cls("site-nav"), Html.a("aria-label", "Site")],
		Site.nav_links.map(
			|l|
				if l.area == area {
					Html.el("a", [Html.a("href", l.href), Html.a("aria-current", "page")], [l.label])
				} else {
					Html.link(l.href, l.label)
				},
		),
	)
}

top_bar : Str -> Str
top_bar = |section|
	Html.el(
		"header",
		[cls("top-bar")],
		[
			Html.el("a", [cls("home-link"), Html.a("href", "/")], [Html.el("span", [cls("crest-small")], [crest]), Html.el("span", [cls("blackletter")], [site_name])]),
			nav(section),
		],
	)

footer : Str
footer =
	Html.el(
		"footer",
		[cls("site-footer")],
		[
			Html.el("a", [cls("crest-small"), Html.a("href", "/"), Html.a("aria-label", "Home")], [crest]),
			Html.el("p", [], [Str.join_with(Site.footer_links.map(|l| Html.link(l.href, l.label)), " · ")]),
			Html.el("p", [cls("copyright")], ["© ", Html.el("span", [Html.a("data-current-year", "")], ["2026"]), " ${site_name}"]),
		],
	)

crest : Str
crest = Html.void("img", [Html.a("src", "/images/favicon.webp"), Html.a("alt", ""), Html.a("width", "59"), Html.a("height", "80")])

dagger : Str
dagger = Html.el("span", [cls("dagger"), Html.a("aria-hidden", "true")], ["†"])

cls : Str -> { name : Str, value : Str }
cls = |c| Html.a("class", c)

# ---------------------------------------------------------------------------
# The document around every page

Shell : {
	title : Str,
	description : Str,
	url : Str,
	kind : Str,
	published : Str,
	body : Str,
	wide : Bool,
}

# The page as HTML, in #static, and the element the app mounts into, #app.
# site.js mounts the app (`kai run build-signals` builds it into _resources/app/),
# which draws the same page and takes #static away once it has.
page_shell : Shell, Str -> Str
page_shell = |s, build| {
	canonical = "${site_url}${s.url}"
	meta = |property, content| Html.void("meta", [Html.a("property", property), Html.a("content", content)])
	named = |name, content| Html.void("meta", [Html.a("name", name), Html.a("content", content)])
	page_title = if s.url == "/" { site_name } else { s.title }
	share_title = if s.url == "/" { site_name } else { s.title.drop_suffix(" · ${site_name}") }
	published =
		if s.published.is_empty() {
			""
		} else {
			meta("article:published_time", s.published)
		}
	head = Str.join_with(
		[
			Html.void("meta", [Html.a("charset", "utf-8")]),
			named("viewport", "width=device-width, initial-scale=1"),
			Html.el("title", [], [Html.text(page_title)]),
			named("description", s.description),
			Html.void("link", [Html.a("rel", "canonical"), Html.a("href", canonical)]),
			meta("og:title", share_title),
			meta("og:description", s.description),
			meta("og:type", s.kind),
			meta("og:url", canonical),
			meta("og:image", "${site_url}/images/social-card.png"),
			meta("og:site_name", site_name),
			published,
			named("twitter:card", "summary_large_image"),
			named("twitter:site", "@${Site.x_handle}"),
			named("twitter:creator", "@${Site.x_handle}"),
			named("twitter:title", share_title),
			named("twitter:description", s.description),
			named("twitter:image", "${site_url}/images/social-card.png"),
			Html.void("link", [Html.a("rel", "alternate"), Html.a("type", "application/rss+xml"), Html.a("title", site_name), Html.a("href", "/rss.xml")]),
			Html.void("link", [Html.a("rel", "icon"), Html.a("href", "/favicon.ico")]),
			Html.void("link", [Html.a("rel", "preload"), Html.a("href", "/fonts/EBGaramond-Regular.woff2"), Html.a("as", "font"), Html.a("type", "font/woff2"), Html.a("crossorigin", "")]),
			Html.void("link", [Html.a("rel", "preload"), Html.a("href", "/fonts/UnifrakturMaguntia-Regular.woff2"), Html.a("as", "font"), Html.a("type", "font/woff2"), Html.a("crossorigin", "")]),
			Html.void("link", [Html.a("rel", "stylesheet"), Html.a("href", "/style.css?v=${build}")]),
			Html.void("link", [Html.a("rel", "stylesheet"), Html.a("href", "/highlight/tokyo-night-dark.min.css")]),
			Html.el("script", [Html.a("type", "application/ld+json")], [structured_data(s, canonical, share_title)]),
			Html.el("script", [Html.a("defer", ""), Html.a("src", "/highlight/highlight.min.js")], []),
			Html.el("script", [Html.a("defer", ""), Html.a("src", "/site.js?v=${build}")], []),
		],
		"\n",
	)
	width = if s.wide { "wide" } else { "narrow" }
	mount = Html.el("div", [Html.a("id", "app"), Html.a("data-wasm", "/app/app.wasm?v=${build}"), Html.a("data-runtime", "/app/runtime.mjs?v=${build}")], [])
	"<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n${head}\n</head>\n<body>\n<div id=\"static\" class=\"page ${width}\">\n${s.body}\n</div>\n${mount}\n</body>\n</html>\n"
}

structured_data : Shell, Str, Str -> Str
structured_data = |s, canonical, title| {
	person = "{\"@type\":\"Person\",\"@id\":\"${site_url}/#person\",\"name\":\"${site_name}\",\"url\":\"${site_url}\",\"sameAs\":[\"https://github.com/thebrandonlucas\",\"https://x.com/${Site.x_handle}\"]}"
	if s.published.is_empty() {
		"{\"@context\":\"https://schema.org\",\"@graph\":[{\"@type\":\"WebSite\",\"@id\":\"${site_url}/#website\",\"url\":\"${site_url}\",\"name\":\"${site_name}\",\"publisher\":{\"@id\":\"${site_url}/#person\"}},${person}]}"
	} else {
		"{\"@context\":\"https://schema.org\",\"@type\":\"BlogPosting\",\"headline\":${Data.string(title)},\"description\":${Data.string(s.description)},\"datePublished\":\"${s.published}\",\"url\":\"${canonical}\",\"author\":${person}}"
	}
}

# ---------------------------------------------------------------------------
# Feeds

feed : Str, List(Entry) -> Str
feed = |section, items| {
	title = if section.is_empty() { site_name } else { "${site_name}: ${Site.section_title(section)}" }
	link = if section.is_empty() { "${site_url}/writing/" } else { "${site_url}/posts/${section}/" }
	self_url = if section.is_empty() { "${site_url}/rss.xml" } else { "${site_url}/posts/${section}/rss.xml" }
	entries = items.take_first(30).map(
		|i|
			Str.join_with(
				[
					"<item>",
					"<title>${Html.text(i.title)}</title>",
					"<link>${site_url}${i.url}</link>",
					"<guid isPermaLink=\"true\">${site_url}${i.url}</guid>",
					"<pubDate>${Dates.rfc822(i.date)}</pubDate>",
					"<description>${Html.text(i.description)}</description>",
					"<content:encoded><![CDATA[${i.html.replace_each("]]>", "]]]]><![CDATA[>")}]]></content:encoded>",
					"</item>",
				],
				"",
			),
	)
	Str.join_with(
		[
			"<?xml version=\"1.0\" encoding=\"utf-8\"?>",
			"<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\">",
			"<channel>",
			"<title>${Html.text(title)}</title>",
			"<link>${link}</link>",
			"<description>${Html.text(Site.site_description)}</description>",
			"<language>en</language>",
			"<atom:link href=\"${self_url}\" rel=\"self\" type=\"application/rss+xml\"/>",
			Str.join_with(entries, "\n"),
			"</channel>",
			"</rss>",
			"",
		],
		"\n",
	)
}

sitemap : List(Entry) -> Str
sitemap = |items| {
	fixed = ["/", "/writing/", "/posts/articles/", "/posts/blog/", "/posts/journal/", "/projects/", "/quotes/", "/tags/"]
	urls = List.concat(fixed, items.map(|i| i.url)).map(|u| "<url><loc>${site_url}${u}</loc></url>")
	"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n${Str.join_with(urls, "\n")}\n</urlset>\n"
}

strip_slashes : Str -> Str
strip_slashes = |url| url.drop_prefix("/").drop_suffix("/")

redirect : Str -> Str
redirect = |to|
	Str.join_with(
		[
			"<!DOCTYPE html>",
			"<html lang=\"en\"><head><meta charset=\"utf-8\"><title>Moved</title>",
			"<link rel=\"canonical\" href=\"${site_url}${to}\">",
			"<meta http-equiv=\"refresh\" content=\"0; url=${to}\">",
			"</head><body><p>This page moved to <a href=\"${to}\">${site_url}${to}</a>.</p></body></html>",
			"",
		],
		"\n",
	)

featured_list : List(Entry) -> Str
featured_list = |items|
	Html.el(
		"ul",
		[cls("featured")],
		items.map(
			|i|
				Html.el(
					"li",
					[cls("featured-card")],
					[
						Html.el("p", [cls("kicker")], [Site.kind_label(i), " · ", Html.el("time", [Html.a("datetime", i.date)], [Dates.short_date(i.date)])]),
						Html.el("h3", [], [Html.link(i.url, i.title)]),
						Html.el("p", [], [Html.text(Text.clip(i.description, 220))]),
					],
				),
		),
	)

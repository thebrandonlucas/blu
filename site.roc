app [site] { pf: platform "../folio/platform/main.roc" }

# blu.cx: what I'm writing, then what I'm building, then who I am.
#
# Content lives in Markdown files (Quill publishes them):
#   _posts/articles|blog|journal/YYYY-MM-DD-slug.md   writing
#   _posts/quotes/YYYY-MM-DD-who.md                   quotes (source, link)
#   _projects/slug.md                                 projects (tagline, url, repo, order)
#   _pages/slug.md                                    about, books, talks, …
# Front matter this site reads: title, description, date, tags, status,
# type (article, post, fragment, quote), series, project, and for projects
# tagline, url, repo, status, order.

import pf.Folio
import pf.Html

site_url = "https://blu.cx"
site_name = "Brandon Lucas"
greek_name = "Βράνδων Λουκᾶς"
site_description = "Brandon Lucas writes about software, history and philosophy, and builds Kai and Lyceum."
x_handle = "brandonstlucas"

# The monthly journal pages fragments came from: their old addresses show the month.
legacy_months = [
	{ path: "posts/journal/2025-01-01-jan25", month: "2025-01" },
	{ path: "posts/journal/2025-02-01-feb25", month: "2025-02" },
]

# Pages that moved; their old addresses redirect.
legacy_redirects = [
	{ from: "posts/snippets/2000-01-01-writing-description", to: "/writing/" },
	{ from: "posts/snippets/2000-01-02-quotes", to: "/quotes/" },
	{ from: "posts/snippets/2000-01-03-creations", to: "/projects/" },
	{ from: "posts/snippets/2000-01-04-contributions", to: "/contributions/" },
	{ from: "posts/snippets/2000-01-05-talks", to: "/talks/" },
	{ from: "posts/snippets/2000-01-06-technology-i-like", to: "/technology/" },
	{ from: "posts/snippets/2000-01-07-books", to: "/books/" },
	{ from: "posts/snippets/2000-01-08-work-description", to: "/about/" },
]

writing_sections = ["articles", "blog", "journal"]

## A document as this site sees it.
Item : {
	doc : Folio.Doc,
	## "articles", "blog", "journal", "quotes", "page" or "project".
	section : Str,
	## "article", "post", "fragment", "quote", "page" or "project".
	kind : Str,
	url : Str,
	title : Str,
	## Whether `title` came from the front matter (fragments may have none).
	titled : Bool,
	description : Str,
	tags : List(Str),
}

site : Folio.Input -> List(Folio.Page)
site = |input| {
	items = input.docs.keep_if(|d| visible(d, input.today)).map(item)
	writing = newest(items.keep_if(|i| writing_sections.contains(i.section)))
	quotes = newest(items.keep_if(|i| i.section == "quotes"))
	projects = items.keep_if(|i| i.section == "project").sort_by(|p| order_of(p))
	pages = items.keep_if(|i| i.section == "page")
	List.join(
		[
			[{ path: "index.html", body: home(writing, projects, quotes) }],
			writing.map(|i| { path: "${strip_slashes(i.url)}/index.html", body: post_page(i, writing, projects) }),
			quotes.map(|q| { path: "${strip_slashes(q.url)}/index.html", body: quote_page(q) }),
			projects.map(|p| { path: "${strip_slashes(p.url)}/index.html", body: project_page(p, writing) }),
			pages.map(|p| { path: "${strip_slashes(p.url)}/index.html", body: plain_page(p) }),
			[
				{ path: "writing/index.html", body: writing_index(writing) },
				{ path: "posts/index.html", body: writing_index(writing) },
				{ path: "posts/articles/index.html", body: section_index("articles", writing) },
				{ path: "posts/blog/index.html", body: section_index("blog", writing) },
				{ path: "posts/journal/index.html", body: journal_index(writing) },
				{ path: "quotes/index.html", body: quotes_index(quotes) },
				{ path: "projects/index.html", body: projects_index(projects, writing) },
				{ path: "tags/index.html", body: tags_index(writing) },
				{ path: "changelog/index.html", body: changelog(input.commits) },
				{ path: "404.html", body: not_found },
				{ path: "rss.xml", body: feed("", writing) },
				{ path: "sitemap.xml", body: sitemap(List.join([writing, quotes, projects, pages])) },
			],
			writing_sections.map(|s| { path: "posts/${s}/rss.xml", body: feed(s, writing.keep_if(|i| i.section == s)) }),
			tags_of(writing).map(|t| { path: "tags/${t}/index.html", body: tag_page(t, writing) }),
			months(writing).map(|m| { path: "posts/journal/${m.replace_each("-", "/")}/index.html", body: month_page(m, writing) }),
			legacy_months.map(|l| { path: "${l.path}/index.html", body: month_page(l.month, writing) }),
			legacy_redirects.map(|r| { path: "${r.from}/index.html", body: redirect(r.to) }),
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
	and (doc.date.is_empty() or date_num(doc.date) <= date_num(today))
}

item : Folio.Doc -> Item
item = |doc| {
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
	url =
		match section {
			"page" => "/${doc.slug}/"
			"project" => "/projects/${doc.slug}/"
			_ => "/posts/${section}/${doc.stem}/"
		}
	written = Folio.field(doc, "title")
	title =
		if !written.is_empty() {
			written
		} else if kind == "quote" {
			Folio.field(doc, "source")
		} else {
			long_date(doc.date)
		}
	described = Folio.field(doc, "description")
	description = if described.is_empty() { Folio.field(doc, "tagline") } else { described }
	{
		doc,
		section,
		kind,
		url,
		title,
		titled: !written.is_empty(),
		description: if description.is_empty() { clip(doc.excerpt, 200) } else { description },
		tags: Folio.words_of(doc, "tags").map(Str.with_ascii_lowercased),
	}
}

newest : List(Item) -> List(Item)
newest = |items| items.sort_by_reversed(|i| stamp(i.doc))

order_of : Item -> U64
order_of = |i| U64.from_str(Folio.field(i.doc, "order")) ?? 99

# Posts about a project: `project:` names it, or the post's slug mentions it.
about_project : Item, Item -> Bool
about_project = |post, project| {
	named = Folio.field(post.doc, "project")
	if named.is_empty() {
		post.doc.slug.contains(project.doc.slug)
	} else {
		named == project.doc.slug
	}
}

tags_of : List(Item) -> List(Str)
tags_of = |items|
	items
		.join_map(|i| i.tags)
		.fold([], |seen, t| if seen.contains(t) { seen } else { seen.append(t) })
		.sort_with(compare_str)

# Byte order, which for these ASCII words is alphabetical.
compare_str : Str, Str -> [Before, Same, After]
compare_str = |a, b| {
	x = a.to_utf8()
	y = b.to_utf8()
	var $i = 0
	var $result = Same
	while $result == Same and $i < x.len() and $i < y.len() {
		p = x.get($i) ?? 0
		q = y.get($i) ?? 0
		if p < q {
			$result = Before
		} else if p > q {
			$result = After
		}
		$i = $i + 1
	}
	if $result != Same {
		$result
	} else if x.len() < y.len() {
		Before
	} else if x.len() > y.len() {
		After
	} else {
		Same
	}
}

# "2025-02", for each month a fragment was written in, newest first.
months : List(Item) -> List(Str)
months = |items|
	items
		.keep_if(|i| i.section == "journal")
		.map(|i| month_of(i.doc.date))
		.fold([], |seen, m| if seen.contains(m) { seen } else { seen.append(m) })

month_of : Str -> Str
month_of = |date| {
	parts = date.split_on("-")
	"${parts.get(0) ?? ""}-${parts.get(1) ?? ""}"
}

# ---------------------------------------------------------------------------
# Pages

home : List(Item), List(Item), List(Item) -> Str
home = |writing, projects, quotes| {
	pieces = writing.keep_if(|i| i.kind != "fragment")
	fragments = writing.keep_if(|i| i.kind == "fragment")
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
	chosen = featured(writing)
	quote =
		match quotes.first() {
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
					Html.el("p", [cls("greek"), Html.a("lang", "grc")], [greek_name]),
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
					Html.el("ul", [cls("entries")], latest.map(entry)),
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
					Html.el("ul", [cls("projects")], projects.map(|p| project_card(p, writing))),
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
					Html.el(
						"p",
						[cls("also")],
						[
							Str.join_with(
								[
									Html.link("/about/", "About"),
									Html.link("/quotes/", "Quotes"),
									Html.link("/books/", "Books"),
									Html.link("/talks/", "Talks"),
									Html.link("/contributions/", "Contributions"),
									Html.link("/technology/", "Technology"),
									Html.link("/archive/", "Old projects"),
								],
								" · ",
							),
						],
					),
				],
			),
			footer,
		],
		"",
	)
	shell({ title: site_name, description: site_description, url: "/", kind: "website", published: "", body, wide: True })
}

post_page : Item, List(Item), List(Item) -> Str
post_page = |i, writing, projects| {
	series = Folio.field(i.doc, "series")
	in_series =
		if series.is_empty() {
			[]
		} else {
			writing.keep_if(|w| Folio.field(w.doc, "series") == series).sort_by(|w| stamp(w.doc))
		}
	project = projects.find_first(|p| about_project(i, p))
	same = writing.keep_if(|w| w.section == i.section)
	toc =
		if i.doc.toc.len() >= 4 and i.kind != "fragment" {
			Html.el(
				"details",
				[cls("toc")],
				[
					Html.el("summary", [], ["Contents"]),
					Html.el(
						"ol",
						[],
						i.doc.toc.map(
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
					Html.el("p", [cls("kicker")], ["Series: ${Html.text(series_name(series, in_series))}"]),
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
					["Part of ", Html.link(p.url, p.title), ": ", Html.text(Folio.field(p.doc, "tagline"))],
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
							if Folio.field(i.doc, "description").is_empty() or i.kind == "fragment" {
								""
							} else {
								Html.el("p", [cls("standfirst")], [Html.text(i.description)])
							},
						],
					),
					series_box,
					toc,
					Html.el("div", [cls("markdown")], [i.doc.html]),
					Html.el("footer", [], [project_note, tag_links(i.tags), neighbours(i, same)]),
				],
			),
			footer,
		],
		"",
	)
	shell({ title: "${i.title} · ${site_name}", description: i.description, url: i.url, kind: "article", published: i.doc.date, body, wide: False })
}

series_name : Str, List(Item) -> Str
series_name = |series, items|
	match items.first() {
		Ok(first) =>
			match first.title.split_first("#") {
				Ok({ before, .. }) if !before.trim().is_empty() => before.trim()
				_ => series
			}

		Err(_) => series
	}

# Older and newer pieces of the same section.
neighbours : Item, List(Item) -> Str
neighbours = |i, same| {
	at = index_of(same, i.url)
	newer = if at == 0 { Err(OutOfBounds) } else { same.get(at - 1) }
	older = same.get(at + 1)
	link_to = |r, label, c|
		match r {
			Ok(w) => Html.el("a", [cls(c), Html.a("href", w.url)], [Html.el("span", [cls("kicker")], [label]), Html.text(w.title)])
			Err(_) => Html.el("span", [cls(c)], [])
		}
	Html.el("nav", [cls("neighbours")], [link_to(older, "Older", "older"), link_to(newer, "Newer", "newer")])
}

index_of : List(Item), Str -> U64
index_of = |items, url| {
	var $i = 0
	var $found = 0
	for w in items {
		if w.url == url {
			$found = $i
		}
		$i = $i + 1
	}
	$found
}

quote_page : Item -> Str
quote_page = |q| {
	body = Str.join_with([top_bar("quotes"), Html.el("article", [cls("piece quote")], [quote_block(q, True)]), footer], "")
	shell({ title: "${q.title} · ${site_name}", description: clip(q.doc.excerpt, 200), url: q.url, kind: "article", published: q.doc.date, body, wide: False })
}

quote_block : Item, Bool -> Str
quote_block = |q, dated| {
	source = Folio.field(q.doc, "source")
	link = Folio.field(q.doc, "link")
	cite = if link.is_empty() { Html.text(source) } else { Html.link(link, source) }
	Html.el(
		"figure",
		[cls("quotation")],
		[
			Html.el("blockquote", [], [q.doc.html]),
			Html.el(
				"figcaption",
				[],
				[
					"— ",
					cite,
					if dated { Html.el("span", [cls("when")], [" · ", Html.link(q.url, long_date(q.doc.date))]) } else { "" },
				],
			),
		],
	)
}

project_page : Item, List(Item) -> Str
project_page = |p, writing| {
	posts = writing.keep_if(|w| about_project(w, p))
	links = Str.join_with(
		[
			link_if("Visit", Folio.field(p.doc, "url")),
			link_if("Source", Folio.field(p.doc, "repo")),
		]
			.drop_if(Str.is_empty),
		" · ",
	)
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
							Html.el("p", [cls("standfirst")], [Html.text(Folio.field(p.doc, "tagline"))]),
							if links.is_empty() { "" } else { Html.el("p", [cls("links")], [links]) },
						],
					),
					Html.el("div", [cls("markdown")], [p.doc.html]),
					if posts.is_empty() {
						""
					} else {
						Html.el("section", [cls("related")], [Html.el("h2", [], ["Writing about ${Html.text(p.title)}"]), Html.el("ul", [cls("entries")], posts.map(entry))])
					},
				],
			),
			footer,
		],
		"",
	)
	shell({ title: "${p.title} · ${site_name}", description: p.description, url: p.url, kind: "website", published: "", body, wide: False })
}

link_if : Str, Str -> Str
link_if = |label, href| if href.is_empty() { "" } else { Html.link(href, label) }

status_badge : Item -> Str
status_badge = |p| {
	status = Folio.field(p.doc, "status")
	if status.is_empty() { "" } else { Html.el("span", [cls("badge")], [Html.text(status)]) }
}

plain_page : Item -> Str
plain_page = |p| {
	body = Str.join_with(
		[
			top_bar("page"),
			Html.el(
				"article",
				[cls("piece page")],
				[
					Html.el("header", [], [Html.el("h1", [], [Html.text(p.title)])]),
					Html.el("div", [cls("markdown")], [p.doc.html]),
				],
			),
			footer,
		],
		"",
	)
	shell({ title: "${p.title} · ${site_name}", description: p.description, url: p.url, kind: "website", published: "", body, wide: False })
}

writing_index : List(Item) -> Str
writing_index = |writing| {
	pieces = writing.keep_if(|i| i.kind != "fragment")
	years = pieces
		.map(|i| year_of(i.doc.date))
		.fold([], |seen, y| if seen.contains(y) { seen } else { seen.append(y) })
	listing = years.map(
		|y|
			Html.el(
				"section",
				[cls("year")],
				[Html.el("h2", [], [y]), Html.el("ul", [cls("entries")], pieces.keep_if(|i| year_of(i.doc.date) == y).map(entry))],
			),
	)
	index_page(
		"writing",
		"Writing",
		"Articles are long and considered; the blog is shorter and quicker; the journal is fragments as they come.",
		[
			if featured(writing).is_empty() { "" } else { Html.el("section", [cls("featured-block")], [Html.el("h2", [], ["Featured"]), featured_list(featured(writing))]) },
			Html.el(
				"p",
				[cls("sections")],
				[
					Str.join_with(
						[
							Html.link("/posts/articles/", "Articles"),
							Html.link("/posts/blog/", "Blog"),
							Html.link("/posts/journal/", "Journal"),
							Html.link("/quotes/", "Quotes"),
							Html.link("/tags/", "Tags"),
						],
						" · ",
					),
				],
			),
			Str.join_with(listing, ""),
		],
		"/writing/",
	)
}

section_index : Str, List(Item) -> Str
section_index = |section, writing| {
	items = writing.keep_if(|i| i.section == section)
	intro =
		match section {
			"articles" => "Long, considered pieces."
			_ => "Shorter posts: devlogs, fixes and things I learned."
		}
	index_page(
		section,
		section_title(section),
		intro,
		[Html.el("ul", [cls("entries")], items.map(entry)), feed_link("/posts/${section}/rss.xml")],
		"/posts/${section}/",
	)
}

journal_index : List(Item) -> Str
journal_index = |writing| {
	ms = months(writing)
	stream = ms.map(
		|m|
			Html.el(
				"section",
				[cls("month")],
				[
					Html.el("h2", [], [Html.link("/posts/journal/${m.replace_each("-", "/")}/", month_name(m))]),
					Str.join_with(writing.keep_if(|i| i.section == "journal" and month_of(i.doc.date) == m).map(fragment_full), ""),
				],
			),
	)
	index_page("journal", "Journal", "Fragments: thoughts, ideas and notes, as they come.", [Str.join_with(stream, ""), feed_link("/posts/journal/rss.xml")], "/posts/journal/")
}

month_page : Str, List(Item) -> Str
month_page = |m, writing| {
	fragments = writing.keep_if(|i| i.section == "journal" and month_of(i.doc.date) == m)
	index_page(
		"journal",
		month_name(m),
		"The journal for ${month_name(m)}.",
		[Str.join_with(fragments.map(fragment_full), ""), Html.el("p", [cls("more")], [Html.link("/posts/journal/", "The whole journal")])],
		"/posts/journal/${m.replace_each("-", "/")}/",
	)
}

quotes_index : List(Item) -> Str
quotes_index = |quotes|
	index_page(
		"quotes",
		"Quotes",
		"Quotes I find interesting, each with the book, link or other source I read it in.",
		[Html.el("div", [cls("quotes")], quotes.map(|q| quote_block(q, True)))],
		"/quotes/",
	)

projects_index : List(Item), List(Item) -> Str
projects_index = |projects, writing|
	index_page(
		"project",
		"Projects",
		"What I'm building.",
		[Html.el("ul", [cls("projects")], projects.map(|p| project_card(p, writing))), Html.el("p", [cls("more")], [Html.link("/archive/", "Older projects and experiments")])],
		"/projects/",
	)

tags_index : List(Item) -> Str
tags_index = |writing|
	index_page(
		"writing",
		"Tags",
		"",
		[
			Html.el(
				"ul",
				[cls("tag-cloud")],
				tags_of(writing).map(
					|t| {
						n = writing.keep_if(|i| i.tags.contains(t)).len()
						Html.el("li", [], [Html.link("/tags/${t}/", t), Html.el("span", [cls("count")], [U64.to_str(n)])])
					},
				),
			),
		],
		"/tags/",
	)

tag_page : Str, List(Item) -> Str
tag_page = |t, writing|
	index_page("writing", "Tagged ${t}", "", [Html.el("ul", [cls("entries")], writing.keep_if(|i| i.tags.contains(t)).map(entry)), Html.el("p", [cls("more")], [Html.link("/tags/", "All tags")])], "/tags/${t}/")

changelog : List(Folio.Commit) -> Str
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
								Html.el("time", [], [long_date(c.date)]),
								" ",
								Html.el("a", [Html.a("href", "https://github.com/thebrandonlucas/blu/commit/${c.hash}")], [Html.text(c.subject)]),
							],
						),
				),
			),
		],
		"/changelog/",
	)

not_found : Str
not_found =
	index_page("page", "Not found", "There's nothing at this address. It may have moved; try the writing below.", [Html.el("p", [cls("more")], [Html.link("/writing/", "All writing")])], "/404.html")

index_page : Str, Str, Str, List(Str), Str -> Str
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
	shell({ title: "${title} · ${site_name}", description: if intro.is_empty() { site_description } else { intro }, url, kind: "website", published: "", body, wide: False })
}

# ---------------------------------------------------------------------------
# Pieces of pages

entry : Item -> Str
entry = |i|
	Html.el(
		"li",
		[cls("entry")],
		[
			Html.el("time", [Html.a("datetime", i.doc.date)], [short_date(i.doc.date)]),
			Html.el(
				"div",
				[],
				[
					Html.el("a", [cls("title"), Html.a("href", i.url)], [Html.text(i.title)]),
					Html.el("span", [cls("kind")], [kind_label(i)]),
					if i.description.is_empty() { "" } else { Html.el("p", [], [Html.text(i.description)]) },
				],
			),
		],
	)

fragment_teaser : Item -> Str
fragment_teaser = |i|
	Html.el(
		"li",
		[],
		[
			Html.el("a", [cls("date"), Html.a("href", i.url)], [long_date(i.doc.date)]),
			if i.titled { Html.el("span", [cls("title")], [" · ", Html.text(i.title)]) } else { "" },
			Html.el("p", [], [Html.text(clip(i.doc.excerpt, 240))]),
		],
	)

fragment_full : Item -> Str
fragment_full = |i|
	Html.el(
		"article",
		[cls("fragment"), Html.a("id", i.doc.stem)],
		[
			Html.el(
				"header",
				[],
				[
					Html.el("a", [cls("date"), Html.a("href", i.url)], [long_date(i.doc.date)]),
					if i.titled { Html.el("h3", [], [Html.text(i.title)]) } else { "" },
				],
			),
			Html.el("div", [cls("markdown")], [i.doc.html]),
		],
	)

project_card : Item, List(Item) -> Str
project_card = |p, writing| {
	latest =
		match writing.find_first(|w| about_project(w, p)) {
			Ok(w) => Html.el("p", [cls("latest")], ["Latest: ", Html.link(w.url, w.title)])
			Err(_) => ""
		}
	Html.el(
		"li",
		[cls("project-card")],
		[
			Html.el("h3", [], [Html.link(p.url, p.title), status_badge(p)]),
			Html.el("p", [], [Html.text(Folio.field(p.doc, "tagline"))]),
			latest,
		],
	)
}

kicker : Item -> Str
kicker = |i| Html.el("p", [cls("kicker")], [Html.link(section_url(i.section), section_title(i.section))])

meta_line : Item -> Str
meta_line = |i| {
	minutes = (i.doc.words + 229) // 230
	parts = [
		Html.el("time", [Html.a("datetime", i.doc.date)], [long_date(i.doc.date)]),
		if i.kind == "fragment" or minutes < 2 { "" } else { "${U64.to_str(minutes)} min read" },
		if i.doc.updated.is_empty() or i.doc.updated == i.doc.date or date_num(i.doc.updated) < date_num(i.doc.date) { "" } else { "updated ${long_date(i.doc.updated)}" },
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

kind_label : Item -> Str
kind_label = |i|
	match i.kind {
		"article" => "Article"
		"fragment" => "Journal"
		"quote" => "Quote"
		_ => "Blog"
	}

section_title : Str -> Str
section_title = |s|
	match s {
		"articles" => "Articles"
		"blog" => "Blog"
		"journal" => "Journal"
		"quotes" => "Quotes"
		"project" => "Projects"
		_ => "Writing"
	}

section_url : Str -> Str
section_url = |s|
	match s {
		"articles" => "/posts/articles/"
		"blog" => "/posts/blog/"
		"journal" => "/posts/journal/"
		"quotes" => "/quotes/"
		"project" => "/projects/"
		_ => "/writing/"
	}

nav : Str -> Str
nav = |here| {
	area =
		match here {
			"articles" | "blog" | "writing" => "writing"
			other => other
		}
	link_for = |href, label, key|
		if key == area {
			Html.el("a", [Html.a("href", href), Html.a("aria-current", "page")], [label])
		} else {
			Html.link(href, label)
		}
	Html.el(
		"nav",
		[cls("site-nav"), Html.a("aria-label", "Site")],
		[
			link_for("/writing/", "Writing", "writing"),
			link_for("/posts/journal/", "Journal", "journal"),
			link_for("/projects/", "Projects", "project"),
			link_for("/quotes/", "Quotes", "quotes"),
			link_for("/about/", "About", "page"),
		],
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
			Html.el(
				"p",
				[],
				[
					Str.join_with(
						[
							Html.link("https://github.com/thebrandonlucas", "GitHub"),
							Html.link("https://x.com/${x_handle}", "X"),
							Html.link("/rss.xml", "RSS"),
							Html.link("/changelog/", "Changelog"),
						],
						" · ",
					),
				],
			),
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

shell : Shell -> Str
shell = |s| {
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
			named("twitter:site", "@${x_handle}"),
			named("twitter:creator", "@${x_handle}"),
			named("twitter:title", share_title),
			named("twitter:description", s.description),
			named("twitter:image", "${site_url}/images/social-card.png"),
			Html.void("link", [Html.a("rel", "alternate"), Html.a("type", "application/rss+xml"), Html.a("title", site_name), Html.a("href", "/rss.xml")]),
			Html.void("link", [Html.a("rel", "icon"), Html.a("href", "/favicon.ico")]),
			Html.void("link", [Html.a("rel", "preload"), Html.a("href", "/fonts/EBGaramond-Regular.woff2"), Html.a("as", "font"), Html.a("type", "font/woff2"), Html.a("crossorigin", "")]),
			Html.void("link", [Html.a("rel", "preload"), Html.a("href", "/fonts/UnifrakturMaguntia-Regular.woff2"), Html.a("as", "font"), Html.a("type", "font/woff2"), Html.a("crossorigin", "")]),
			Html.void("link", [Html.a("rel", "stylesheet"), Html.a("href", "/style.css?v=folio-1")]),
			Html.void("link", [Html.a("rel", "stylesheet"), Html.a("href", "/highlight/tokyo-night-dark.min.css")]),
			Html.el("script", [Html.a("type", "application/ld+json")], [structured_data(s, canonical, share_title)]),
			Html.el("script", [Html.a("defer", ""), Html.a("src", "/highlight/highlight.min.js")], []),
			Html.el("script", [Html.a("defer", ""), Html.a("src", "/site.js?v=folio-1")], []),
		],
		"\n",
	)
	width = if s.wide { "wide" } else { "narrow" }
	"<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n${head}\n</head>\n<body class=\"${width}\">\n${s.body}\n</body>\n</html>\n"
}

structured_data : Shell, Str, Str -> Str
structured_data = |s, canonical, title| {
	person = "{\"@type\":\"Person\",\"@id\":\"${site_url}/#person\",\"name\":\"${site_name}\",\"url\":\"${site_url}\",\"sameAs\":[\"https://github.com/thebrandonlucas\",\"https://x.com/${x_handle}\"]}"
	if s.published.is_empty() {
		"{\"@context\":\"https://schema.org\",\"@graph\":[{\"@type\":\"WebSite\",\"@id\":\"${site_url}/#website\",\"url\":\"${site_url}\",\"name\":\"${site_name}\",\"publisher\":{\"@id\":\"${site_url}/#person\"}},${person}]}"
	} else {
		"{\"@context\":\"https://schema.org\",\"@type\":\"BlogPosting\",\"headline\":\"${json(title)}\",\"description\":\"${json(s.description)}\",\"datePublished\":\"${s.published}\",\"url\":\"${canonical}\",\"author\":${person}}"
	}
}

# A JSON string's contents, safe inside a <script> element.
json : Str -> Str
json = |s|
	s
		.replace_each("\\", "\\\\")
		.replace_each("\"", "\\\"")
		.replace_each("\n", " ")
		.replace_each("<", "\\u003c")

# ---------------------------------------------------------------------------
# Feeds

feed : Str, List(Item) -> Str
feed = |section, items| {
	title = if section.is_empty() { site_name } else { "${site_name}: ${section_title(section)}" }
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
					"<pubDate>${rfc822(i.doc.date)}</pubDate>",
					"<description>${Html.text(i.description)}</description>",
					"<content:encoded><![CDATA[${i.doc.html.replace_each("]]>", "]]]]><![CDATA[>")}]]></content:encoded>",
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
			"<description>${Html.text(site_description)}</description>",
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

sitemap : List(Item) -> Str
sitemap = |items| {
	fixed = ["/", "/writing/", "/posts/articles/", "/posts/blog/", "/posts/journal/", "/projects/", "/quotes/", "/tags/"]
	urls = List.concat(fixed, items.map(|i| i.url)).map(|u| "<url><loc>${site_url}${u}</loc></url>")
	"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n${Str.join_with(urls, "\n")}\n</urlset>\n"
}

# ---------------------------------------------------------------------------
# Dates and text

month_names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

date_parts : Str -> { y : Str, m : U64, d : U64 }
date_parts = |date| {
	parts = date.split_on("-")
	{
		y: parts.get(0) ?? "",
		m: U64.from_str(parts.get(1) ?? "") ?? 0,
		d: U64.from_str(parts.get(2) ?? "") ?? 0,
	}
}

# "8 October 2026".
long_date : Str -> Str
long_date = |date| {
	p = date_parts(date)
	if p.m == 0 {
		date
	} else {
		"${U64.to_str(p.d)} ${month_names.get(p.m - 1) ?? ""} ${p.y}"
	}
}

# "8 Oct 2026".
short_date : Str -> Str
short_date = |date| {
	p = date_parts(date)
	if p.m == 0 {
		date
	} else {
		name = month_names.get(p.m - 1) ?? ""
		short = Str.from_utf8_lossy(name.to_utf8().take_first(3))
		"${U64.to_str(p.d)} ${short} ${p.y}"
	}
}

# "2025-02" → "February 2025".
month_name : Str -> Str
month_name = |m| {
	p = date_parts("${m}-01")
	"${month_names.get(p.m - 1) ?? ""} ${p.y}"
}

year_of : Str -> Str
year_of = |date| date_parts(date).y

# RFC 822 for RSS, at noon UTC (the files only have days).
rfc822 : Str -> Str
rfc822 = |date| {
	p = date_parts(date)
	name = month_names.get(p.m - 1) ?? "January"
	day = if p.d < 10 { "0${U64.to_str(p.d)}" } else { U64.to_str(p.d) }
	"${weekday(date)}, ${day} ${Str.from_utf8_lossy(name.to_utf8().take_first(3))} ${p.y} 12:00:00 +0000"
}

# Sakamoto's method.
weekday : Str -> Str
weekday = |date| {
	p = date_parts(date)
	y0 = U64.from_str(p.y) ?? 1970
	y = if p.m < 3 { y0 - 1 } else { y0 }
	t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
	n = (y + y // 4 - y // 100 + y // 400 + (t.get(p.m - 1) ?? 0) + p.d) % 7
	["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].get(n) ?? "Sun"
}

# A document's date and `time:` (HH:MM, which Quill sets on publishing) as
# 202610131549, so the day's pieces sort by when they went out. No time: the
# start of the day.
stamp : Folio.Doc -> U64
stamp = |doc| date_num(doc.date) * 10000 + (U64.from_str(Folio.field(doc, "time").replace_each(":", "")) ?? 0)

# 2026-10-08 → 20261008, for comparing and sorting.
date_num : Str -> U64
date_num = |date| U64.from_str(date.replace_each("-", "")) ?? 0

strip_slashes : Str -> Str
strip_slashes = |url| url.drop_prefix("/").drop_suffix("/")

# At most about `n` bytes, cut at a word.
clip : Str, U64 -> Str
clip = |text, n|
	if text.count_utf8_bytes() <= n {
		text
	} else {
		words = text.split_on(" ")
		kept = words.fold(
			"",
			|acc, w| if (acc.count_utf8_bytes() + w.count_utf8_bytes()) >= n { acc } else if acc.is_empty() { w } else { "${acc} ${w}" },
		)
		"${kept}…"
	}

expect long_date("2026-10-08") == "8 October 2026"
expect short_date("2025-02-14") == "14 Feb 2025"
expect weekday("2026-10-11") == "Sun"
expect rfc822("2025-02-04") == "Tue, 04 Feb 2025 12:00:00 +0000"
expect month_name("2025-02") == "February 2025"
expect clip("one two three", 8) == "one two…"
expect ["nix", "bitcoin", "nixos"].sort_with(compare_str) == ["bitcoin", "nix", "nixos"]

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

# The pieces marked `featured: true`, newest first.
featured : List(Item) -> List(Item)
featured = |writing| newest(writing.keep_if(|i| Folio.field(i.doc, "featured") == "true"))

featured_list : List(Item) -> Str
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
						Html.el("p", [cls("kicker")], [kind_label(i), " · ", Html.el("time", [Html.a("datetime", i.doc.date)], [short_date(i.doc.date)])]),
						Html.el("h3", [], [Html.link(i.url, i.title)]),
						Html.el("p", [], [Html.text(clip(i.description, 220))]),
					],
				),
		),
	)

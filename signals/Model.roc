import blu.Dates
import blu.Route
import blu.Site exposing [Data, Entry]
import blu.Text

## What each page shows, worked out from the data in plain Roc, so the views
## only draw it. Each function is what site.roc's page of the same name puts
## on it.
Model := [].{

	## The kinds of page, one branch of the app's view each.
	Kind : [Waiting, Home, Post, Day, Month, Quote, Project, Plain, Writing, Section, Journal, Quotes, Projects, Tags, Tag, Changelog, NotFound]

	kinds : List(Kind)
	kinds = [Waiting, Home, Post, Day, Month, Quote, Project, Plain, Writing, Section, Journal, Quotes, Projects, Tags, Tag, Changelog, NotFound]

	kind : [Waiting, Showing(Route.Page)] -> Kind
	kind = |shown|
		match shown {
			Waiting => Waiting
			Showing(page) =>
				match page {
					Home => Home
					Post(_) => Post
					Day(_) => Day
					Month(_) => Month
					Quote(_) => Quote
					Project(_) => Project
					Plain(_) => Plain
					Writing => Writing
					Section(_) => Section
					Journal => Journal
					Quotes => Quotes
					Projects => Projects
					Tags => Tags
					Tag(_) => Tag
					Changelog => Changelog
					NotFound => NotFound
				}
		}

	## The page, or "not found" while there is none.
	page_of : [Waiting, Showing(Route.Page)] -> Route.Page
	page_of = |shown|
		match shown {
			Showing(page) => page
			Waiting => NotFound
		}

	## The entry a page is about, or a blank one.
	entry_of : Route.Page -> Entry
	entry_of = |page|
		match page {
			Post(e) | Quote(e) | Project(e) | Plain(e) => e
			_ => Site.blank
		}

	## The document's title, as site.roc writes it in <title>.
	title : Data, Route.Page -> Str
	title = |data, page| {
		named = |t| "${t} · ${Site.site_name}"
		match page {
			Home => Site.site_name
			Post(e) | Quote(e) | Project(e) | Plain(e) => named(e.title)
			Day(d) => named(Dates.long_date(d))
			Month(m) => named(Dates.month_name(m))
			Writing => named("Writing")
			Section(s) => named(Site.section_title(s))
			Journal => named("Journal")
			Quotes => named("Quotes")
			Projects => named("Projects")
			Tags => named("Tags")
			Tag(t) => named("Tagged ${t}")
			Changelog => named("Changelog")
			NotFound => if data.today.is_empty() { Site.site_name } else { named("Not found") }
		}
	}

	## The navigation's area for a page.
	area : Route.Page -> Str
	area = |page| Site.nav_area(Route.section(page))

	## A link: its address and label.
	Link : { url : Str, title : Str }

	none : Link
	none = { url: "", title: "" }

	link_to : Entry -> Link
	link_to = |e| { url: e.url, title: e.title }

	## A post's page.
	Post : {
		entry : Entry,
		heading : Bool,
		## " · 4 min read · updated 9 October 2026", after the date.
		meta : Str,
		standfirst : Str,
		series : Str,
		in_series : List({ url : Str, title : Str, here : Bool }),
		toc : List({ url : Str, title : Str, level : Str }),
		project : { url : Str, title : Str, tagline : Str },
		older : Link,
		newer : Link,
	}

	post : Data, Entry -> Post
	post = |data, e| {
		series = Site.in_series(data.writing, e)
		around = Site.neighbours(data.writing, e)
		project =
			match data.projects.find_first(|p| Site.about_project(e, p)) {
				Ok(p) => { url: p.url, title: p.title, tagline: p.tagline }
				Err(_) => { url: "", title: "", tagline: "" }
			}
		{
			entry: e,
			heading: e.titled or e.kind != "fragment",
			meta: Str.join_with([Site.reading_time(e), Site.updated_note(e)].drop_if(Str.is_empty).map(|m| " · ${m}"), ""),
			standfirst: if !e.described or e.kind == "fragment" { "" } else { e.description },
			series: if series.len() > 1 { "Series: ${Site.series_name(e.series, series)}" } else { "" },
			in_series: if series.len() > 1 { series.map(|w| { url: w.url, title: w.title, here: w.url == e.url }) } else { [] },
			toc: if e.toc.len() >= 4 and e.kind != "fragment" { e.toc.map(|h| { url: "#${h.id}", title: h.text, level: "toc-${U64.to_str(h.level)}" }) } else { [] },
			project,
			older: around.older.map_ok(link_to) ?? none,
			newer: around.newer.map_ok(link_to) ?? none,
		}
	}

	## A project's page, and its card on the lists of projects.
	Project : { entry : Entry, links : List({ href : Str, label : Str, before : Str }), posts : List(Entry), latest : Link }

	project : Data, Entry -> Project
	project = |data, p| {
		posts = data.writing.keep_if(|w| Site.about_project(w, p))
		{
			entry: p,
			links: [{ href: p.visit, label: "Visit" }, { href: p.repo, label: "Source" }].drop_if(|l| l.href.is_empty()).map_with_index(|l, i| { href: l.href, label: l.label, before: if i == 0 { "" } else { " · " } }),
			posts,
			latest: posts.first().map_ok(link_to) ?? none,
		}
	}

	projects : Data -> List(Project)
	projects = |data| data.projects.map(|p| project(data, p))

	## A journal entry, under its day.
	Fragment : { entry : Entry, id : Str, when : Str, project : Str }

	fragment : Entry -> Fragment
	fragment = |e| { entry: e, id: Site.entry_id(e), when: if e.time.is_empty() { "¶" } else { e.time }, project: e.project }

	Day : { date : Str, url : Str, title : Str, fragments : List(Fragment) }

	## The journal entries under a heading for each day, newest first.
	days : List(Entry) -> List(Day)
	days = |entries| Site.days(entries).map(|d| { date: d, url: Site.day_url(d), title: Dates.long_date(d), fragments: entries.keep_if(|e| e.date == d).map(fragment) })

	Month : { month : Str, url : Str, title : Str, days : List(Day) }

	months : List(Entry) -> List(Month)
	months = |writing| Site.months(writing).map(|m| { month: m, url: Site.month_url(m), title: Dates.month_name(m), days: days(Site.in_month(writing, m)) })

	## The writing page's pieces, a list for each year.
	Year : { year : Str, entries : List(Entry) }

	years : List(Entry) -> List(Year)
	years = |writing| Site.years(writing).map(|y| { year: y, entries: Site.in_year(writing, y) })

	Tag : { tag : Str, url : Str, count : Str }

	tags : List(Entry) -> List(Tag)
	tags = |writing| Site.tags_of(writing).map(|t| { tag: t, url: "/tags/${t}/", count: U64.to_str(Site.tagged(writing, t).len()) })

	## An index page's heading and text.
	Index : { title : Str, intro : Str }

	index : Route.Page -> Index
	index = |page|
		match page {
			Writing => { title: "Writing", intro: Site.writing_intro }
			Section(s) => { title: Site.section_title(s), intro: Site.section_intro(s) }
			Journal => { title: "Journal", intro: "Fragments: thoughts, ideas and notes, as they come." }
			Month(m) => { title: Dates.month_name(m), intro: "The journal for ${Dates.month_name(m)}." }
			Day(d) => { title: Dates.long_date(d), intro: "The journal for ${Dates.long_date(d)}, newest first." }
			Quotes => { title: "Quotes", intro: "Quotes I find interesting, each with the book, link or other source I read it in." }
			Projects => { title: "Projects", intro: "What I'm building." }
			Tags => { title: "Tags", intro: "" }
			Tag(t) => { title: "Tagged ${t}", intro: "" }
			Changelog => { title: "Changelog", intro: "The site's latest changes, from its git history." }
			_ => { title: "Not found", intro: "There's nothing at this address. It may have moved; try the writing below." }
		}

	## The entries an index page lists.
	listed : Data, Route.Page -> List(Entry)
	listed = |data, page|
		match page {
			Section(s) => data.writing.keep_if(|e| e.section == s)
			Tag(t) => Site.tagged(data.writing, t)
			_ => []
		}

	## The journal entries a day or month page shows.
	journal_days : Data, Route.Page -> List(Day)
	journal_days = |data, page|
		match page {
			Day(d) => days(Site.on_day(data.writing, d))
			Month(m) => days(Site.in_month(data.writing, m))
			_ => []
		}

	## A quote: its text, who said it, where, and its own page.
	Quote : { entry : Entry, source : Str, link : Str, date : Str }

	quote : Entry -> Quote
	quote = |q| { entry: q, source: q.source, link: q.link, date: Dates.long_date(q.date) }

	## The home page.
	Home : {
		featured : List(Entry),
		lead : Entry,
		has_lead : Bool,
		latest : List(Entry),
		fragments : List({ url : Str, date : Str, excerpt : Str }),
		projects : List(Project),
		quote : Quote,
		has_quote : Bool,
	}

	home : Data -> Home
	home = |data| {
		pieces = Site.pieces(data.writing)
		first_quote = data.quotes.first()
		{
			featured: Site.featured(data.writing),
			lead: pieces.first() ?? Site.blank,
			has_lead: !pieces.is_empty(),
			latest: pieces.drop_first(1).take_first(7),
			fragments: Site.fragments(data.writing).take_first(3).map(|e| { url: e.url, date: Dates.long_date(e.date), excerpt: Text.clip(e.excerpt, 240) }),
			projects: projects(data),
			quote: quote(first_quote ?? Site.blank),
			has_quote: first_quote.is_ok(),
		}
	}

	## A featured piece's card.
	featured_kicker : Entry -> Str
	featured_kicker = |e| "${Site.kind_label(e)} · "

	## A commit on the changelog.
	Commit : { hash : Str, date : Str, subject : Str, url : Str }

	commits : Data -> List(Commit)
	commits = |data| data.commits.map(|c| { hash: c.hash, date: Dates.long_date(c.date), subject: c.subject, url: "https://github.com/thebrandonlucas/blu/commit/${c.hash}" })
}

## A post in a series lists the series and marks itself.
expect {
	one = { ..Site.blank, url: "/posts/blog/1/", title: "Kai devlog #1", series: "kai-devlog", date: "2026-01-01", titled: Bool.True }
	two = { ..Site.blank, url: "/posts/blog/2/", title: "Kai devlog #2", series: "kai-devlog", date: "2026-01-02", titled: Bool.True }
	data = { today: "2026-02-01", writing: [two, one], quotes: [], projects: [], pages: [], commits: [] }
	shown = Model.post(data, two)
	shown.series == "Series: Kai devlog" and shown.in_series.map(|s| s.here) == [Bool.False, Bool.True] and shown.older.url == "/posts/blog/1/" and shown.newer.url == ""
}

## A page's title is what site.roc puts in <title>.
expect {
	data = { today: "2026-02-01", writing: [], quotes: [], projects: [], pages: [], commits: [] }
	Model.title(data, Home) == "Brandon Lucas" and Model.title(data, Tag("nix")) == "Tagged nix · Brandon Lucas" and Model.title(data, Day("2026-01-02")) == "2 January 2026 · Brandon Lucas"
}

## Fragments group by month, then day, newest first.
expect {
	a = { ..Site.blank, url: "/posts/journal/2026/01/02/#10-00", section: "journal", kind: "fragment", date: "2026-01-02", stem: "2026-01-02-10-00", time: "10:00" }
	b = { ..Site.blank, url: "/posts/journal/2026/01/01/#09-00", section: "journal", kind: "fragment", date: "2026-01-01", stem: "2026-01-01-09-00" }
	shown = Model.months([a, b])
	shown.map(|m| m.days.map(|d| d.date)) == [["2026-01-02", "2026-01-01"]] and shown.map(|m| m.days.map(|d| d.fragments.map(|f| f.when))) == [[["10:00"], ["¶"]]]
}

## A project's links are separated only between them.
expect {
	source_only = Model.project({ today: "", writing: [], quotes: [], projects: [], pages: [], commits: [] }, { ..Site.blank, repo: "https://github.com/x/y" })
	both = Model.project({ today: "", writing: [], quotes: [], projects: [], pages: [], commits: [] }, { ..Site.blank, visit: "https://x", repo: "https://github.com/x/y" })
	source_only.links.map(|l| l.before) == [""] and both.links.map(|l| l.before) == ["", " · "]
}

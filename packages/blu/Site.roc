import Dates
import Text

## The site's documents once read: who the site is, each published document
## as an `Entry`, and the questions the pages ask of them (what is newest,
## featured, in a series, about a project, on a day).
Site := [].{
	site_url = "https://blu.cx"
	site_name = "Brandon Lucas"
	greek_name = "Βράνδων Λουκᾶς"
	site_description = "Brandon Lucas writes about software, history and philosophy, and builds Kai and Lyceum."
	x_handle = "brandonstlucas"

	writing_sections = ["articles", "blog", "journal"]

	## The monthly journal pages fragments came from: their old addresses show the month.
	legacy_months = [
		{ path: "posts/journal/2025-01-01-jan25", month: "2025-01" },
		{ path: "posts/journal/2025-02-01-feb25", month: "2025-02" },
	]

	## Pages that moved; their old addresses redirect.
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

	## A published document as the pages see it.
	Entry : {
		## "articles", "blog", "journal", "quotes", "page" or "project".
		section : Str,
		## "article", "post", "fragment", "quote", "page" or "project".
		kind : Str,
		url : Str,
		title : Str,
		## Whether `title` came from the front matter (fragments may have none).
		titled : Bool,
		## The front matter's description, or the tagline, or the start of the text.
		description : Str,
		## Whether the front matter gave a description.
		described : Bool,
		tags : List(Str),
		## The file name without ".md", and without its date.
		stem : Str,
		slug : Str,
		date : Str,
		## HH:MM, which Quill sets on publishing, or "".
		time : Str,
		## Date of the last commit touching the file, or "".
		updated : Str,
		words : U64,
		## The first paragraph as plain text.
		excerpt : Str,
		## The body as HTML; headings carry ids.
		html : Str,
		toc : List(Heading),
		series : Str,
		## The project a post names with `project:`, or "".
		project : Str,
		featured : Bool,
		## Quotes: who said it, and where.
		source : Str,
		link : Str,
		## Projects: what it is, where it lives, its source, its status, its place.
		tagline : Str,
		visit : Str,
		repo : Str,
		status : Str,
		order : U64,
	}

	Heading : { level : U64, id : Str, text : Str }

	## A commit of the site's repository.
	Commit : { hash : Str, date : Str, subject : Str }

	## Everything the pages are drawn from, each list in the order it is shown.
	Data : {
		## The build's date, YYYY-MM-DD.
		today : Str,
		## Writing, newest first.
		writing : List(Entry),
		## Quotes, newest first.
		quotes : List(Entry),
		## Projects in their `order`.
		projects : List(Entry),
		pages : List(Entry),
		## The site's latest commits, newest first.
		commits : List(Commit),
	}

	## The data from the documents in any order.
	data : Str, List(Entry), List(Commit) -> Data
	data = |today, entries, commits| {
		today,
		writing: newest(entries.keep_if(|e| writing_sections.contains(e.section))),
		quotes: newest(entries.keep_if(|e| e.section == "quotes")),
		projects: entries.keep_if(|e| e.section == "project").sort_by(|p| p.order),
		pages: entries.keep_if(|e| e.section == "page"),
		commits,
	}

	## A document's date and time as 202610131549, so the day's pieces sort
	## by when they went out. No time: the start of the day.
	stamp : Entry -> U64
	stamp = |e| Dates.date_num(e.date) * 10000 + (U64.from_str(e.time.replace_each(":", "")) ?? 0)

	newest : List(Entry) -> List(Entry)
	newest = |entries| entries.sort_by_reversed(stamp)

	## The writing that isn't a journal fragment.
	pieces : List(Entry) -> List(Entry)
	pieces = |writing| writing.keep_if(|e| e.kind != "fragment")

	fragments : List(Entry) -> List(Entry)
	fragments = |writing| writing.keep_if(|e| e.kind == "fragment")

	journal : List(Entry) -> List(Entry)
	journal = |writing| writing.keep_if(|e| e.section == "journal")

	## The pieces marked `featured: true`, newest first.
	featured : List(Entry) -> List(Entry)
	featured = |writing| writing.keep_if(|e| e.featured)

	## Posts about a project: `project:` names it, or the post's slug mentions it.
	about_project : Entry, Entry -> Bool
	about_project = |post, project|
		if post.project.is_empty() {
			post.slug.contains(project.slug)
		} else {
			post.project == project.slug
		}

	## Every tag the writing uses, alphabetically.
	tags_of : List(Entry) -> List(Str)
	tags_of = |writing| Text.unique(writing.join_map(|e| e.tags)).sort_with(Text.compare)

	tagged : List(Entry), Str -> List(Entry)
	tagged = |writing, tag| writing.keep_if(|e| e.tags.contains(tag))

	## "2025-02", for each month a fragment was written in, newest first.
	months : List(Entry) -> List(Str)
	months = |writing| Text.unique(journal(writing).map(|e| Dates.month_of(e.date)))

	## "2026-10-13", for each day a journal entry was written on, newest first.
	days : List(Entry) -> List(Str)
	days = |writing| Text.unique(journal(writing).map(|e| e.date))

	in_month : List(Entry), Str -> List(Entry)
	in_month = |writing, month| journal(writing).keep_if(|e| Dates.month_of(e.date) == month)

	on_day : List(Entry), Str -> List(Entry)
	on_day = |writing, day| journal(writing).keep_if(|e| e.date == day)

	## The pieces of a year, for each year there are pieces, newest first.
	years : List(Entry) -> List(Str)
	years = |writing| Text.unique(pieces(writing).map(|e| Dates.year_of(e.date)))

	in_year : List(Entry), Str -> List(Entry)
	in_year = |writing, year| pieces(writing).keep_if(|e| Dates.year_of(e.date) == year)

	## A journal day's page: /posts/journal/2026/10/13/.
	day_url : Str -> Str
	day_url = |date| "/posts/journal/${date.replace_each("-", "/")}/"

	## A journal month's page: /posts/journal/2026/10/.
	month_url : Str -> Str
	month_url = |month| "/posts/journal/${month.replace_each("-", "/")}/"

	## A journal entry's anchor on its day's page: its file name past the date.
	## Quill names entries by when they went out (2026-10-13-10-49 is 10-49).
	entry_id : Entry -> Str
	entry_id = |e| e.stem.drop_prefix("${e.date}-")

	## The other pieces of an entry's series, oldest first, or [] when it has none.
	in_series : List(Entry), Entry -> List(Entry)
	in_series = |writing, e|
		if e.series.is_empty() {
			[]
		} else {
			writing.keep_if(|w| w.series == e.series).sort_by(stamp)
		}

	## A series' name: the first piece's title before a "#", or the series' key.
	series_name : Str, List(Entry) -> Str
	series_name = |series, entries|
		match entries.first() {
			Ok(first) =>
				match first.title.split_first("#") {
					Ok({ before, .. }) if !before.trim().is_empty() => before.trim()
					_ => series
				}

			Err(_) => series
		}

	## The older and newer pieces of an entry's section.
	neighbours : List(Entry), Entry -> { older : Try(Entry, [OutOfBounds]), newer : Try(Entry, [OutOfBounds]) }
	neighbours = |writing, e| {
		same = writing.keep_if(|w| w.section == e.section)
		var $i = 0
		var $at = 0
		for w in same {
			if w.url == e.url {
				$at = $i
			}
			$i = $i + 1
		}
		{
			older: same.get($at + 1),
			newer: if $at == 0 { Err(OutOfBounds) } else { same.get($at - 1) },
		}
	}

	## "4 min read", or "" for a fragment or anything shorter than two minutes.
	reading_time : Entry -> Str
	reading_time = |e| {
		minutes = (e.words + 229) // 230
		if e.kind == "fragment" or minutes < 2 { "" } else { "${U64.to_str(minutes)} min read" }
	}

	## "updated 9 October 2026", when the file changed after its date.
	updated_note : Entry -> Str
	updated_note = |e|
		if e.updated.is_empty() or e.updated == e.date or Dates.date_num(e.updated) < Dates.date_num(e.date) {
			""
		} else {
			"updated ${Dates.long_date(e.updated)}"
		}

	kind_label : Entry -> Str
	kind_label = |e|
		match e.kind {
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

	section_intro : Str -> Str
	section_intro = |s|
		match s {
			"articles" => "Long, considered pieces."
			_ => "Shorter posts: devlogs, fixes and things I learned."
		}

	## The links of the site's navigation: where, what, and the area it marks.
	nav_links = [
		{ href: "/writing/", label: "Writing", area: "writing" },
		{ href: "/posts/journal/", label: "Journal", area: "journal" },
		{ href: "/projects/", label: "Projects", area: "project" },
		{ href: "/quotes/", label: "Quotes", area: "quotes" },
		{ href: "/about/", label: "About", area: "page" },
	]

	## The navigation's area a page of a section is in.
	nav_area : Str -> Str
	nav_area = |section|
		match section {
			"articles" | "blog" | "writing" => "writing"
			other => other
		}

	## The home page's links to the smaller pages.
	also_links = [
		{ href: "/about/", label: "About" },
		{ href: "/quotes/", label: "Quotes" },
		{ href: "/books/", label: "Books" },
		{ href: "/talks/", label: "Talks" },
		{ href: "/contributions/", label: "Contributions" },
		{ href: "/technology/", label: "Technology" },
		{ href: "/archive/", label: "Old projects" },
	]

	## The writing page's links to its sections.
	section_links = [
		{ href: "/posts/articles/", label: "Articles" },
		{ href: "/posts/blog/", label: "Blog" },
		{ href: "/posts/journal/", label: "Journal" },
		{ href: "/quotes/", label: "Quotes" },
		{ href: "/tags/", label: "Tags" },
	]

	footer_links = [
		{ href: "https://github.com/thebrandonlucas", label: "GitHub" },
		{ href: "https://x.com/${x_handle}", label: "X" },
		{ href: "/rss.xml", label: "RSS" },
		{ href: "/changelog/", label: "Changelog" },
	]

	writing_intro = "Articles are long and considered; the blog is shorter and quicker; the journal is fragments as they come."

	## An entry with nothing in it, for tests.
	blank : Entry
	blank = {
		section: "blog",
		kind: "post",
		url: "",
		title: "",
		titled: Bool.False,
		description: "",
		described: Bool.False,
		tags: [],
		stem: "",
		slug: "",
		date: "",
		time: "",
		updated: "",
		words: 0,
		excerpt: "",
		html: "",
		toc: [],
		series: "",
		project: "",
		featured: Bool.False,
		source: "",
		link: "",
		tagline: "",
		visit: "",
		repo: "",
		status: "",
		order: 99,
	}

	expect {
		a = { ..blank, url: "/a/", date: "2026-10-01", time: "09:00" }
		b = { ..blank, url: "/b/", date: "2026-10-01", time: "17:30" }
		c = { ..blank, url: "/c/", date: "2026-09-01" }
		newest([c, a, b]).map(|e| e.url) == ["/b/", "/a/", "/c/"]
	}

	expect {
		a = { ..blank, url: "/a/" }
		b = { ..blank, url: "/b/" }
		c = { ..blank, url: "/c/" }
		around = neighbours([a, b, c], b)
		around.older.map_ok(|e| e.url) == Ok("/c/") and around.newer.map_ok(|e| e.url) == Ok("/a/")
	}

	expect {
		kai = { ..blank, section: "project", slug: "kai" }
		about_project({ ..blank, slug: "kai-devlog-1" }, kai) and about_project({ ..blank, slug: "x", project: "kai" }, kai) and !about_project({ ..blank, slug: "kai-x", project: "lyceum" }, kai)
	}

	expect entry_id({ ..blank, stem: "2026-10-13-10-49", date: "2026-10-13" }) == "10-49"
}

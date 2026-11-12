import Site exposing [Data, Entry]

## Which page an address shows. site.roc writes a file for each of these;
## the app draws the page for the address it is at.
Route := [].{
	Page : [
		Home,
		Post(Entry),
		Day(Str),
		Month(Str),
		Quote(Entry),
		Project(Entry),
		Plain(Entry),
		Writing,
		Section(Str),
		Journal,
		Quotes,
		Projects,
		Tags,
		Tag(Str),
		Changelog,
		NotFound,
	]

	## The path of an address: no origin, query or fragment, "index.html"
	## dropped, and ending in "/" unless it names a file.
	path : Str -> Str
	path = |url| {
		after_origin =
			match url.split_first("://") {
				Ok({ after, .. }) =>
					match after.split_first("/") {
						Ok({ after: rest, .. }) => "/${rest}"
						Err(_) => "/"
					}

				Err(_) => url
			}
		no_fragment =
			match after_origin.split_first("#") {
				Ok({ before, .. }) => before
				Err(_) => after_origin
			}
		bare =
			match no_fragment.split_first("?") {
				Ok({ before, .. }) => before
				Err(_) => no_fragment
			}
		trimmed = bare.drop_suffix("index.html")
		if trimmed.is_empty() {
			"/"
		} else if trimmed.ends_with("/") or trimmed.ends_with(".html") or trimmed.ends_with(".xml") {
			trimmed
		} else {
			"${trimmed}/"
		}
	}

	## The page at an address.
	of : Data, Str -> Page
	of = |data, url| {
		at = path(url)
		parts = at.split_on("/").drop_if(Str.is_empty)
		is = |e| e.url == at
		match parts {
			[] => Home
			["writing"] | ["posts"] => Writing
			["posts", "articles"] => Section("articles")
			["posts", "blog"] => Section("blog")
			["posts", "journal"] => Journal
			["posts", "journal", y, m] => month(data, "${y}-${m}")
			["posts", "journal", y, m, d] => day(data, "${y}-${m}-${d}")
			["posts", "journal", legacy] =>
				match Site.legacy_months.find_first(|l| l.path == "posts/journal/${legacy}") {
					Ok(l) => Month(l.month)
					Err(_) => NotFound
				}

			["posts", "quotes", _] =>
				match data.quotes.find_first(is) {
					Ok(q) => Quote(q)
					Err(_) => NotFound
				}

			["posts", _, _] =>
				match data.writing.find_first(|e| e.section != "journal" and is(e)) {
					Ok(e) => Post(e)
					Err(_) => NotFound
				}

			["quotes"] => Quotes
			["projects"] => Projects
			["projects", _] =>
				match data.projects.find_first(is) {
					Ok(p) => Project(p)
					Err(_) => NotFound
				}

			["tags"] => Tags
			["tags", tag] => if Site.tags_of(data.writing).contains(tag) { Tag(tag) } else { NotFound }
			["changelog"] => Changelog
			[_] =>
				match data.pages.find_first(is) {
					Ok(p) => Plain(p)
					Err(_) => NotFound
				}

			_ => NotFound
		}
	}

	month : Data, Str -> Page
	month = |data, m| if Site.months(data.writing).contains(m) { Month(m) } else { NotFound }

	day : Data, Str -> Page
	day = |data, d| if Site.days(data.writing).contains(d) { Day(d) } else { NotFound }

	## The section a page is in, for the navigation.
	section : Page -> Str
	section = |page|
		match page {
			Home => "home"
			Post(e) => e.section
			Day(_) | Month(_) | Journal => "journal"
			Quote(_) | Quotes => "quotes"
			Project(_) | Projects => "project"
			Plain(_) | Changelog | NotFound => "page"
			Section(s) => s
			Writing | Tags | Tag(_) => "writing"
		}

	expect path("https://blu.cx/posts/blog/x/?a=1#top") == "/posts/blog/x/"
	expect path("/about") == "/about/"
	expect path("/index.html") == "/"
	expect path("/404.html") == "/404.html"
	expect path("") == "/"

	expect {
		post = { ..Site.blank, url: "/posts/blog/2026-01-01-x/", section: "blog" }
		quote = { ..Site.blank, url: "/posts/quotes/2026-01-01-y/", section: "quotes", kind: "quote" }
		about = { ..Site.blank, url: "/about/", section: "page", kind: "page" }
		fragment = { ..Site.blank, url: "/posts/journal/2026/01/02/#10-00", section: "journal", kind: "fragment", date: "2026-01-02" }
		data = { today: "2026-02-01", writing: [fragment, post], quotes: [quote], projects: [], pages: [about], commits: [] }
		of(data, "/posts/blog/2026-01-01-x/") == Post(post)
		and of(data, "/posts/quotes/2026-01-01-y/") == Quote(quote)
		and of(data, "/about/") == Plain(about)
		and of(data, "/posts/journal/2026/01/02/") == Day("2026-01-02")
		and of(data, "/posts/journal/2026/01/") == Month("2026-01")
		and of(data, "/posts/journal/2026/03/") == NotFound
		and of(data, "/posts/journal/2025-02-01-feb25/") == Month("2025-02")
		and of(data, "/nowhere/") == NotFound
		and of(data, "/") == Home
	}
}

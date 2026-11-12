import Site exposing [Commit, Entry, Heading]

## The site's data as the JSON the app reads (data/site.json): each record
## an object whose keys are its fields' names, as the app's decoder expects.
Data := [].{
	encode : Site.Data -> Str
	encode = |data|
		object(
			[
				("today", string(data.today)),
				("writing", array(data.writing.map(entry))),
				("quotes", array(data.quotes.map(entry))),
				("projects", array(data.projects.map(entry))),
				("pages", array(data.pages.map(entry))),
				("commits", array(data.commits.map(commit))),
			],
		)

	entry : Entry -> Str
	entry = |e|
		object(
			[
				("section", string(e.section)),
				("kind", string(e.kind)),
				("url", string(e.url)),
				("title", string(e.title)),
				("titled", bool(e.titled)),
				("description", string(e.description)),
				("described", bool(e.described)),
				("tags", array(e.tags.map(string))),
				("stem", string(e.stem)),
				("slug", string(e.slug)),
				("date", string(e.date)),
				("time", string(e.time)),
				("updated", string(e.updated)),
				("words", U64.to_str(e.words)),
				("excerpt", string(e.excerpt)),
				("html", string(e.html)),
				("toc", array(e.toc.map(heading))),
				("series", string(e.series)),
				("project", string(e.project)),
				("featured", bool(e.featured)),
				("source", string(e.source)),
				("link", string(e.link)),
				("tagline", string(e.tagline)),
				("visit", string(e.visit)),
				("repo", string(e.repo)),
				("status", string(e.status)),
				("order", U64.to_str(e.order)),
			],
		)

	heading : Heading -> Str
	heading = |h| object([("level", U64.to_str(h.level)), ("id", string(h.id)), ("text", string(h.text))])

	commit : Commit -> Str
	commit = |c| object([("hash", string(c.hash)), ("date", string(c.date)), ("subject", string(c.subject))])

	object : List((Str, Str)) -> Str
	object = |fields| "{${Str.join_with(fields.map(|(k, v)| "${string(k)}:${v}"), ",")}}"

	array : List(Str) -> Str
	array = |items| "[${Str.join_with(items, ",")}]"

	bool : Bool -> Str
	bool = |b| if b { "true" } else { "false" }

	## A JSON string. "<" is escaped too, so the text is safe inside a <script>.
	string : Str -> Str
	string = |s| {
		escaped = s.to_utf8().fold(
			[],
			|out, byte|
				if byte == '"' {
					out.concat(['\\', '"'])
				} else if byte == '\\' {
					out.concat(['\\', '\\'])
				} else if byte == '\n' {
					out.concat(['\\', 'n'])
				} else if byte == '\r' {
					out.concat(['\\', 'r'])
				} else if byte == '\t' {
					out.concat(['\\', 't'])
				} else if byte == '<' {
					out.concat("\\u003c".to_utf8())
				} else if byte < 0x20 {
					out.concat("\\u00${hex(byte // 16)}${hex(byte % 16)}".to_utf8())
				} else {
					out.append(byte)
				},
		)
		"\"${Str.from_utf8_lossy(escaped)}\""
	}

	hex : U8 -> Str
	hex = |n| Str.from_utf8_lossy(["0123456789abcdef".to_utf8().get(n.to_u64()) ?? '0'])

	expect string("a\"b\\c\n<") == "\"a\\\"b\\\\c\\n\\u003c\""
	expect string("\u(01)") == "\"\\u0001\""
	expect object([("a", array([bool(Bool.True)]))]) == "{\"a\":[true]}"
}

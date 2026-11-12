import pf.Engine exposing [Handler, Signal]
import pf.PortJson
import blu.Route
import blu.Site

## The app's store: where the reader is (`loc`), the navigations links ask
## for (`nav`, which the root pushes to the history), and the site's data
## (`data`), downloaded once from data/site.json.
BluStore := [Blu].{

	## The site's data: not here yet, here, or why it could not be read.
	Loaded : [Loading, Ready(Site.Data), Failed(Str)]

	store = Engine.store(
		BluStore.Blu,
		{
			loc: Engine.cell(""),
			nav: Engine.cell(Engine.outbox({})),
			data: Engine.cell(Loading),
		}.Engine.Cells,
	)

	cells = BluStore.store.cells()

	## Where site.roc writes the data the pages are drawn from.
	data_url : Str
	data_url = "/data/site.json"

	## The store a reader starts with: at the address the page was opened at.
	start : Engine.Boot -> Engine.Store(_, _)
	start = |boot| BluStore.store.with_initial(BluStore.cells.loc, if boot.url.is_empty() { "/" } else { boot.url })

	## The writes of going to `url`: ask for it to be pushed, and move there.
	going : Str -> List(Engine.Write(_))
	going = |url| [BluStore.cells.nav.update(|o| o.post(url)), BluStore.cells.loc.set(url)]

	## A handler that goes to `url`.
	go : Str -> Handler(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	go = |url| Engine.does(BluStore.going(url))

	## A handler that goes to the URL `url` holds when the event fires.
	go_by : Signal(ctx, Str) -> Handler(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	go_by = |url| Engine.handle_by(url, |to, _| BluStore.going(to))

	## A handler that goes to the URL the event carries (a link in a page's text).
	go_to : {} -> Handler(ctx)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	go_to = |{}| Engine.handle(|to| if to.is_empty() { [] } else { BluStore.going(to) })

	## What the answer to the data's request writes.
	loaded : Engine.Result -> List(Engine.Write(_))
	loaded = |res| [BluStore.cells.data.set(BluStore.read(res))]

	read : Engine.Result -> Loaded
	read = |res|
		match Engine.http_text(res) {
			Ok(body) => BluStore.decode(body)
			Err(Status(code)) => Failed("data/site.json answered ${code.to_str()}")
			Err(Network(message)) => Failed(message)
			Err(Timeout) => Failed("data/site.json took too long")
			Err(Refused) => Failed("too many requests")
		}

	decode : Str -> Loaded
	decode = |body| {
		decoded : Try(Site.Data, PortJson.Error)
		decoded = PortJson.decode({ json: body, blobs: [], files: [] })
		match decoded {
			Ok(d) => Ready(d)
			Err(e) => Failed("data/site.json: ${PortJson.describe(e)}")
		}
	}

	## What going back or forward writes.
	popped : Engine.Result -> List(Engine.Write(_))
	popped = |res|
		match res {
			Location(url) => [BluStore.cells.loc.set(url)]
			_ => []
		}

	## The site's data, empty until it is here.
	site : {} -> Signal(ctx, Site.Data)
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	site = |{}|
		BluStore.cells.data.signal().map(
			|d|
				match d {
					Ready(data) => data
					_ => BluStore.empty
				},
		)

	empty : Site.Data
	empty = { today: "", writing: [], quotes: [], projects: [], pages: [], commits: [] }

	## The page the reader is at, once the data is here.
	page : {} -> Signal(ctx, [Waiting, Showing(Route.Page)])
		where [ctx.store : () -> Engine.Reach(ctx, _)]
	page = |{}|
		BluStore.cells.loc.signal().map2(
			BluStore.cells.data.signal(),
			|loc, d|
				match d {
					Ready(data) => Showing(Route.of(data, loc))
					_ => Waiting
				},
		)
}

## Going somewhere moves the reader there and asks for it to be pushed.
expect {
	after = BluStore.store.after(BluStore.going("/about/"))
	after.read(BluStore.cells.loc) == "/about/" and after.read(BluStore.cells.nav).last() == Posted("/about/")
}

## The data decodes from what site.roc writes.
expect {
	json = "{\"today\":\"2026-11-12\",\"writing\":[],\"quotes\":[],\"projects\":[],\"pages\":[{\"section\":\"page\",\"kind\":\"page\",\"url\":\"/about/\",\"title\":\"About\",\"titled\":true,\"description\":\"d\",\"described\":true,\"tags\":[],\"stem\":\"about\",\"slug\":\"about\",\"date\":\"\",\"time\":\"\",\"updated\":\"\",\"words\":120,\"excerpt\":\"\",\"html\":\"<p>Hi</p>\",\"toc\":[{\"level\":2,\"id\":\"a\",\"text\":\"A\"}],\"series\":\"\",\"project\":\"\",\"featured\":false,\"source\":\"\",\"link\":\"\",\"tagline\":\"\",\"visit\":\"\",\"repo\":\"\",\"status\":\"\",\"order\":99}],\"commits\":[{\"hash\":\"abc\",\"date\":\"2026-11-12\",\"subject\":\"x\"}]}"
	match BluStore.decode(json) {
		Ready(d) => d.pages.map(|p| p.title) == ["About"] and d.commits.len() == 1
		_ => Bool.False
	}
}

## A failed request leaves the static page in place and says why.
expect BluStore.read(Network("offline")) == Failed("offline")

## Back and forward move the reader; other results write nothing.
expect BluStore.store.after(BluStore.popped(Location("/quotes/"))).read(BluStore.cells.loc) == "/quotes/"

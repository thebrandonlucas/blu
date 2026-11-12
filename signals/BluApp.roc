import pf.Engine exposing [Elem]
import BluStore
import Model
import Pages

## blu.cx in the browser: the pages site.roc writes, drawn from the same
## data and moved between without loading another page.
##
## The page opens as site.roc's static HTML, in #static. The app mounts
## beside it in #app, downloads data/site.json, draws the page it is at,
## and then a `blu-ready` element (site.js) takes #static away. Until the
## data is here, or if it never arrives, the app draws nothing and the
## static page stays.
##
## The root owns the effects: the data's request, the history (each
## navigation a link asks for is pushed, and back and forward move the
## reader), and the document's title.
BluApp := [].{

	program : Engine.Program
	program = Engine.program_store({ storage_keys: [], max_inflight: 8 }, BluStore.start, |_boot| BluApp.view({}))

	view : {} -> Elem(Engine.StoreRoot(_))
	view = |{}| {
		shown = BluStore.page({})
		at = BluStore.site({}).map2(shown, |data, s| { data, page: Model.page_of(s) })
		Engine.element(
			"div",
			[],
			[
				# Focused after each move, which takes the reader to the top of the new page.
				Engine.element("span", [Engine.class("top"), Engine.attr("tabindex", "-1"), Engine.ref("top")], []),
				Engine.watch(
					Engine.const({}),
					|_| [Http({ method: "GET", url: BluStore.data_url, headers: [("cache-control", "no-cache")], body: "", timeout_ms: 30000 })],
					Engine.react(|_, res| BluStore.loaded(res)),
				),
				Engine.on_post(BluStore.cells.nav.signal(), |url| [Push(url), Focus("top")], Engine.ignore({})),
				Engine.watch(Engine.const({}), |_| [Popstate], Engine.react(|_, res| BluStore.popped(res))),
				Engine.watch(
					at.map2(shown, |a, s| if s == Waiting { "" } else { Model.title(a.data, a.page) }),
					|title| if title.is_empty() { [] } else { [Title(title)] },
					Engine.ignore({}),
				),
				Engine.switch(shown.map(Model.kind), Model.kinds, |kind| Pages.view(kind, at)),
				Engine.when(shown.map(|s| s != Waiting), || Engine.element("blu-ready", [], []), || Engine.text("")),
			],
		)
	}
}

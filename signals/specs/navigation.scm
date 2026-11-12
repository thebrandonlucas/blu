; Links move between pages without loading one: the address, the title and
; the page change, and back and forward return.
(test "links, back and forward move between pages"
  (setup
    (initial-location "/"))
  (steps
    (stub-http "site" :url "/data/site.json" :status 200 :body "{\"today\":\"2026-11-12\",\"writing\":[{\"section\":\"journal\",\"kind\":\"fragment\",\"url\":\"/posts/journal/2026/11/02/#09-30\",\"title\":\"2 November 2026\",\"titled\":false,\"description\":\"\",\"described\":false,\"tags\":[],\"stem\":\"2026-11-02-09-30\",\"slug\":\"09-30\",\"date\":\"2026-11-02\",\"time\":\"09:30\",\"updated\":\"\",\"words\":100,\"excerpt\":\"A fragment.\",\"html\":\"<p>A fragment.</p>\",\"toc\":[],\"series\":\"\",\"project\":\"\",\"featured\":false,\"source\":\"\",\"link\":\"\",\"tagline\":\"\",\"visit\":\"\",\"repo\":\"\",\"status\":\"\",\"order\":99},{\"section\":\"blog\",\"kind\":\"post\",\"url\":\"/posts/blog/2026-11-01-kai-devlog-8/\",\"title\":\"Kai devlog #8\",\"titled\":true,\"description\":\"Lockfiles.\",\"described\":true,\"tags\":[\"nix\"],\"stem\":\"2026-11-01-kai-devlog-8\",\"slug\":\"kai-devlog-8\",\"date\":\"2026-11-01\",\"time\":\"\",\"updated\":\"\",\"words\":100,\"excerpt\":\"Lockfiles.\",\"html\":\"<p>See <a href=\\\"/about/\\\">about</a>.</p>\",\"toc\":[],\"series\":\"kai-devlog\",\"project\":\"\",\"featured\":false,\"source\":\"\",\"link\":\"\",\"tagline\":\"\",\"visit\":\"\",\"repo\":\"\",\"status\":\"\",\"order\":99},{\"section\":\"blog\",\"kind\":\"post\",\"url\":\"/posts/blog/2026-10-01-kai-devlog-7/\",\"title\":\"Kai devlog #7\",\"titled\":true,\"description\":\"Config.\",\"described\":true,\"tags\":[\"nix\"],\"stem\":\"2026-10-01-kai-devlog-7\",\"slug\":\"kai-devlog-7\",\"date\":\"2026-10-01\",\"time\":\"\",\"updated\":\"\",\"words\":100,\"excerpt\":\"Config.\",\"html\":\"<p>Config.</p>\",\"toc\":[],\"series\":\"kai-devlog\",\"project\":\"\",\"featured\":false,\"source\":\"\",\"link\":\"\",\"tagline\":\"\",\"visit\":\"\",\"repo\":\"\",\"status\":\"\",\"order\":99}],\"quotes\":[{\"section\":\"quotes\",\"kind\":\"quote\",\"url\":\"/posts/quotes/2026-08-01-seneca/\",\"title\":\"Seneca\",\"titled\":false,\"description\":\"\",\"described\":false,\"tags\":[],\"stem\":\"2026-08-01-seneca\",\"slug\":\"seneca\",\"date\":\"2026-08-01\",\"time\":\"\",\"updated\":\"\",\"words\":100,\"excerpt\":\"\",\"html\":\"<p>Time.</p>\",\"toc\":[],\"series\":\"\",\"project\":\"\",\"featured\":false,\"source\":\"Seneca\",\"link\":\"\",\"tagline\":\"\",\"visit\":\"\",\"repo\":\"\",\"status\":\"\",\"order\":99}],\"projects\":[{\"section\":\"project\",\"kind\":\"project\",\"url\":\"/projects/kai/\",\"title\":\"Kai\",\"titled\":true,\"description\":\"A CLI.\",\"described\":true,\"tags\":[],\"stem\":\"kai\",\"slug\":\"kai\",\"date\":\"\",\"time\":\"\",\"updated\":\"\",\"words\":100,\"excerpt\":\"\",\"html\":\"<p>Kai.</p>\",\"toc\":[],\"series\":\"\",\"project\":\"\",\"featured\":false,\"source\":\"\",\"link\":\"\",\"tagline\":\"A CLI.\",\"visit\":\"\",\"repo\":\"https://github.com/thebrandonlucas/kai\",\"status\":\"\",\"order\":1}],\"pages\":[{\"section\":\"page\",\"kind\":\"page\",\"url\":\"/about/\",\"title\":\"About\",\"titled\":true,\"description\":\"Who.\",\"described\":true,\"tags\":[],\"stem\":\"about\",\"slug\":\"about\",\"date\":\"\",\"time\":\"\",\"updated\":\"\",\"words\":100,\"excerpt\":\"\",\"html\":\"<p>Me.</p>\",\"toc\":[],\"series\":\"\",\"project\":\"\",\"featured\":false,\"source\":\"\",\"link\":\"\",\"tagline\":\"\",\"visit\":\"\",\"repo\":\"\",\"status\":\"\",\"order\":99}],\"commits\":[{\"hash\":\"abc123\",\"date\":\"2026-11-12\",\"subject\":\"Publish\"}]}")
    (run-effect 1)
    (click (role link :name "Kai devlog #8"))
    (expect-current-location "/posts/blog/2026-11-01-kai-devlog-8/")
    (expect-document-title "Kai devlog #8 · Brandon Lucas")
    (expect-visible (role heading :name "Kai devlog #8"))
    (expect-text (text "Series: Kai devlog") "Series: Kai devlog")
    (click (role link :name "OlderKai devlog #7"))
    (expect-current-location "/posts/blog/2026-10-01-kai-devlog-7/")
    (expect-visible (role heading :name "Kai devlog #7"))
    (click (role link :name "#nix"))
    (expect-current-location "/tags/nix/")
    (expect-visible (role heading :name "Tagged nix"))
    (history-back)
    (expect-current-location "/posts/blog/2026-10-01-kai-devlog-7/")
    (expect-document-title "Kai devlog #7 · Brandon Lucas")
    (history-back)
    (history-back)
    (expect-current-location "/")
    (expect-visible (role heading :name "Brandon Lucas"))
    (history-forward)
    (expect-current-location "/posts/blog/2026-11-01-kai-devlog-8/")))

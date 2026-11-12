; When the data cannot be read, the app draws nothing: the static page stays,
; and its links load pages as they always did.
(test "a failed download leaves the static page alone"
  (setup
    (initial-location "/about/"))
  (steps
    (stub-http "site" :url "/data/site.json" :status 500 :body "")
    (run-effect 1)
    (expect-absent (role heading :name "About"))
    (expect-current-location "/about/")))

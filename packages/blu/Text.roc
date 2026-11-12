Text := [].{
	## At most about `n` bytes, cut at a word.
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

	## Byte order, which for the site's ASCII words is alphabetical.
	compare : Str, Str -> [Before, Same, After]
	compare = |a, b| {
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

	## Each string once, in the order first seen.
	unique : List(Str) -> List(Str)
	unique = |items| items.fold([], |seen, s| if seen.contains(s) { seen } else { seen.append(s) })

	expect clip("one two three", 8) == "one two…"
	expect ["nix", "bitcoin", "nixos"].sort_with(compare) == ["bitcoin", "nix", "nixos"]
	expect unique(["a", "b", "a"]) == ["a", "b"]
}

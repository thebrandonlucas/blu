## Dates as the documents write them: YYYY-MM-DD.
Dates := [].{
	month_names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

	parts : Str -> { y : Str, m : U64, d : U64 }
	parts = |date| {
		pieces = date.split_on("-")
		{
			y: pieces.get(0) ?? "",
			m: U64.from_str(pieces.get(1) ?? "") ?? 0,
			d: U64.from_str(pieces.get(2) ?? "") ?? 0,
		}
	}

	## "8 October 2026".
	long_date : Str -> Str
	long_date = |date| {
		p = parts(date)
		if p.m == 0 {
			date
		} else {
			"${U64.to_str(p.d)} ${month_names.get(p.m - 1) ?? ""} ${p.y}"
		}
	}

	## "8 Oct 2026".
	short_date : Str -> Str
	short_date = |date| {
		p = parts(date)
		if p.m == 0 {
			date
		} else {
			name = month_names.get(p.m - 1) ?? ""
			short = Str.from_utf8_lossy(name.to_utf8().take_first(3))
			"${U64.to_str(p.d)} ${short} ${p.y}"
		}
	}

	## "2025-02" → "February 2025".
	month_name : Str -> Str
	month_name = |m| {
		p = parts("${m}-01")
		"${month_names.get(p.m - 1) ?? ""} ${p.y}"
	}

	## "2026-10-13" → "2026-10".
	month_of : Str -> Str
	month_of = |date| {
		p = date.split_on("-")
		"${p.get(0) ?? ""}-${p.get(1) ?? ""}"
	}

	year_of : Str -> Str
	year_of = |date| parts(date).y

	## RFC 822 for RSS, at noon UTC (the files only have days).
	rfc822 : Str -> Str
	rfc822 = |date| {
		p = parts(date)
		name = month_names.get(p.m - 1) ?? "January"
		day = if p.d < 10 { "0${U64.to_str(p.d)}" } else { U64.to_str(p.d) }
		"${weekday(date)}, ${day} ${Str.from_utf8_lossy(name.to_utf8().take_first(3))} ${p.y} 12:00:00 +0000"
	}

	## Sakamoto's method.
	weekday : Str -> Str
	weekday = |date| {
		p = parts(date)
		y0 = U64.from_str(p.y) ?? 1970
		y = if p.m < 3 { y0 - 1 } else { y0 }
		t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
		n = (y + y // 4 - y // 100 + y // 400 + (t.get(p.m - 1) ?? 0) + p.d) % 7
		["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].get(n) ?? "Sun"
	}

	## 2026-10-08 → 20261008, for comparing and sorting.
	date_num : Str -> U64
	date_num = |date| U64.from_str(date.replace_each("-", "")) ?? 0

	expect long_date("2026-10-08") == "8 October 2026"
	expect short_date("2025-02-14") == "14 Feb 2025"
	expect weekday("2026-10-11") == "Sun"
	expect rfc822("2025-02-04") == "Tue, 04 Feb 2025 12:00:00 +0000"
	expect month_name("2025-02") == "February 2025"
	expect month_of("2026-10-13") == "2026-10"
}

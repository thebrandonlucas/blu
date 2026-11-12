app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.28.0/2yhxoR7cZPSYbyUzPWULFw8AA6QEcdsgFNRmzu7pZbst.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/1.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
}

import pf.Cmd
import pf.Http
import pf.OsStr
import pf.Path
import pf.Stdout
import http.Request

# signals.roc build|verify|specs
#
# build: the app (signals/) as the files site.js loads from /app/: its wasm32
# module (app.wasm) and the roc-signals runtime pinned by URL and SHA-256 in
# signals/runtime.lock.json (runtime.mjs, downloaded when the copy there does
# not match the pin, never edited). Both go to _resources/app/, which is kept
# in git and which folio copies to the site as it is: publishing a post needs
# only folio, and the app is built again only when signals/ or packages/
# change.
#
# verify: builds the module again into .signals/ and fails unless it is the
# one in _resources/app/, so the committed app is the one its source builds.
#
# specs: builds the app's native spec runner (.signals/spec-runner) and runs
# signals/specs/*.scm with it.
#
# Both build with `--specialize=no`. The app draws text and does no heavy
# work, and specializing its view's closures makes the module seven times
# larger and its build twenty times slower (roc-issues
# roc/IMPROVEMENT-010-specialization-code-size); the specs test the lowering
# that ships.

runner = ".signals/spec-runner"

main! = |args| {
	match args.map(OsStr.display) {
		["build"] => build!({})
		["verify"] => verify!({})
		["specs"] => specs!({})
		_ => Err(Usage("Usage: signals.roc build|verify|specs"))
	}
}

build! = |{}| {
	Path.create_all!(Path.unix("_resources/app"))?
	roc!(["build", "--target=wasm32", "--opt=size", "--specialize=no", "signals/main.roc", "--output=_resources/app/app.wasm"])?
	runtime!({})?
	Stdout.line!("built _resources/app/app.wasm and _resources/app/runtime.mjs")
}

verify! = |{}| {
	Path.create_all!(Path.unix(".signals"))?
	roc!(["build", "--target=wasm32", "--opt=size", "--specialize=no", "signals/main.roc", "--output=.signals/app.wasm"])?
	built = sha256(Path.read_bytes!(Path.unix(".signals/app.wasm"))?)
	kept = sha256(Path.read_bytes!(Path.unix("_resources/app/app.wasm"))?)
	if built == kept {
		Stdout.line!("_resources/app/app.wasm is what signals/ builds")
	} else {
		Err(Stale("_resources/app/app.wasm is not what signals/ builds: run kai run build-signals and commit it"))
	}
}

## The pinned runtime.mjs, downloaded unless the copy there already matches the pin.
runtime! = |{}| {
	lock = Path.read_utf8!(Path.unix("signals/runtime.lock.json"))?
	url = field(lock, "url") ? |_| Lock("signals/runtime.lock.json has no url")
	pinned = field(lock, "sha256") ? |_| Lock("signals/runtime.lock.json has no sha256")
	target = Path.unix("_resources/app/runtime.mjs")
	present = if Path.exists!(target)? sha256(Path.read_bytes!(target)?) == pinned else Bool.False
	if present {
		Ok({})
	} else {
		response = Http.send!(Request.from_method(GET).with_uri(url), { max_redirects: 5 })?
		body = response.body()
		digest = sha256(body)
		if response.status() != 200 {
			Err(Fetch("${url} answered ${response.status().to_str()}"))
		} else if digest != pinned {
			Err(Fetch("${url} has SHA-256 ${digest}, but signals/runtime.lock.json pins ${pinned}"))
		} else {
			Path.write_bytes!(target, body)
		}
	}
}

## A string field of the lock's one flat JSON object.
field : Str, Str -> Try(Str, [Missing])
field = |json, name|
	match json.split_first("\"${name}\"") {
		Ok({ after, .. }) =>
			match after.split_first("\"") {
				Ok({ after: value, .. }) =>
					match value.split_first("\"") {
						Ok({ before, .. }) => Ok(before)
						Err(_) => Err(Missing)
					}

				Err(_) => Err(Missing)
			}

		Err(_) => Err(Missing)
	}

specs! = |{}| {
	Path.create_all!(Path.unix(".signals"))?
	roc!(["build", "--target=x64musl", "--opt=size", "--specialize=no", "signals/main.roc", "--output=${runner}"])?
	found = Path.list!(Path.unix("signals/specs"))?
		.map(|path| path.display())
		.keep_if(|path| path.ends_with(".scm"))
	call!(runner, found.sort_with(compare))
}

roc! = |args| call!("roc", args)

# Runs a program with the terminal inherited; a non-zero exit is an error.
call! = |program, args| {
	output = Cmd.new(OsStr.from_str(program)).args(args.map(OsStr.from_str)).inherit_stdio().run!()?
	match output.status {
		Exited(0) => Ok({})
		_ => Err(Failed("${program} ${Str.join_with(args, " ")}: ${Str.inspect(output.status)}"))
	}
}

sha256 = |bytes| Crypto.SHA256.hash(bytes).to_hex()

# Byte order, so the specs run in the same order everywhere.
compare = |a, b| compare_bytes(a.to_utf8(), b.to_utf8(), 0)

compare_bytes = |a, b, at|
	match (a.get(at), b.get(at)) {
		(Err(_), Err(_)) => Same
		(Err(_), Ok(_)) => Before
		(Ok(_), Err(_)) => After
		(Ok(x), Ok(y)) => if x < y Before else if x > y After else compare_bytes(a, b, at + 1)
	}

expect field("{ \"url\": \"https://x/runtime.mjs\", \"sha256\": \"ab\" }", "sha256") == Ok("ab")

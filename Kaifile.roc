# blu.cx's development environment and tasks. `kai shell` has what folio
# and site.roc need, `kai shell signals` what the roc-signals app in
# signals/ needs; `kai run --help` lists the tasks.
#
# folio is a checkout beside this one (../folio), as site.roc's platform
# path expects. It is published on no forge a Nix build can fetch, and a
# source may not lie outside the project, so the site is built by a task
# rather than a sandboxed build.
app [kaifile] {
	pf: platform "https://github.com/thebrandonlucas/kai/releases/download/v0.0.12/G3CQ6Ed3h7vyvV4eDvwH1J8UqBv2wEtkb9jLJhFkU5ny.tar.zst",
	std: "https://github.com/thebrandonlucas/kai/releases/download/v0.0.12/std-6VuNBrdv6tT7ZAVD4bWGBYYwk1KJoXP7gCnFip5VSK11.tar.zst",
}

import std.Std

folio = "../folio/driver/target/release/folio"

kaifile = Std.kaifile([
	Name("blu"),
	Systems(["x86_64-linux", "aarch64-linux"]),
	# The roc-overlay and compiler folio's flake pins, so site.roc links
	# against folio's platform host.
	Overlay("roc", "github:thebrandonlucas/roc-overlay/75e0d3ae5c9a4d99eb14d2b13cac5a0e22fcd89d"),
	Follows("roc", "nixpkgs", "default"),
	Environment(
		"dev",
		[
			Overlays(["roc"]),
			Tools(
				[
					"rocpkgs.nightly-2026-09-26-d6267b4",
					"zig_0_16",
					"cargo",
					"rustc",
					"clippy",
					"rustfmt",
					"git",
					"rsync",
					"openssh",
				],
			),
		],
	),
	# The compiler roc-signals 0.5.0 was built and tested with, for the app.
	Overlay("roc-signals", "github:roc-lang/roc-overlay/d36f07ca9bb332d48386da38fe0d45da5009d5bc"),
	Follows("roc-signals", "nixpkgs", "default"),
	Environment(
		"signals",
		[
			Overlays(["roc-signals"]),
			Tools(["rocpkgs.nightly-2026-11-11-7679cc5", "coreutils"]),
		],
	),
	Shell("default", [Use("dev")]),
	Shell("signals", [Use("signals")]),
	Task(
		"folio",
		[
			Use("dev"),
			Description("Build ../folio: its driver and its platform host"),
			Run(
				[
					"sh",
					"-c",
					\\set -eu
					\\test -d ../folio || { echo "Clone folio beside this checkout, as ../folio." >&2; exit 1; }
					\\cargo build --release --manifest-path ../folio/driver/Cargo.toml
					\\cd ../folio/platform && zig build --release
					,
				],
			),
		],
	),
	Task(
		"build",
		[
			Use("dev"),
			Description("Render the site into _site/ with ../folio"),
			Run(["sh", "-c", "test -x ${folio} || { echo 'No folio driver: kai run folio' >&2; exit 1; }; exec ${folio} build ."]),
		],
	),
	Task("test", [Use("dev"), Description("Run the site's tests (packages/blu/) on folio's compiler"), Run(["roc", "test", "packages/blu/main.roc"])]),
	Task("check", [Use("dev"), Description("Type-check site.roc"), Run(["roc", "check", "site.roc"])]),
	# The app (signals/) on roc-signals 0.5.0, built with the nightly that
	# release was tested with. It shares packages/blu/ with site.roc, so that
	# package builds on both compilers.
	Task("check-signals", [Use("signals"), Description("Type-check the app and its build script"), Run(["sh", "-c", "roc check signals/main.roc && roc check scripts/signals.roc"])]),
	Task("test-signals", [Use("signals"), Description("Run the app's tests and packages/blu/'s on the app's compiler"), Run(["sh", "-c", "roc test packages/blu/main.roc && roc test signals/main.roc"])]),
	Task("specs", [Use("signals"), Description("Run the app's specs (signals/specs/) natively"), Run(["roc", "scripts/signals.roc", "specs"])]),
	Task("build-signals", [Use("signals"), Description("Build the app into _resources/app/ (commit it)"), Run(["roc", "scripts/signals.roc", "build"])]),
	Task("verify-signals", [Use("signals"), Description("Check _resources/app/app.wasm is what signals/ builds"), Run(["roc", "scripts/signals.roc", "verify"])]),
	Task(
		"changelog",
		[
			Use("dev"),
			Description("Write _site/changelog/ from the git history"),
			Run(["bash", "scripts/generate-changelog.sh"]),
		],
	),
	# Puts _site/ live on the server; Quill passes these variables.
	Task(
		"deploy",
		[
			Use("dev"),
			Description("Copy _site/ to the server and switch to it"),
			Run(["bash", "scripts/deploy.sh"]),
			OptionalEnvironmentVariables(["BLU_SSH", "BLU_DEPLOY_HOST", "QUILL_SITE_COMMIT", "SSH_AUTH_SOCK"]),
		],
	),
	Workflow(
		"ci",
		[
			RunTask("check", []),
			RunTask("test", []),
			RunTask("build", []),
			RunTask("check-signals", []),
			RunTask("test-signals", []),
			RunTask("specs", []),
			RunTask("verify-signals", []),
		],
	),
])

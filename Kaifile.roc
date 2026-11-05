# blu.cx's development environment and tasks. `kai shell` has what folio
# and site.roc need; `kai run --help` lists the tasks.
#
# folio is a checkout beside this one (../folio), as site.roc's platform
# path expects. It is published on no forge a Nix build can fetch, and a
# source may not lie outside the project, so the site is built by a task
# rather than a sandboxed build.
app [kaifile] {
	pf: platform "https://github.com/thebrandonlucas/kai/releases/download/v0.0.11/65bk6qdahqxn1mm6LR6Hkyw8dSdoeRZGwjNSuiPfvguP.tar.zst",
	std: "https://github.com/thebrandonlucas/kai/releases/download/v0.0.11/std-6Jw5GxNCFkpnvBbnFmQg4KAVEn5bAfEveSZfDSzTDs42.tar.zst",
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
	Shell("default", [Use("dev")]),
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
	Task("test", [Use("dev"), Description("Run site.roc's tests"), Run(["roc", "test", "site.roc"])]),
	Task("check", [Use("dev"), Description("Type-check site.roc"), Run(["roc", "check", "site.roc"])]),
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
	Workflow("ci", [RunTask("check", []), RunTask("test", []), RunTask("build", [])]),
])

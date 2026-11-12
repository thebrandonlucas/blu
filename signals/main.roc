app [main] {
	pf: platform "https://github.com/lukewilliamboswell/roc-signals/releases/download/0.5.0/2SYUPo9uKFPJDvTyXiwsLEqHvmq7UMgaY4hdgMiSsSEF.tar.zst",
	blu: "../packages/blu/main.roc",
}

import pf.Engine
import BluApp

## blu.cx on roc-signals 0.5.0: `roc build --target=wasm32` gives the
## browser module and `roc build --target=x64musl` its native spec runner
## (see scripts/signals.roc).
main : Engine.Program
main = BluApp.program

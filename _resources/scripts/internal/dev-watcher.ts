// dev-watcher.ts
import { watch } from "fs";
import { relative, resolve } from "path";

let isBuilding = false;
let debounceTimer: NodeJS.Timeout | null = null;
let serverProc: Bun.Subprocess | null = null;

const debounceMs = 500;

// Watch these source directories recursively
const pathsToWatch = [
  "./_layouts",
  "./_pages",
  "./_posts",
  "./_resources",
];

// Explicitly exclude these paths to prevent rebuild loops
const pathsToExclude = ["./_site", "./node_modules"];

async function runBuild() {
  if (isBuilding) {
    console.log("⏳ Build already running – skipping duplicate");
    return;
  }
  isBuilding = true;
  console.clear();
  console.log("🔄 Changes detected – starting build sequence...\n");

  // 1. ElmStatic – generates content into _site
  const elmstaticProc = Bun.spawn(["bunx", "elmstatic", "build"], {
    stdout: "inherit",
    stderr: "inherit",
  });
  const elmstaticCode = await elmstaticProc.exited;
  if (elmstaticCode !== 0) {
    console.log(`\n❌ ElmStatic failed (code ${elmstaticCode})`);
    isBuilding = false;
    return;
  }
  console.log("\n✅ ElmStatic complete");

  // 2. Tailwind CSS – overwrites styles.css in _site
  const tailwindProc = Bun.spawn([
    "bunx",
    "@tailwindcss/cli",
    "-i",
    "./_resources/styles.css",
    "-o",
    "./_site/styles.css",
  ], {
    stdout: "inherit",
    stderr: "inherit",
  });
  const tailwindCode = await tailwindProc.exited;
  if (tailwindCode !== 0) {
    console.log(`\n❌ Tailwind failed (code ${tailwindCode})`);
    isBuilding = false;
    return;
  }
  console.log("\n✅ Tailwind complete");

  // 3. Restart the dev server
  if (serverProc) {
    console.log("🛑 Stopping previous dev server...");
    serverProc.kill("SIGTERM");
    await serverProc.exited; // Wait for clean shutdown
  }

  console.log("🚀 Starting new dev server...");
  serverProc = Bun.spawn([
    "http-server",
    "_site",
    "-p",
    "3000",
    "--cors", // Optional but useful for dev
  ], {
    stdout: "inherit",
    stderr: "inherit",
    detached: true, // Allows it to run independently
  });

  console.log("\n✅ Dev server running at http://localhost:3000");
  console.log("\n🎉 Full build sequence finished!\n");

  isBuilding = false;
}

// Helper: check if a path should be ignored
function shouldIgnore(filePath: string): boolean {
  const absPath = resolve(filePath);
  return pathsToExclude.some((exclude) => {
    const absExclude = resolve(exclude);
    return absPath.startsWith(absExclude + "/") || absPath === absExclude;
  });
}

// Set up watchers
pathsToWatch.forEach((dir) => {
  watch(
    dir,
    { recursive: true },
    (event, filename) => {
      if (!filename) return;
      const fullPath = resolve(dir, filename);
      const relPath = relative(process.cwd(), fullPath);

      if (shouldIgnore(relPath)) {
        // Silently ignore output directories
        return;
      }

      console.log(`Change detected: ${relPath}`);

      if (debounceTimer) clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => runBuild(), debounceMs);
    }
  );
});

console.log("👀 Watching for changes in:");
pathsToWatch.forEach((p) => console.log(`   • ${p}`));
console.log("\nExcluding:", pathsToExclude.join(", "));
console.log("\n");

// Clean up server on exit
process.on("SIGINT", () => {
  console.log("\n\n🛑 Shutting down...");
  if (serverProc) {
    serverProc.kill("SIGTERM");
  }
  process.exit(0);
});
process.on("SIGTERM", () => {
  if (serverProc) serverProc.kill("SIGTERM");
  process.exit(0);
});

// Initial build on startup
await runBuild();

// dev-watcher.ts
import { watch } from "fs";
import { relative, resolve } from "path";

let isBuilding = false;
let debounceTimer: NodeJS.Timeout | null = null;
const debounceMs = 500;

// Watch these source directories recursively
const pathsToWatch = [
  "./",
  // Add more source dirs as needed
];

// Explicitly exclude these paths (and everything inside them)
// Useful for output dirs like _site, dist, build, etc.
const pathsToExclude = [
  "./_site",        // Main culprit for Tailwind/ElmStatic output
  "./node_modules"
  // "./dist",
  // "./build",
];

async function runBuild() {
  if (isBuilding) {
    console.log("⏳ Build already running – skipping duplicate");
    return;
  }
  isBuilding = true;
  console.clear();
  console.log("🔄 Changes detected – starting build sequence...\n");


  // 2. ElmStatic
  const elmstaticProc = Bun.spawn([
    "bunx", "elmstatic", "build"
  ], { stdout: "inherit", stderr: "inherit" });

  const elmstaticCode = await elmstaticProc.exited;
  if (elmstaticCode !== 0) {
    console.log(`\n❌ ElmStatic failed (code ${elmstaticCode})`);
    isBuilding = false;
    return;
  }
  console.log("\n✅ ElmStatic complete");
  //
  // 1. Tailwind CSS
  const tailwindProc = Bun.spawn([
    "bun", "run", "tailwindcss",
    "-i", "./_resources/styles.css",
    "-o", "./_site/output.css",
  ], { stdout: "inherit", stderr: "inherit" });

  const tailwindCode = await tailwindProc.exited;
  if (tailwindCode !== 0) {
    console.log(`\n❌ Tailwind failed (code ${tailwindCode})`);
    isBuilding = false;
    return;
  }
  console.log("\n✅ Tailwind complete");

  // 3. Replace this with your actual third command
  const thirdProc = Bun.spawn([
    "http-server", "_site"
  ], { stdout: "inherit", stderr: "inherit" });

  const thirdCode = await thirdProc.exited;
  if (thirdCode !== 0) {
    console.log(`\n❌ Third step failed (code ${thirdCode})`);
    isBuilding = false;
    return;
  }
  console.log("\n✅ Third step complete");

  console.log("\n🎉 Full build sequence finished!\n");
  isBuilding = false;
}

// Helper: check if a file path should be ignored
function shouldIgnore(filePath: string): boolean {
  const absPath = resolve(filePath);
  return pathsToExclude.some(exclude => {
    const absExclude = resolve(exclude);
    return absPath.startsWith(absExclude + "/") || absPath === absExclude;
  });
}

pathsToWatch.forEach((dir) => {
  watch(dir, { recursive: true }, (event, filename) => {
    if (!filename) return;

    const fullPath = resolve(dir, filename);
    const relPath = relative(process.cwd(), fullPath);

    if (shouldIgnore(relPath)) {
      console.log(`Ignored change (excluded path): ${relPath}`);
      return;
    }

    console.log(`Change: ${relPath}`);
    if (debounceTimer) clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => runBuild(), debounceMs);
  });
});

console.log("👀 Watching for changes...");
console.log("Included paths:", pathsToWatch.join(", "));
console.log("Excluded paths:", pathsToExclude.join(", "));
console.log("\n");

// Initial build on start
await runBuild();

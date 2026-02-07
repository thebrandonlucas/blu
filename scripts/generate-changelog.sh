#!/usr/bin/env bash
# Generate changelog HTML page from git history

OUTPUT_DIR="_site/changelog"
OUTPUT_FILE="$OUTPUT_DIR/index.html"

mkdir -p "$OUTPUT_DIR"

# Generate JSON data for commits
generate_commits_json() {
    echo "["
    first=true
    git log --pretty=format:'%H|%s|%ai|%an' --no-merges | head -50 | while IFS='|' read -r hash subject date author; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi

        # Get diff stats
        stats=$(git show --stat --format='' "$hash" | tail -1 | sed 's/^ *//')

        # Escape JSON strings
        subject_escaped=$(echo "$subject" | sed 's/\\/\\\\/g; s/"/\\"/g')
        stats_escaped=$(echo "$stats" | sed 's/\\/\\\\/g; s/"/\\"/g')

        cat <<COMMIT
    {
      "hash": "$hash",
      "shortHash": "${hash:0:7}",
      "subject": "$subject_escaped",
      "date": "$date",
      "author": "$author",
      "stats": "$stats_escaped"
    }
COMMIT
    done
    echo ""
    echo "]"
}

COMMITS_JSON=$(generate_commits_json)

cat > "$OUTPUT_FILE" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Changelog | Brandon Lucas</title>
    <link href="/styles.css" rel="stylesheet" type="text/css">
    <style>
        .changelog-container { max-width: 800px; margin: 0 auto; padding: 20px; }
        .commit { border: 1px solid #333; border-radius: 4px; margin: 12px 0; padding: 16px; background: #1a1a1a; }
        .commit-header { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; flex-wrap: wrap; }
        .commit-hash { font-family: monospace; color: #7aa2f7; font-size: 14px; }
        .commit-date { color: #888; font-size: 14px; }
        .commit-subject { font-size: 18px; margin: 8px 0; color: #fffff8; }
        .commit-stats { color: #888; font-size: 14px; margin-top: 8px; }
        .commit-link { margin-top: 12px; }
        .commit-link a { color: #7aa2f7; text-decoration: none; font-size: 14px; }
        .commit-link a:hover { text-decoration: underline; }
        h1 { text-align: center; margin-bottom: 32px; }
        .back-link { text-align: center; margin-bottom: 24px; }
    </style>
</head>
<body>
    <main class="flex flex-col gap-8 w-[80%] items-center mx-auto my-20">
        <a href="/"><img src="/images/favicon.webp" alt="Narsil Logo" width="59" height="80"></a>
        <h1 class="text-4xl font-bold">Changelog</h1>
        <p class="text-center text-gray-400">Auto-generated from git commit history</p>
        <div class="changelog-container">
            <div id="commits"></div>
        </div>
    </main>
    <script>
    const commits =
HTMLHEAD

echo "$COMMITS_JSON" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << 'HTMLTAIL'
;
    const container = document.getElementById('commits');
    const repoUrl = 'https://github.com/thebrandonlucas/blu';

    commits.forEach(commit => {
        const div = document.createElement('div');
        div.className = 'commit';
        div.innerHTML = `
            <div class="commit-header">
                <span class="commit-hash">${commit.shortHash}</span>
                <span class="commit-date">${new Date(commit.date).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })}</span>
            </div>
            <div class="commit-subject">${commit.subject}</div>
            ${commit.stats ? `<div class="commit-stats">${commit.stats}</div>` : ''}
            <div class="commit-link">
                <a href="${repoUrl}/commit/${commit.hash}" target="_blank" rel="noopener">View diff on GitHub &rarr;</a>
            </div>
        `;
        container.appendChild(div);
    });
    </script>
</body>
</html>
HTMLTAIL

echo "Generated changelog at $OUTPUT_FILE"

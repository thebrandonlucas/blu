#!/usr/bin/env bash
# Puts the built _site/ live on the VPS that serves blu.cx. Caddy serves
# /var/www/blu-site/current, a link to one of /var/www/blu-site/releases/*:
# _site/ is copied to a new release, then the link is switched in one step,
# so nobody sees a half-copied site. The last five releases stay; to roll
# back, point the link at an older one.
#
#   folio build . && scripts/deploy.sh
#
# Quill runs it after every publish (its QUILL_SITE_DEPLOY), with its own key:
#   BLU_SSH="ssh -i KEY -o UserKnownHostsFile=FILE"  ssh command to use
#   BLU_DEPLOY_HOST=user@host                       (default blu-deploy@216.155.158.213)
#   QUILL_SITE_COMMIT                               names the release (default HEAD)
set -euo pipefail
cd "$(dirname "$0")/.."
host=${BLU_DEPLOY_HOST:-blu-deploy@216.155.158.213}
ssh_cmd=${BLU_SSH:-ssh -o BatchMode=yes}
base=/var/www/blu-site

test -f _site/index.html || { echo "No _site/: build first (folio build .)."; exit 1; }
rev=${QUILL_SITE_COMMIT:-$(git rev-parse HEAD)}
release="$base/releases/release.$(date -u +%Y%m%d%H%M%S).${rev:0:7}"

$ssh_cmd "$host" "mkdir -p '$release'"
rsync -rlz --chmod=D755,F644 -e "$ssh_cmd" _site/ "$host:$release/"
$ssh_cmd "$host" "ln -sfn '$release' '$base/current.new' && mv -T '$base/current.new' '$base/current' &&
  cd '$base/releases' && ls -1dt release.* | tail -n +6 | xargs -r rm -rf"
echo "Live: $release"

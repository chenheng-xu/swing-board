#!/bin/bash
# 把 web/ 推到 GitHub Pages。凭据从 ~/.swing_gh.conf 读取(该文件由你本人创建, 我不经手 token)。
#   ~/.swing_gh.conf 内容(两行):
#     GH_REPO=你的用户名/仓库名
#     GH_TOKEN=你的 Personal Access Token
#   chmod 600 ~/.swing_gh.conf
set -euo pipefail
CONF=~/.swing_gh.conf
[ -f "$CONF" ] || { echo "缺少 $CONF, 跳过推送"; exit 0; }
# shellcheck disable=SC1090
source "$CONF"
: "${GH_REPO:?GH_REPO 未设置}"; : "${GH_TOKEN:?GH_TOKEN 未设置}"

SRC=/home/chenheng/workspace/xch/swing/web
REPO=/home/chenheng/.swing_gh_repo
if [ ! -d "$REPO/.git" ]; then
  rm -rf "$REPO"; mkdir -p "$REPO"; cd "$REPO"
  git init -q -b main
  git config user.email "swing-bot@local"; git config user.name "swing-bot"
fi
cd "$REPO"
rsync -a --delete --exclude .git "$SRC"/ ./
touch .nojekyll
git add -A
if git diff --cached --quiet; then echo "无变化, 跳过"; exit 0; fi
git commit -q -m "选股结果 $(TZ=Asia/Shanghai date '+%F %H:%M') 北京"
git push -q --force "https://x-access-token:${GH_TOKEN}@github.com/${GH_REPO}.git" main
echo "已推送 -> https://$(echo "$GH_REPO" | cut -d/ -f1).github.io/$(echo "$GH_REPO" | cut -d/ -f2)/"

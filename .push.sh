#!/bin/bash
# 把 web/ 推到 GitHub Pages。凭据从 ~/.swing_gh.conf 读取。
# 安全要点: token 通过 GIT_ASKPASS 传给 git, 不出现在 URL 或进程参数里,
#           所以 git 的任何报错都不会把 token 打印出来。
set -uo pipefail
CONF=~/.swing_gh.conf
[ -f "$CONF" ] || { echo "缺少 $CONF, 跳过推送"; exit 0; }
# shellcheck disable=SC1090
source "$CONF"
: "${GH_REPO:?GH_REPO 未设置}"; : "${GH_TOKEN:?GH_TOKEN 未设置}"
export GH_TOKEN

SRC=/home/chenheng/workspace/xch/swing/web
REPO=/home/chenheng/.swing_gh_repo
BRANCH=main

if [ ! -d "$REPO/.git" ]; then
  rm -rf "$REPO"; mkdir -p "$REPO"; cd "$REPO"
  git init -q -b "$BRANCH"
fi
cd "$REPO"
git config user.email "swing-bot@local"
git config user.name "swing-bot"

rsync -a --delete --exclude .git "$SRC"/ ./
touch .nojekyll
git add -A
if git diff --cached --quiet && [ -n "$(git rev-list -n1 --all 2>/dev/null)" ]; then
  echo "内容无变化, 跳过提交"
else
  git commit -q -m "选股结果 $(TZ=Asia/Shanghai date '+%F %H:%M') 北京" || true
fi

# --- token 经 GIT_ASKPASS 传入, 不进 URL ---
ASK=$(mktemp)
cat > "$ASK" <<'EOS'
#!/bin/sh
case "$1" in
  *[Uu]sername*) printf '%s' "x-access-token" ;;
  *[Pp]assword*) printf '%s' "$GH_TOKEN" ;;
esac
EOS
chmod 700 "$ASK"
export GIT_ASKPASS="$ASK" GIT_TERMINAL_PROMPT=0

OUT=$(git push --force "https://github.com/${GH_REPO}.git" "$BRANCH" 2>&1)
RC=$?
rm -f "$ASK"
# 兜底: 万一任何形式的凭据混进输出, 一律打码
echo "$OUT" | sed -E 's#//[^@/]*@#//***@#g; s#github_pat_[A-Za-z0-9_]+#github_pat_***#g; s#ghp_[A-Za-z0-9]+#ghp_***#g'

USER_NAME=${GH_REPO%%/*}; REPO_NAME=${GH_REPO##*/}
if [ $RC -eq 0 ]; then
  echo "已推送 -> https://${USER_NAME}.github.io/${REPO_NAME}/"
else
  echo "!! 推送失败 (git 退出码 $RC)"
fi
exit $RC

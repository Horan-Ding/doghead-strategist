# 独立 data 仓 + AI 定时同步

`GOUTOU_DATA_DIR` 指向 **单独 private Git 仓库** 的根目录（不是 `doghead-strategist` 里的 `./data/`）。

## 一次性搭建

1. GitHub **Private** 仓：`Horan-Ding/goutou-data`（已创建）。
2. 在 `doghead-strategist` 根目录：

```bash
cp .env.example .env
# 按需改 GOUTOU_DATA_DIR 路径
./scripts/ensure-data-repo.sh
```

等价于 clone + `init-local-data.sh`。Horan-Ding 专用 SSH 见 [github-ssh-horan-ding.md](github-ssh-horan-ding.md)；URL 也可用 `git@github.com:Horan-Ding/goutou-data.git`（走本机默认 `github.com` Host）。

首次若要把旧 `./data/` 迁入私有仓，在 clone 后：

```bash
rsync -a --exclude 'conversations/raw' ./data/ "$GOUTOU_DATA_DIR/"
./scripts/sync-data-repo.sh
```

3. `.env` 中保留 **`GOUTOU_DATA_REPO_URL`**，方便换机后 Agent 自动 clone（见根目录 [AGENTS.md](../AGENTS.md)）。

4. 若已有 `doghead-strategist/data/` 里的真实档案，**复制内容**到 `goutou-data/` 对应路径后 `git add` 首次提交（不要提交 `conversations/raw/`）。

## 日常：脚本同步

```bash
./scripts/sync-data-repo.sh
```

流程：`stash`（如有未提交改动）→ `pull --rebase` → `stash pop` → 有变更则 commit → `push`。冲突时 **退出码 2**，不 force push。

## 定时 + AI 合成（推荐分工）

| 步骤 | 谁做 |
|------|------|
| 定时触发（cron / Cursor `/loop` / 云 Agent） | 机器 |
| 无冲突的 pull / commit / push | `sync-data-repo.sh` |
| `normalized.jsonl` 冲突 | AI：按时间排序、按 `id` 或整行去重，**追加为主** |
| `state.yaml` 冲突 | AI：合并 `metrics`、`timeline` 条目；`stoploss_level` 取较高或带 `updated_at` 的字段 |
| `meta.yaml` 冲突 | AI：少改；冲突时保留两边事实，标 `notes` 待人工扫一眼 |

给 Agent 的固定提示（可贴进 automation）：

```text
在 GOUTOU_DATA_DIR 仓库执行 doghead-strategist/scripts/sync-data-repo.sh。
若退出码 2：仅解决冲突文件，遵守 docs/data-repo-ai-sync.md 的 jsonl/yaml 规则，
完成后 git rebase --continue 或完成 merge，再重新运行 sync-data-repo.sh。
禁止 git push --force。禁止添加图片或 conversations/raw/。
```

## 多设备

每台机器：clone `doghead-strategist` + clone `goutou-data`，同一 `GOUTOU_DATA_DIR`。先 pull 再让 Cursor 改 `state`/聊天，结束时跑 sync（或交给定时任务）。

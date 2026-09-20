# Cursor / Cloud Agent 说明（狗头军师）

本仓库是**开源策略与 Skill 代码**，不含真实聊天记录。私有档案在 **独立 Git 仓 `goutou-data`**（GitHub Private）。

## 新机器 / `git pull` 本仓库之后 — Agent 应主动做的事

1. 读项目根 `.env`（若不存在，从 `.env.example` 复制并补全）。
2. 确认 **`GOUTOU_DATA_DIR`** 指向本机 data 目录，且 **`GOUTOU_DATA_REPO_URL`** 为私有仓地址（默认见 `.env.example`）。
3. 若 `GOUTOU_DATA_DIR` 不存在、为空、或不是 git 仓库，**立即执行**：
   ```bash
   ./scripts/ensure-data-repo.sh
   ```
   用户只提供私有仓 URL 时：写入 `GOUTOU_DATA_REPO_URL`（及可选的 `GOUTOU_DATA_DIR`），再跑上述脚本。
4. 若用户说「同步数据」「拉档案」「恢复对话记录」，同样先 `ensure-data-repo.sh`，再视需要 `./scripts/sync-data-repo.sh`。
5. 读写对象档案时只改 **`$GOUTOU_DATA_DIR`** 下文件（`me/`、`people/<codename>/`），**禁止**把真实 data 提交进 `doghead-strategist`。

SSH 推私有仓失败时，让用户对照 [docs/github-ssh-horan-ding.md](docs/github-ssh-horan-ding.md)（Horan-Ding 账号与 `github.com` / 专用 Host 分离）。

## 改完档案之后

```bash
./scripts/sync-data-repo.sh
```

- 退出码 `0`：已同步或无变更。
- 退出码 `2`：合并冲突 → 按 [docs/data-repo-ai-sync.md](docs/data-repo-ai-sync.md) 合成 `normalized.jsonl` / `state.yaml` 等，**禁止** `git push --force`，完成后再次 `sync-data-repo.sh`。

## 用户发聊天截图（固定两步）

1. `screenshot-ingest.md`：识图、时间、`me/them`、jsonl、`sync-data-repo.sh`。
2. **仅** `qingsheng`（`SKILL.md`）生成回复。中间不要默认 `chat-analysis.md`。详见 [docs/skill-routing.md](docs/skill-routing.md)。

## Skill 入口

分析具体对象：`@goutou-junshi`（数据根目录规则见 `.cursor/skills/goutou-junshi/SKILL.md`）。

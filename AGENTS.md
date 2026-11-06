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
4. 若用户说「同步数据」「拉档案」「恢复对话记录」，缺仓时先 `ensure-data-repo.sh`，已有仓直接运行 `./scripts/sync-data-repo.sh`。
5. 读写对象档案时只改 **`$GOUTOU_DATA_DIR`** 下文件（`me/`、`people/<codename>/`），**禁止**把真实 data 提交进 `doghead-strategist`。
6. **截图入库**：append `normalized.jsonl` 前**先读已有行、去重**（同内容不重复写；用户可能把同一张图发给多个模型）。规则见 `.cursor/skills/goutou-junshi/references/howto/screenshot-ingest.md` §2。

SSH 推私有仓失败时，让用户对照 [docs/github-ssh-horan-ding.md](docs/github-ssh-horan-ding.md)（Horan-Ding 账号与 `github.com` / 专用 Host 分离）。

## 本地保存与定时同步

单实例运行：每次咨询只保存本地文件，不逐次 commit / pull / push。
工程启动时运行一次 `./scripts/auto-sync-data-repo.sh start`（可重复运行）；默认每 600 秒同步，重启环境后需重新启动。用户明确只读时不启动任务。

写档案时通过 `flock "$(git -C "$GOUTOU_DATA_DIR" rev-parse --git-path goutou-sync.lock)" <写入命令>` 包住读取、去重与写入这一整段操作，避免后台同步同时改文件。锁只覆盖本地文件操作，不包含模型思考或网络请求。

保存成功说「已保存到本地，等待定时同步」；不把本地保存等同于 GitHub 已同步。
用户明确要求立即同步时才运行 `./scripts/sync-data-repo.sh`。

- 状态：`./scripts/auto-sync-data-repo.sh status`；停止：`./scripts/auto-sync-data-repo.sh stop`。
- 同步退出码 `0`：本次远端同步成功；`1`：失败，下次重试；`75`：忙碌，稍后重试。
- 退出码 `2`：待处理的 merge/rebase；按 [同步说明](docs/data-repo-ai-sync.md) 处理，禁止强推。

## 用户发聊天截图（固定两步）

1. `screenshot-ingest.md`：识图、时间、`me/them`、jsonl 本地保存；后台定时同步。
2. **仅** `qingsheng`（`SKILL.md`）生成回复。中间不要默认 `chat-analysis.md`。详见 [docs/skill-routing.md](docs/skill-routing.md)。

## Skill 入口

分析具体对象：`@goutou-junshi`（数据根目录规则见 `.cursor/skills/goutou-junshi/SKILL.md`）。

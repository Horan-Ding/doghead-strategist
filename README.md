# 狗头军师 (goutou-junshi)

开源的是**策略引擎与数据约定**，不是你的聊天记录。真实数据放在 **`GOUTOU_DATA_DIR`**（默认仓库旁 `./data/`，已 gitignore）；**推荐**单独 **private Git 仓** + [docs/data-repo-ai-sync.md](docs/data-repo-ai-sync.md)。也可用 iCloud 等，见 [docs/private-data-and-sync.md](docs/private-data-and-sync.md)。

推 GitHub 请用 **Horan-Ding 专用 SSH**，勿与 `Host github.com` 默认密钥混用：见 [docs/github-ssh-horan-ding.md](docs/github-ssh-horan-ding.md)。

## 快速开始

```bash
cp .env.example .env
./scripts/ensure-data-repo.sh   # clone 私有 goutou-data；仅玩示例可改用 init-local-data.sh
```

**Cursor Agent**：换机或 `git pull` 后读 [AGENTS.md](AGENTS.md)，会自动拉私有 data 仓。

在 Cursor 中：

- **`@goutou-junshi`** — 咱们总入口（档案 + 状态 + 何时止损）
- **`@qingsheng`** — 情圣战术（已安装在 `.cursor/skills/qingsheng/`）

HowTo 恋爱教练库只做**部分集成**（8 个 reference 文件，含 `chat-analysis.md`，无第二个主 Skill），路由说明见 [docs/skill-routing.md](docs/skill-routing.md)。

分析具体对象时请指明代号（如 `demo-alice`），或设置 `GOUTOU_ACTIVE_PERSON`。

## 本机数据布局（`data/`，不进 Git）

```text
data/
├── config.yaml
├── me/profile.yaml
├── people/<codename>/
│   ├── meta.yaml          # 相对稳定：平台、标签、边界
│   ├── state.yaml         # 当前阶段与指标（高频更新）
│   ├── conversations/
│   │   ├── raw/           # 原始导出，仅本机
│   │   └── normalized.jsonl
│   └── snapshots/         # 可选：state 历史
└── sessions/              # 可选：单次咨询摘要
```

虚构示例见 `examples/people/demo-alice/`（可提交到仓库）。

## 仓库结构

| 路径 | 说明 |
|------|------|
| `.cursor/skills/goutou-junshi/` | Cursor Agent Skill |
| `schemas/` | `meta` / `state` / 消息行 JSON Schema |
| `examples/` | 脱敏演示数据 |
| `templates/` | 初始化 `data/` 用的模板 |
| `adapters/` | 未来：对接上游 Skill 的映射说明 |

## 隐私

- 禁止向本仓库提交 `data/`、截图、原始导出。
- PR 请只使用 `examples/` 中的虚构人物。

## License

MIT — 见 [LICENSE](LICENSE)。

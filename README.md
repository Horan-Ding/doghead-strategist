# 狗头军师 (goutou-junshi)

开源的是**策略引擎与数据约定**，不是你的聊天记录。真实对象、对话与状态只留在本机 `data/`（已 gitignore）。

## 快速开始

```bash
cp .env.example .env
./scripts/init-local-data.sh
```

在 Cursor 中通过 `@goutou-junshi` 或 `/goutou-junshi` 调用 Skill。分析具体对象时，请指明代号（如 `demo-alice`），或设置 `GOUTOU_ACTIVE_PERSON`。

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

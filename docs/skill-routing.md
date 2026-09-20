# Skill 怎么分工（咱们狗头军师 + 情圣 + HowTo 片段）

## 两层入口

1. **`goutou-junshi`（咱们自研）** — 唯一「总入口」：读 `GOUTOU_DATA_DIR`、狗头语气、写回 `state.yaml`、决定何时止损。
2. **`qingsheng`（上游 vendored）** — 战术主力：怎么回、怎么推、平台差异、`/展示面` `/挽回` `/自动` 等。

用户可以直接 `@qingsheng` 纯聊天；**有代号档案、要记状态**时优先 `@goutou-junshi`。

## 发聊天截图时谁会动（本仓库）

Cursor **不会**自动跑脚本；是靠 **Skill 描述 + 路由表** 让 Agent 读对应 markdown 后自行写 `goutou-data`。

| 顺序 | Skill / 文档 | 做什么 |
|------|----------------|--------|
| 1（建议 `@goutou-junshi` 或默认匹配到狗头） | `goutou-junshi` → `screenshot-ingest.md` | 识图、对齐 `me/them`、追加 `normalized.jsonl`、可选存 `raw/imports/`、`sync-data-repo.sh` |
| 2 | `goutou-junshi` → `chat-analysis.md` | 阶段、信号、问题 |
| 3 | `qingsheng` | 具体怎么回（短回复风格） |

只 `@qingsheng` 发截图时：**情圣**会分析/话术，但**不保证**写入 `GOUTOU_DATA_DIR`（除非 Agent 自己记得改文件）。要**稳定落盘**，请 `@goutou-junshi` 或先说「入库」。

**改之前（未强调 ingest）**：截图只在对话里被模型「看见」，一般**不会**自动写 jsonl——除非当次 Agent 手动更新了 `state.yaml` 等。

## HowTo「部分集成」是什么意思

| 做法 | 说明 |
|------|------|
| ✅ 做了 | 复制 8 个 `references/*.md` 到 `goutou-junshi/references/howto/`（含 `chat-analysis.md` 分析 SOP） |
| ❌ 没做 | 不安装第二个主 Skill `dating-coach/SKILL.md`（会和情圣重复触发） |
| ❌ 没做 | 不复制 `knowledge-base.md` 全文（体量大，与情圣 references 重叠高） |

触发规则写在 `goutou-junshi/SKILL.md` 的「路由表」里：Agent **先**判断场景，**再**打开对应 howto 文件，**然后**仍用情圣给具体话术（止损场景下话术让位于 howto 结论）。

## 数据别两套

- 档案以本仓库约定为准：`data/people/<codename>/meta.yaml` + `state.yaml` + `conversations/`。
- 情圣自带「档案存哪」流程时，**优先映射到** `GOUTOU_DATA_DIR`；howto 的 `profile-template.md` 只作字段对照，不另建 `profiles/` 目录进 Git。

## 升级

```bash
./scripts/sync-skills.sh
```

会刷新 `qingsheng` 全量 skill 目录，并按清单刷新 howto 片段。

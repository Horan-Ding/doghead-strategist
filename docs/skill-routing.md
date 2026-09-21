# Skill 怎么分工（咱们狗头军师 + 情圣 + HowTo 片段）

## 两层入口

1. **`goutou-junshi`（咱们自研）** — 唯一「总入口」：读 `GOUTOU_DATA_DIR`、狗头语气、写回 `state.yaml`、决定何时止损。
2. **`qingsheng`（基于上游的本地适配版）** — 回复主力：按证据判断是否回应、邀约、等待或停止，生成符合用户风格的话术。
3. **`damage-control`（止损）** — 还有没有戏、该不该放弃；读 `goutou-junshi/references/howto/damage-control.md`，写回 `state.flags.stoploss_level`。

用户可以直接 `@qingsheng`；它与 `@goutou-junshi` 共享档案和截图入库协议。**怀疑没戏、想止损**时用 `@damage-control`（狗头路由也会走同一 howto）。

**现任 / partner-skill**：未安装（见 `THIRD_PARTY.md`），需要长期伴侣顾问时再考虑。

## 发聊天截图时谁会动（本仓库）

Cursor **不会**自动跑脚本；是靠 **Skill 描述 + 路由表** 让 Agent 读对应 markdown 后自行写 `goutou-data`。

| 顺序 | Skill / 文档 | 做什么 |
|------|----------------|--------|
| 1 | `goutou-junshi` → `screenshot-ingest.md` | 识图、大概时间、`me/them`；文字/图/表情包简述 → `normalized.jsonl` → `sync-data-repo.sh` |
| 2 | **`qingsheng`**（读 `SKILL.md`） | **生成回复**（短、可复制）。中间**默认不**走 `chat-analysis.md` |

建议 **`@goutou-junshi` + 截图**，保证先 1 后 2。

直接 `@qingsheng` 发截图也执行同一个 `screenshot-ingest.md`；总入口已完成入库时不重复追加。用户明确只读或不保存时跳过写入与同步，仍可给建议。执行依赖 Agent，只有实际写入和同步完成才宣称成功。

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
- **唯一协议**：`.cursor/skills/qingsheng/references/user-context.md`，包括 `@qingsheng`、`/急`、`/自动`、`/挽回`。不再读写 `~/.qingsheng/` 或 `targets/*.md`；旧全局数据只在用户要求迁移时处理。
- 用户本轮明确指认优先于会话对象和配置默认值；七阶段咨询标签与 `state.stage` 的 schema 枚举分开。原始事实、状态推测、未执行建议分开记录。
- howto 的 `profile-template.md` 只作字段对照；真实档案按项目 `schemas/` 保存，不另建 `profiles/` 目录进 Git。

## 回复判断的共同规则

- 单个称呼、回复速度、深夜聊天不强制升阶；阶段依据应可追溯到双方行为和时间线。
- 拒绝按原意理解，不靠施压、贬低或虚构经历推进；等待和停止都是有效行动。
- `qingsheng/SKILL.md` 的证据与边界规则约束全部战术参考，包括自动和挽回模式。示例只提供表达参考，不充当真实档案。

## 升级

```bash
./scripts/sync-skills.sh
```

仅将上游 `qingsheng` 与 howto 下载到独立临时目录供对比，不覆盖本地规则。按 `qingsheng/qingsheng-upgrade.md` 合并需要的更新；`.agents/skills/` 副本如存在，也要核对并同步相同修改。

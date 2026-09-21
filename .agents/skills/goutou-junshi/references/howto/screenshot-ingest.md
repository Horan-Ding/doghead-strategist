# 聊天截图入库 SOP（第 1 步，完成后才调情圣）

用户发**聊天截图**时，本 SOP 是**固定第 1 步**。做完立刻进入第 2 步：**只读** `.cursor/skills/qingsheng/SKILL.md` 帮用户生成回复。**不要**在中间默认加载 `chat-analysis.md`（除非止损或用户明确要求深度分析）。

## 触发

- 用户消息含聊天界面**图片**，或说「入库」「记档案」且带图。

## 0. 准备

1. 读 `.env` → `GOUTOU_DATA_DIR`；缺则 `scripts/ensure-data-repo.sh`。
2. 确定 **codename**：用户本轮明确指认 → 本轮已确认对象 → `GOUTOU_ACTIVE_PERSON` → `config.yaml` 的 `default_person`。按统一档案协议匹配代号，有歧义问一句，不依赖 schema 中不存在的 `meta.display_name`。
3. 用户要求只读或不保存时，只识图并给建议，不追加文件、不运行同步。总入口或情圣已经完成本次入库时，读取结果，不重复执行。
4. 目录：
   - `people/<codename>/conversations/normalized.jsonl`
   - 可选 `conversations/raw/imports/<import_id>/`（原图，不进 Git）

`import_id`：`YYYY-MM-DDTHHMMSS`。

## 1. 识图：谁说的 + 大概时间

- **微信**：右绿泡 → `me`；左白泡 → `them`；灰条系统 → `from: system`, `kind: system`。
- **时间**：气泡旁可见则 ISO8601 `ts`；只有「昨天/上午」等 → 估到日或时段 + `ts_inferred: true`；完全看不出可省略 `ts`。
- **文字**：OCR 进 `text`。
- **表情包**：`kind: sticker`，`text` 如 `[表情包：捂脸]`。
- **图片消息**：`kind: image`，`text` 如 `[图片：风景]` 或一句可见内容摘要。

## 2. 追加 JSONL

路径：`$GOUTOU_DATA_DIR/people/<codename>/conversations/normalized.jsonl`

遵守 `schemas/message-line.schema.json`：

```json
{"id":"01JEXAMPLE","ts":"2026-09-20T13:56:00+08:00","from":"them","text":"周日又要调休","kind":"text","source":{"type":"screenshot","import_id":"2026-09-20T171200","confidence":0.9}}
```

- `from` 仅 `me` | `them` | `system`。
- 去重：已有相同 `ts`+`from`+`text` 或同 `id` 则跳过。

## 3. 原图（可选）

`raw/imports/<import_id>/page-1.png`，行内 `source.image` 写相对路径。

## 4. 同步

```bash
./scripts/sync-data-repo.sh
```

## 5. 第 2 步（本 SOP 结束后立即做）

1. 读取 **`.cursor/skills/qingsheng/SKILL.md`**，用 `meta` / `state` / 本次追加的 jsonl 作为上下文，**生成回复**（情圣短回复风格）。
2. 不在此步写长篇阶段分析报告。适合等待或停止时不硬凑可发话术。
3. 按 `.cursor/skills/qingsheng/references/user-context.md` 保存必要状态变化；用户另要求深度分析时再跑 `chat-analysis.md`。

## 对用户回复格式

```text
已入库：<codename> +N 条（sync 完成）。
---
（下面直接接情圣建议；适合回复时主推一句，也可以建议不发）
```

只有同步确实完成才能写「sync 完成」；否则说明已本地入库但未同步。只读时不输出入库成功。

# 聊天截图入库 SOP

用户在本项目里**发送聊天截图**时，在分析/出话术之前，先把可见消息**落盘**到 `GOUTOU_DATA_DIR`（独立 `goutou-data` 仓）。

## 触发

- 用户消息含**图片**（微信/探探等聊天界面），或明确说「入库」「记到档案」「保存这段聊天」。
- 与 `chat-analysis.md` 连用：**先本 SOP，再分析 SOP，再情圣话术**。

## 0. 准备

1. 读 `.env` → `GOUTOU_DATA_DIR`；缺则 `scripts/ensure-data-repo.sh`。
2. 确定 **codename**：`GOUTOU_ACTIVE_PERSON` → `config.yaml` 的 `default_person` → 用户当次说明 → `meta.yaml` 里 `display_name` 匹配。不确定则问一句。
3. 确保目录存在：
   - `people/<codename>/conversations/normalized.jsonl`
   - `people/<codename>/conversations/raw/imports/<import_id>/`（仅本机，不进 Git）

`import_id` 建议：`YYYY-MM-DDTHHMMSS`（UTC 或本地一致即可）。

## 1. 识图与说话人

- **微信**：右侧绿泡 / 常见「我」侧 → `from: me`；左侧白泡 → `from: them`；居中灰条 → `from: system`, `kind: system`。
- 其他平台对照 `qingsheng` 的 `platform-guide.md`；默认仍用 `me` / `them`。
- 表情包：`kind: sticker`，`text` 写简短描述，如 `[表情包：捂脸]`。
- 纯图片消息：`kind: image`，`text` 写 `[图片]` 或可见 OCR 摘要。
- 气泡旁有时间则解析为 ISO8601 `ts`；看不清则省略秒或用日期 + `ts_inferred: true`。

## 2. 写成 JSONL（一行一条）

路径：`$GOUTOU_DATA_DIR/people/<codename>/conversations/normalized.jsonl`

字段见 `schemas/message-line.schema.json`。示例：

```json
{"id":"01JEXAMPLE","ts":"2026-09-20T13:56:00+08:00","from":"them","text":"周日又要调休","kind":"text","source":{"type":"screenshot","import_id":"2026-09-20T171200","confidence":0.9}}
```

- **`id`**：新消息必生成（可用时间+内容 hash）；用于去重。
- **`from`**：只用 `me` | `them` | `system`（勿写 `her`/`him`）。
- **去重**：追加前读已有 jsonl，若同 `ts`+`from`+`text`（或同 `id`）已存在则跳过。

## 3. 原图（可选）

若能把用户上传的图写到 data 目录（本机路径可用时）：

`people/<codename>/conversations/raw/imports/<import_id>/page-1.png`

在对应行的 `source.image` 写相对路径。无法写文件则只 jsonl，仍填 `import_id`。

可选元数据：`people/<codename>/conversations/imports/<import_id>.json`（`images` + `message_ids` 列表）。

## 4. 同步

```bash
./scripts/sync-data-repo.sh
```

冲突按 `docs/data-repo-ai-sync.md` 处理后再 sync。

## 5. 再交给下游

入库完成后：

1. `references/howto/chat-analysis.md` — 分析。
2. `.cursor/skills/qingsheng/SKILL.md` — 话术（狗头军师语气包装即可）。
3. 必要时更新 `state.yaml` / `meta.yaml`（时间线、open_threads）。

## 回复用户习惯

入库后一句话确认即可，例如：「已追加 N 条到 `liyingxuan/normalized.jsonl` 并 sync。」再进入分析，避免长报告。

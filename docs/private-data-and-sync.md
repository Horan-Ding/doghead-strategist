# 私有 data 放哪、怎么云同步

开源仓库里**永远不要**放真实 `data/`。代码可以 `git clone`，**关系数据**用单独目录同步。

## 推荐：代码与 data 分离

| 内容 | 放哪 | 同步方式 |
|------|------|----------|
| `doghead-strategist` 代码 | 任意目录 `git clone` | GitHub（可 public） |
| 狗头军师私有 data | **`GOUTOU_DATA_DIR` → 独立 private Git 仓** | `./scripts/sync-data-repo.sh` + 可选 AI 处理冲突 |

**首选**：独立 data 仓（例如 `Horan-Ding/goutou-data`）——搭建与 AI 定时同步见 [data-repo-ai-sync.md](data-repo-ai-sync.md)。

| 备选 | 同步方式 |
|------|----------|
| iCloud / Dropbox / Syncthing | 整目录放在同步盘，仍用 `GOUTOU_DATA_DIR` |

设置方式（任选其一）：

```bash
# 项目根 .env（已 gitignore）
GOUTOU_DATA_DIR="/path/to/your/synced/goutou-data"
```

或在 shell 配置里 `export GOUTOU_DATA_DIR=...`。

初始化：

```bash
export GOUTOU_DATA_DIR="/path/to/your/synced/goutou-data"
./scripts/init-local-data.sh
```

Skill 与脚本优先读 `GOUTOU_DATA_DIR`，未设置时才是仓库旁的 `./data/`。

## macOS：iCloud Drive（省事）

1. 在 iCloud 盘里建目录，例如：`~/Library/Mobile Documents/com~apple~CloudDocs/goutou-data`
2. `GOUTOU_DATA_DIR` 指到该路径并执行 `init-local-data.sh`
3. 换 Mac 登录同一 Apple ID 后，装好 Cursor、clone 代码、同样设置 `GOUTOU_DATA_DIR` 即可

注意：iCloud 对大量小文件偶发延迟；`conversations/raw/` 很大时更适合 Syncthing 或网盘整目录同步。

## 其他常见方案

- **Dropbox / OneDrive / 坚果云**：整目录放在同步盘内，同上设置 `GOUTOU_DATA_DIR`。
- **Syncthing**：多设备点对点，不经过商业云明文策略时更可控（仍建议见下「加密」）。
- **私有 Git 仓库**：与 `doghead-strategist` **不同 remote**；仓内根目录即 data 树（不是嵌套 `data/` 子目录）。模板见 `templates/data-repo/`。

## 安全提醒（聊天记录很敏感）

- 云同步 = 数据在第三方或 Apple 服务器上，**默认不是端到端加密**。
- 至少：强密码、全盘加密、不开共享链接；有顾虑可对 `goutou-data` 用 **Cryptomator** 等加密卷再放进 iCloud。
- 不要把 data 目录提交到 `Horan-Ding/doghead-strategist` 公开仓库。

## 迁移清单

1. 新机器：安装 Cursor、clone `doghead-strategist`
2. 云盘登录 / Syncthing 配对，确认 `goutou-data` 已同步
3. 配置 `GOUTOU_DATA_DIR` 与（若使用）Horan-Ding 专用 SSH Host
4. 无需复制仓库里的 `./data/`（若你从未用过本地 `./data/`）

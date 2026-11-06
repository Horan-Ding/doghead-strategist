# 单实例：本地保存 + 定时同步

真实档案放在独立私有 Git 仓 `GOUTOU_DATA_DIR`。每次咨询只写本地文件，后台默认每 10 分钟合并提交并同步 GitHub；不用每次对话都等待 push。

## 初始化与启动（Linux）

依赖 Bash、Git、`flock`（util-linux）。配置 `.env` 的 `GOUTOU_DATA_DIR` 和 `GOUTOU_DATA_REPO_URL`，云环境使用已有 HTTPS Git 认证。缺仓时执行 `./scripts/ensure-data-repo.sh`；已有仓不自动 pull。

```bash
./scripts/auto-sync-data-repo.sh start
./scripts/auto-sync-data-repo.sh status
./scripts/auto-sync-data-repo.sh stop
```

重复启动不会创建第二个任务。首次同步也等待一个周期。修改 `.env` 中 `GOUTOU_SYNC_INTERVAL_SECONDS=600` 后 stop，等 status 显示 Stopped，再 start。

后台任务只在机器运行时生效；环境休眠、停止或重建后要重新 start，不能承诺离线期间定时备份。进程在停止时会等待正在进行的一次同步结束。

日志在代码仓已忽略的 `.goutou/auto-sync/log`，最近结果在 `last-result`。日志超过约 1 MiB 后保留末尾约 512 KiB 到 `log.previous` 并清空当前日志。启动成功不等于同步成功，须检查最近结果。不要提交这些运行文件。

## 本地写入与同步互斥

Agent 写档案时，把实际读取、去重、写回放在同一个短暂的锁内。例如 `.env` 已加载时：

```bash
flock "$(git -C "$GOUTOU_DATA_DIR" rev-parse --git-path goutou-sync.lock)" python3 your_local_writer.py
```

这里的 writer 是实际写入命令，不是仓库提供的脚本。锁内不等待模型生成或进行网络调用。同步脚本使用同一把锁；有写入进行时跳过本轮，下周期重试。

## 单次同步与失败处理

用户明确要求立即同步，或退出前希望确认备份时：

```bash
./scripts/sync-data-repo.sh
```

流程：锁定 → 检查冲突状态 → 本地变更 commit → fetch → rebase → 有待推送提交时 push。

- 无本地变更时仍检查远端，也会补推之前失败留下的提交。
- 网络失败不 stash，本地成果保留在提交中；下一周期重试。
- 同步退出码：`0` 成功，`1` 失败，`2` 有待处理的 merge/rebase，`75` 忙碌稍后重试。
- 有冲突时后台不会自动改档案或强推。先 stop，人工核对双方内容并完成或撤销 rebase，再 start。消息保留真实记录并去重；状态依证据判断，不机械取更高风险等级。
- 默认同步本地当前分支同名的 origin 分支。若云平台生成 `work` 分支，可明确配置 `GOUTOU_DATA_BRANCH=main`；不要自动重命名、reset 或丢弃改动。
- 新建远端分支不由定时任务负责；先明确目标并初始化。未配置 origin 时只完成本地提交，返回失败而非宣称远端已同步。

任务使用 `git add -A`，遵守数据仓 `.gitignore`；原图与原始导出应放 `conversations/raw/`，不要把其他私密文件随意放进可提交目录。只读咨询不写档案、不启动同步；已运行的后台任务仍可能同步之前保存的内容。若需要暂停后台，用 stop。

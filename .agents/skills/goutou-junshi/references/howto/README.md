# HowTo 部分集成（仅 reference，非完整 Skill）

来源：[Mayuqi-crypto/HowToGetAlongWithGirls](https://github.com/Mayuqi-crypto/HowToGetAlongWithGirls)（MIT）中的 `dating-coach/references/*.md`。

**未拷贝**整份 `dating-coach/SKILL.md`，避免与 `.cursor/skills/qingsheng` 抢路由、重复角色定义。

| 文件 | 何时由狗头军师加载 |
|------|-------------------|
| `screenshot-ingest.md` | **聊天截图第 1 步**：识图、时间、说话人、jsonl、sync；**第 2 步固定情圣出回复**（中间不默认 chat-analysis） |
| `chat-analysis.md` | 粘贴文字 / 明确要求深度分析时——再走完整分析 SOP，再联动情圣 |
| `damage-control.md` | 止损、没戏、已读不回、越聊越冷、`state.flags.stoploss_level >= 2` |
| `hard-value-reality.md` | 问配不配、段位、外貌经济地位、话术能否逆天改命 |
| `self-diagnosis.md` | 形象/聊天习惯自评、找短板 |
| `signal-patterns.md` | 礼貌 vs 兴趣 vs 废测 vs 拒绝 分不清 |
| `realistic-scenarios.md` | 被拒、好人卡、约会冷场、体面收场 |
| `lifecycle.md` | 已恋爱/长期/见家长等（超出情圣七阶段主战场） |
| `profile-template.md` | 把对象信息整理进 `data/people/<codename>/` 时对照字段 |

`screenshot-ingest.md` 与 `damage-control.md` 含本地适配。运行仓库根目录 `scripts/sync-skills.sh` 仅下载上游候选，核对后合并需要的变化，不覆盖统一档案与证据判断规则。

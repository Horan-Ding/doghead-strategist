# Horan-Ding 专用 GitHub SSH（与本机 fenglibin 账号分开）

本机默认 `~/.ssh/id_ed25519` 对应 **fenglibinjie@gmail.com / GitHub aderan**，不能用来推 `Horan-Ding/*`。

已为 **Horan-Ding** 单独生成密钥（若不存在）：

- 私钥：`~/.ssh/id_ed25519_horan_ding`（勿分享、勿提交）
- 公钥：`~/.ssh/id_ed25519_horan_ding.pub` → 加到 **Horan-Ding** GitHub → Settings → SSH keys

## SSH 配置示例

在 `~/.ssh/config` 增加（保留你原有的代理 `ProxyCommand` 即可照抄一份）：

```sshconfig
Host github.com-horan-ding
    Hostname ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/id_ed25519_horan_ding
    HostKeyAlias github.com
    ProxyCommand nc -X 5 -x 127.0.0.1:7897 %h %p
```

验证：

```bash
ssh -T git@github.com-horan-ding
# 期望：Hi Horan-Ding! ...
```

## 本仓库 remote

```bash
cd /path/to/doghead-strategist
git remote set-url origin git@github.com-horan-ding:Horan-Ding/doghead-strategist.git
git push -u origin main   # 或你的分支名
```

`github.com` 仍走 fenglibin 的 key；只有带 `github.com-horan-ding` 的 URL 才用 Horan-Ding 的 key。

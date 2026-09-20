# Horan-Ding 专用 GitHub SSH（与默认账号分开）

若本机 `~/.ssh/config` 里 `Host github.com` 已绑定**另一个** GitHub 账号的密钥，不要用那条 key 推 `Horan-Ding/*` 仓库。

为 **Horan-Ding** 单独生成密钥（若不存在）：

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

`Host github.com` 仍走默认账号的 key；remote URL 使用 `github.com-horan-ding` 时才会用 Horan-Ding 的 key。

# 部署模式参考

按需读取。主 SKILL.md 仅在 devops Agent 启动时加载核心协议，长内容按场景加载。

---

## 部署策略

### 全量部署（Rolling Update）
- 逐批替换旧版本
- 适合：小规模、风险低的变更

### 蓝绿部署
- 准备新版本环境（绿）
- 流量切换（蓝→绿）
- 出问题快速切回
- 适合：关键服务、零停机要求

### 金丝雀部署
- 小比例流量到新版本（5% → 20% → 50% → 100%）
- 监控关键指标，异常立即停止
- 适合：大规模、需要真实流量验证

### Feature Flag
- 代码已部署但功能未启用
- 运行时开关控制
- 适合：逐步推出、A/B 测试、紧急回滚

---

## 健康检查

### 部署后必须验证

- `/health` 端点：存活、就绪、关键依赖（DB、Redis）
- 核心业务路径：至少一个端到端的冒烟测试
- 指标健康：错误率、延迟、流量未显著恶化（观察 5-15 分钟）

### 健康检查失败的响应

- 短时波动：等待（可能是启动预热）
- 持续失败：立即回滚
- 回滚也失败：升级应急响应

---

## 文件传输完整性（v3.5 新增 — 来自眼科项目实测）

**触发条件**：scp / rsync / sftp 任何文件传输到远端服务器，**必须**校验完整性。

来自眼科项目 feedback `deploy-md5-check`：曾因 scp 静默截断导致部署的 jar 损坏，后端服务起不来，排查多个小时才定位到是文件不完整。

### 必须做（不是可选）

```bash
# Step 1: 上传前算本地 md5
LOCAL_MD5=$(md5sum dist/app.jar | awk '{print $1}')

# Step 2: scp 上传
scp dist/app.jar user@host:/path/to/

# Step 3: 远端算 md5（关键！）
REMOTE_MD5=$(ssh user@host "md5sum /path/to/app.jar | awk '{print \$1}'")

# Step 4: 对比
if [ "$LOCAL_MD5" != "$REMOTE_MD5" ]; then
  echo "FATAL: file corrupted during transfer"
  echo "  local : $LOCAL_MD5"
  echo "  remote: $REMOTE_MD5"
  exit 1
fi

echo "OK: md5 match $LOCAL_MD5"
# Step 5: 才允许重启服务
ssh user@host "systemctl restart app"
```

### 反例（实战发生过）

```bash
# ❌ 错误：直接 scp + restart，没校验
scp dist/app.jar user@host:/path/
ssh user@host "systemctl restart app"
# 结果：jar 在传输中被静默截断（网络波动 / 磁盘满 / 权限问题）
# 现象：服务重启后 ClassNotFoundException 但代码明明没改
```

### 适用范围

| 场景 | 必须校验 |
|:--|:--|
| jar / war / 二进制可执行 | ✅ |
| docker image 上传 | docker pull 自带校验 ✅ |
| 大文件（> 10MB） | ✅ |
| 配置文件（.env / .yaml） | ✅ 建议（容易被传到一半） |
| 静态资源 zip / tar | ✅ |

**判据**：devops 在交付任何"上传 + 重启"流程时，**没 md5 校验视为 [严重]**。

---

## 双产物 / 多端同步编译（v3.5 新增 — 来自眼科项目）

**触发条件**：项目同时输出多个产物（如 uni-app 同时 H5 + mp-weixin、Tauri 同时 desktop + mobile、Next.js 同时 SSR + static）。

来自眼科项目 feedback `compile-both`：每次修改必须**同时**编译所有产物，因为：

```bash
# ❌ 错误：只编译一个就推
npm run build:h5
git push  # mp-weixin 可能因平台特性差异编译失败

# ✅ 正确：双产物都通过才推
npm run build:h5 && npm run build:mp-weixin
# 或并行
npm run build:h5 & npm run build:mp-weixin & wait
git push
```

### 平台特性差异（uni-app 实例）

- H5 支持 `localStorage`，小程序需用 `uni.setStorage`
- H5 CSS 支持 `position: fixed`，小程序部分场景受限
- H5 用 `<input type="password">`，小程序需 `password` 布尔属性（已固化到 `rules/_framework/wechat-mp.md`）

**判据**：双产物项目的 PR 必须证明所有产物编译通过，不接受"H5 build 通过所以 mp 也行"的假设。

# 远程 Notebook 配置指南

## 环境信息

- **主机**: ascendyun (ModelArts Notebook)
- **SSH**: `ssh ascendyun`
- **持久化目录**: `~/work/`（重启后保留）
- **临时目录**: `~/`、`/tmp/`（重启后丢失）

---

## 已完成配置

### 1. 持久化 .claude 目录

```bash
# 创建持久化目录
mkdir -p ~/work/.claude

# 创建软链接（重启后自动生效）
ln -sf ~/work/.claude ~/.claude
```

### 2. Claude Code 安装位置

```
~/work/node/bin/claude  # 版本 2.1.122
```

### 3. Claude Code 配置

文件位置：`~/work/.claude/settings.json`

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "3c77df5cb2424642aae7d052e234f5ad.g2XuHGzqaIUWhwLZ",
    "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
    "ANTHROPIC_MODEL": "glm-5.1"
  }
}
```

---

## 使用方法

### 方式 1：直接使用完整路径

```bash
/home/ma-user/work/node/bin/claude
```

### 方式 2：添加到 PATH（推荐）

```bash
# 添加到 ~/.bashrc
echo 'export PATH="/home/ma-user/work/node/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 然后直接使用
claude
```

### 方式 3：创建别名

```bash
# 添加到 ~/.bashrc
echo 'alias claude="/home/ma-user/work/node/bin/claude"' >> ~/.bashrc
source ~/.bashrc

# 然后直接使用
claude
```

---

## 重启后恢复

由于配置已持久化到 `~/work/.claude/`，重启后只需：

```bash
# 1. 确认软链接存在
ls -la ~/.claude
# 应该显示: ~/.claude -> /home/ma-user/work/.claude

# 2. 如果软链接丢失，重新创建
ln -sf ~/work/.claude ~/.claude

# 3. 确认 PATH 配置
source ~/.bashrc
which claude
```

---

## 验证配置

```bash
# 测试 Claude Code
/home/ma-user/work/node/bin/claude --version

# 测试 API 连接
/home/ma-user/work/node/bin/claude -p "你好，这是测试"
```

---

## 配置文件结构

```
~/work/.claude/
├── settings.json          # Claude Code 配置（API 密钥、模型）
├── projects/              # 项目配置（如有）
├── agents/                # Agent 定义（如有）
├── skills/                # Skill 定义（如有）
└── rules/                 # Rule 定义（如有）
```

---

## 注意事项

1. **不要在 ~/.claude/ 下直接创建文件**，所有配置都写入 `~/work/.claude/`
2. **重启后检查软链接**，如果丢失需要重新创建
3. **API 密钥已配置**，无需每次设置环境变量
4. **模型使用 glm-5.1**，通过智谱 bigmodel API 调用

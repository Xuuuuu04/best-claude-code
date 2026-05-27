## 敏感文件保护

以下文件/目录在任何项目中都不应被修改或读取（除非用户明确要求）：

**绝不修改：**
- `.env` / `.env.*` / `*.env`（环境变量，可能含密钥）
- `credentials.json` / `auth.json` / `api_keys.json`
- `~/.ssh/` / `~/.aws/`
- 任何包含 `secret`、`credential`、`token` 的配置文件

**绝不 commit：**
- 上述所有文件
- `node_modules/` / `.venv/` / `dist/` / `build/`
- 二进制大文件（>1MB 的图片/视频/压缩包）

**绝不在代码或 commit message 中出现：**
- API key、密码、token 的明文值
- 如果在代码中发现硬编码的密钥，立即提醒用户

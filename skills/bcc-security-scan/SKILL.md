---
name: bcc-security-scan
description: 安全扫描——检查依赖漏洞、代码安全问题和敏感信息泄露
disable-model-invocation: true
---

## 安全扫描流程

1. 检查依赖漏洞：
   - Node.js: `!`npm audit --json 2>/dev/null || echo "{}"``
   - Python: `!`pip audit --format json 2>/dev/null || echo "{}"``
   - Go: `!`govulncheck ./... 2>/dev/null || echo "govulncheck not available"``
2. 搜索硬编码密钥和敏感信息：
   - API keys, tokens, passwords, private keys
   - 检查 `.env` 文件是否在 `.gitignore` 中
3. 检查常见安全问题：
   - SQL 注入风险
   - XSS 风险
   - 不安全的反序列化
   - 路径遍历风险
4. 生成安全扫描报告，按严重程度分级（严重/高/中/低）
5. 如有严重或高级别问题，建议修复方案

---
name: remote-diag-protocol
description: 远程/云端诊断协议。当任务涉及生产/staging 环境、远程服务器、云函数、部署状态、线上日志时使用。提供命令白名单、证据收集流程、风险边界。
when_to_use: 调研远程部署状态、云端服务健康、线上错误日志、小程序云函数、远程数据库只读查询、CI/CD 状态、生产环境审计。
---

# Remote Diagnosis Protocol

tech-researcher 调研"远程/云端"时的标准作业流程。

## 适用范围

当需求涉及以下任一关键词，启用此协议：

- 线上 / 生产 / production / prod / live
- staging / 预发布 / uat
- 云函数 / serverless / lambda
- 部署状态 / deploy status / release
- 远程日志 / 线上日志 / error log
- 小程序云开发 / wx-cloud / tcb
- 服务器健康 / health / uptime

## 四步诊断法

### 1. 范围确认（必须先做）

动手前，在 artifact 里明确写出：

| 维度 | 取值 |
|:--|:--|
| 环境 | 本地 / staging / production |
| 目标 | 具体服务名 + 版本 / commit |
| 用户可观察现象 | 一句话描述 |
| 可复现条件 | 环境变量、时间、用户角色、参数 |
| 不变量（可接受的副作用） | 比如"不能改生产 DB"、"只读" |

**范围不清时立即停止**，返回主会话请求补充。**不要靠猜**。

### 2. 命令白名单（只读）

以下命令在 tech-researcher 内允许直接执行。**只读**，不改变远程状态：

```bash
# 网络/HTTP 层
curl -sI https://example.com/health           # HTTP status
curl -s  https://example.com/api/... | jq .

# SSH 只读（假设已有 key；无则升级到"请用户代查"）
ssh user@host 'systemctl status <svc>'
ssh user@host 'journalctl -u <svc> --since="10 min ago" --no-pager'
ssh user@host 'tail -200 /var/log/<svc>.log'
ssh user@host 'ps aux | grep <svc>'
ssh user@host 'df -h'

# GitHub / Git 状态
gh pr view <N>  |  gh pr checks <N>
gh run list --limit 20
gh run view <RUN_ID>
git log --oneline -20 <branch>

# Kubernetes（只读）
kubectl get pods -n <ns>
kubectl logs <pod> -n <ns> --tail=200
kubectl describe pod <pod> -n <ns>

# Docker 远程（只读）
docker ps -a
docker logs <container> --tail=200

# 小程序云开发
# - 小程序云函数日志一般需走微信云平台控制台，不是 shell；
# - 若已配 tcb-cli，可 `tcb functions:log <name> --limit 50`
```

### 3. 命令黑名单（绝不自动执行）

以下命令**必须**返回主会话要求用户确认，或转交 `devops`：

- 任何写操作：`kubectl apply` / `kubectl delete` / `helm upgrade` / `systemctl restart` / `docker rm` / `git push`
- 任何 schema 或数据操作：`mysql> UPDATE/DELETE/INSERT` / `psql ...` 写类
- 重启 / 扩缩容 / 切流：`kubectl scale` / `kubectl rollout` / `pm2 restart`
- 生产部署 / 发版 / 回滚：调 `devops` Agent 并经用户明确确认

### 4. 证据格式（写入 artifact）

每条远程命令的产出记录为：

```markdown
### 命令：`curl -sI https://api.example.com/health`

**环境**：production
**执行时间**：2026-04-25T10:30:00+0800
**结果**（前 20 行）：
```
HTTP/1.1 200 OK
Server: nginx
x-request-id: abc
...
```

**判断**：服务健康 / 5xx / 超时 / 拒连 / 需要更多数据
```

命令失败或超时同样记录，不掩盖。

## 升级触发条件

以下情况，tech-researcher 必须停止并返回主会话：

1. 命令需要密钥/token 而本地没有
2. 命令可能产生副作用但边界不清
3. 发现敏感数据（密钥/PII）出现在日志 → 只记录长度，不复制内容
4. 数据大于 artifact 合理容量（>100 行）→ 写到临时文件，artifact 只引用路径
5. 连续 3 条命令都失败 → 说明前提错了，停止推进

## 与其他 Agent 的分界

- `devops`：真正执行远程写操作（部署/回滚/配置变更）
- `security-auditor`：审查远程操作的授权与最小权限
- `tech-researcher`（本 Agent）：**只读**，负责还原事实 + 给出假设

## 参考

- 只读命令模式与风险分级：`references/readonly-commands.md`（按需）

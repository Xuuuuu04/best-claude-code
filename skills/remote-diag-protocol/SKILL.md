---
name: remote-diag-protocol
description: 远程/云端诊断协议。当任务涉及生产/staging 环境、远程服务器、云函数、部署状态、线上日志时使用。提供命令白名单、证据收集流程、风险边界。
when_to_use: 调研远程部署状态、云端服务健康、线上错误日志、小程序云函数、远程数据库只读查询、CI/CD 状态、生产环境审计。
---

<skill>
  <overview>
    <summary>技术调研专家 调研"远程/云端"时的标准作业流程。</summary>
    <scope>
      <item>当需求涉及以下任一关键词，启用此协议：</item>
      <trigger keyword="线上"/> <trigger keyword="生产"/> <trigger keyword="production"/> <trigger keyword="prod"/> <trigger keyword="live"/>
      <trigger keyword="staging"/> <trigger keyword="预发布"/> <trigger keyword="uat"/>
      <trigger keyword="云函数"/> <trigger keyword="serverless"/> <trigger keyword="lambda"/>
      <trigger keyword="部署状态"/> <trigger keyword="deploy status"/> <trigger keyword="release"/>
      <trigger keyword="远程日志"/> <trigger keyword="线上日志"/> <trigger keyword="error log"/>
      <trigger keyword="小程序云开发"/> <trigger keyword="wx-cloud"/> <trigger keyword="tcb"/>
      <trigger keyword="服务器健康"/> <trigger keyword="health"/> <trigger keyword="uptime"/>
    </scope>
  </overview>

  <workflow>
    <phase n="1" name="范围确认（必须先做）">
      <description>动手前，在 artifact 里明确写出：</description>
      <table>
        <field name="环境" value="本地 / staging / production"/>
        <field name="目标" value="具体服务名 + 版本 / commit"/>
        <field name="用户可观察现象" value="一句话描述"/>
        <field name="可复现条件" value="环境变量、时间、用户角色、参数"/>
        <field name="不变量（可接受的副作用）" value="比如"不能改生产 DB"、"只读""/>
      </table>
      <note type="warning">范围不清时立即停止，返回主会话请求补充。不要靠猜。</note>
    </phase>

    <phase n="2" name="命令白名单（只读）">
      <description>以下命令在 技术调研专家 内允许直接执行。只读，不改变远程状态：</description>
      <command-group name="网络/HTTP 层">
        <command>curl -sI https://example.com/health           # HTTP status</command>
        <command>curl -s  https://example.com/api/... | jq .</command>
      </command-group>
      <command-group name="SSH 只读（假设已有 key；无则升级到"请用户代查"）">
        <command>ssh user@host 'systemctl status &lt;svc&gt;'</command>
        <command>ssh user@host 'journalctl -u &lt;svc&gt; --since="10 min ago" --no-pager'</command>
        <command>ssh user@host 'tail -200 /var/log/&lt;svc&gt;.log'</command>
        <command>ssh user@host 'ps aux | grep &lt;svc&gt;'</command>
        <command>ssh user@host 'df -h'</command>
      </command-group>
      <command-group name="GitHub / Git 状态">
        <command>gh pr view &lt;N&gt;  |  gh pr checks &lt;N&gt;</command>
        <command>gh run list --limit 20</command>
        <command>gh run view &lt;RUN_ID&gt;</command>
        <command>git log --oneline -20 &lt;branch&gt;</command>
      </command-group>
      <command-group name="Kubernetes（只读）">
        <command>kubectl get pods -n &lt;ns&gt;</command>
        <command>kubectl logs &lt;pod&gt; -n &lt;ns&gt; --tail=200</command>
        <command>kubectl describe pod &lt;pod&gt; -n &lt;ns&gt;</command>
      </command-group>
      <command-group name="Docker 远程（只读）">
        <command>docker ps -a</command>
        <command>docker logs &lt;container&gt; --tail=200</command>
      </command-group>
      <command-group name="小程序云开发">
        <note>小程序云函数日志一般需走微信云平台控制台，不是 shell；若已配 tcb-cli，可 tcb functions:log &lt;name&gt; --limit 50</note>
      </command-group>
    </phase>

    <phase n="3" name="命令黑名单（绝不自动执行）">
      <description>以下命令必须返回主会话要求用户确认，或转交 高级运维工程师：</description>
      <blacklist>
        <item>任何写操作：kubectl apply / kubectl delete / helm upgrade / systemctl restart / docker rm / git push</item>
        <item>任何 schema 或数据操作：mysql&gt; UPDATE/DELETE/INSERT / psql ... 写类</item>
        <item>重启 / 扩缩容 / 切流：kubectl scale / kubectl rollout / pm2 restart</item>
        <item>生产部署 / 发版 / 回滚：调 高级运维工程师 Agent 并经用户明确确认</item>
      </blacklist>
    </phase>

    <phase n="4" name="证据格式（写入 artifact）">
      <description>每条远程命令的产出记录为：</description>
      <template>
        <![CDATA[
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
        ]]>
      </template>
      <note>命令失败或超时同样记录，不掩盖。</note>
    </phase>
  </workflow>

  <checklist>
    <escalation-triggers>
      <trigger n="1">命令需要密钥/token 而本地没有</trigger>
      <trigger n="2">命令可能产生副作用但边界不清</trigger>
      <trigger n="3">发现敏感数据（密钥/PII）出现在日志 → 只记录长度，不复制内容</trigger>
      <trigger n="4">数据大于 artifact 合理容量（>100 行）→ 写到临时文件，artifact 只引用路径</trigger>
      <trigger n="5">连续 3 条命令都失败 → 说明前提错了，停止推进</trigger>
    </escalation-triggers>

    <agent-boundaries>
      <boundary agent="高级运维工程师" role="真正执行远程写操作（部署/回滚/配置变更）"/>
      <boundary agent="高级安全审计师" role="审查远程操作的授权与最小权限"/>
      <boundary agent="技术调研专家" role="只读，负责还原事实 + 给出假设"/>
    </agent-boundaries>
  </checklist>

  <reference>
    <file path="references/readonly-commands.md" purpose="只读命令模式与风险分级（按需）"/>
  </reference>
</skill>

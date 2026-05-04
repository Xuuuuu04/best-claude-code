---
name: release-checklist
description: Agent Legion 发布前确定性检查。用于提交或推送前确认版本号一致、运行态文件未入库、DispatchTicket 合法、hook/rule/doctor 检查通过，并在 push 后确认本地 HEAD 与 origin/main 对齐。
argument-hint: "[target-branch]"
disable-model-invocation: true
---

<skill name="release-checklist" type="system-release">

<overview>
发布前后检查清单。该 Skill 不派遣 subagent，不做模型判断；只要求主会话按固定命令验证发布状态。
</overview>

<commands>
  <command purpose="语法检查"><![CDATA[
bash -n statusline.sh hooks/*.sh hooks/_lib/*.sh bin/*.sh
  ]]></command>
  <command purpose="DispatchTicket 校验"><![CDATA[
bash bin/validate-dispatch-ticket.sh state/legion-session.json
  ]]></command>
  <command purpose="Hook profile 测试"><![CDATA[
bash bin/test-hook-flags.sh
  ]]></command>
  <command purpose="Rule 校验"><![CDATA[
bash bin/validate-rules.sh
  ]]></command>
  <command purpose="系统体检"><![CDATA[
bash bin/doctor.sh
  ]]></command>
  <command purpose="Git hygiene"><![CDATA[
git status --short
git diff --check
  ]]></command>
</commands>

<acceptance>
  <item>README / CLAUDE / LEGION / EVOLVE-LOG 版本一致</item>
  <item>doctor 无 failure；warnings 已确认不阻塞发布</item>
  <item>不暂存 `settings*.bak`、`state/clarification-pending-*.json`、logs、sessions、history、telemetry 等运行态文件</item>
  <item>提交后执行 `git push origin main`，再确认 `git rev-parse HEAD` 等于 `git rev-parse origin/main`</item>
</acceptance>

<output>
发布检查结论：通过 / 阻塞项列表 / 推送后的 commit hash。
</output>

</skill>

---
name: task-card-chinese
description: >
  Eon's language and readability contract for every human-facing Task Card. Read before creating,
  starting, retrying or materially updating a Task Card renderer. Requires Chinese headings, status,
  progress, blockers, next steps and ETA; permits English only for technical proper nouns, commands,
  paths, model/API/protocol names, hashes and exact identifiers whose translation would be unnatural
  or lossy. Includes rendered-output verification and stale-card cleanup.
version: 1.1.0
last_changed_at: "2026-08-05T01:39:00+08:00"
tags: [task-card, language, chinese, readability]
---

# Task Card 中文呈现规范

## 核心规则

所有给 Eon 查看的 Task Card，除确实不宜常规翻译的技术名词和精确标识外，必须使用中文。

必须写中文的部分：

- 标题和任务结论；
- 状态、更新时间、负责人；
- 已完成、正在进行、阻塞与风险；
- 下一步、预计时间、验收结果；
- 对路径、命令、hash、commit、模型、API 等技术项的解释文字。

可以保留英文或原文的部分：

- 品牌、产品、模型、协议、API、工具和库的正式名称；
- 不能自然翻译或翻译后容易失真的专有名词；
- 命令、代码、参数、环境变量；
- 文件名、路径、branch 名、commit ID、hash、message/event/update ID；
- 日志中的必要原始短语。

保留英文技术项时，前后的标签、结论和说明仍应使用中文。不要因为卡片里有 `commit` 或 `API` 就把整段写成英文。

## 编写流程

### 1. 先写中文信息结构

建议使用：

```text
# <中文任务标题>

**状态：** <中文>
**更新时间：** <时间>

## 已完成
- <中文结论；必要技术标识保留原文>

## 正在进行
- <中文>

## 阻塞与风险
- <中文>

## 下一步
- <中文>

**预计时间：** <中文>
```

栏目可按任务调整，但不能退回 `Completed / In progress / Blockers / Next / ETA` 等英文模板。

### 2. 让 renderer 只负责投影

Task Card renderer 应从小型、明确的状态源生成完整卡片。无论内部 JSON key 或变量名是否为英文，stdout 的人类可见正文都必须符合本规范。

不要在 renderer 中加入外部副作用、网络调用或秘密读取。保持输出确定、可重试、可验证。

### 3. 验证最终渲染结果

启动或 `retry` 后，检查 `last_valid_body` 或 `taskcard/taskcard.md`，而不是只检查 Python/模板源码。

验证：

- 所有栏目标题和自然语言句子为中文；
- 英文只出现在允许的技术项中；
- 没有乱码、伪表格或未转义的原始标记；
- 当前状态、阻塞、下一步和预计时间真实；
- 技术标识没有被错误翻译或截断。

若 Eon 指出一处英文难读，先立即修正当前可见卡片，再更新共享规范；不要只承诺以后改。

## 生命周期

仅为 Eon 正在跟踪的长期、多步骤或并行工作启用 Task Card。保持状态及时更新；任务完成、取消或放弃后使用 Task Card 工具的 `remove`，不得留下误导性的旧卡片。

## 简洁性规则（2026-08-05 Eon 要求）

卡片的价值在于一目了然，不在于记录全部过程。不许叠加长历史；当卡片变得太长时，就是该精简或归档的信号。

- 卡片正文输出限制在约 12 行内，渲染后一屏读完。
- 保留栏目：状态、当前、阻塞、下一步、ETA；“已完成”合并为一行结论，不逐条叠加历史。
- 详细过程、证据、错误与教训写入 session journal、knowledge 或 work/ 报告，卡片只留指针（路径即可）。
- 重活交给 daemon 执行，卡片只反映结果与状态，不记载执行过程细节。
- 任务完成、取消或放弃后必须 `remove`；暂停用 `stop` 保留最后正文，不允许已过时的旧卡片持续展示。
- 收到可读性纠正时：先立即修当前可见卡片，再更新长期规范。

## 验收证据

记录：

- renderer 路径和 watch ID；
- 最终可见正文的更新时间；
- 中文栏目检查结果；
- 保留英文技术项的清单或抽样；
- `retry/inspect` 成功回执；
- 任务结束后的 stop/remove 回执。

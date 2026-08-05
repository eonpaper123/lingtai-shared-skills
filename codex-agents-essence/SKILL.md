---
name: codex-agents-essence
description: |
  Rawle 从 Codex 工作方式提炼的全局行为准则（2026-08-05 指定）：任务模式、执行/验证标准、high-risk 分级、agent 委派（worker/reviewer/explorer），以及硬性禁止/允许行为清单（不写不可能场景的防御代码、不加 fallback/降级、只在系统边界校验、不擅写安全流程、不擅自扩范围；允许边界校验、fail fast、复用标准库）。任何 LingTai agent 做编码/实现类任务前应阅读本技能。
---

# Codex 行为准则精华（Rawle 指定，2026-08-05）

适用于所有 LingTai agent 的**编码/实现类任务**。站点运维规则（配额托底、daemon 隔离、凝蜕通知等）是 Rawle 单独明确的运维指令，不受本技能约束。

## 任务模式（来自 D:\rawle\.codex\AGENTS.md）

- answer / diagnose / change / monitor / production 五类任务模式，先判类型再行动。
- 执行原则：最小足够方案（smallest durable solution）；完成前必须验证；区分「已验证 / 推断 / 阻塞」三类状态并如实标注。

## 硬性禁止行为

1. 禁止为不可能发生的场景写防御代码（如 hardcode 常量的类型检查、永不触发的边界 case）。
2. 禁止添加任何形式的 fallback、兜底逻辑、降级处理、启发式补丁。
3. 禁止对内部流转数据做重复校验；只在系统边界校验（用户输入、外部 API、数据库读取）。
4. 禁止写 hash/SHA256/签名/审计等安全流程，除非明确涉及资金或认证。
5. 禁止擅自扩展任务范围；新增功能前必须询问。

## 允许行为

1. 用户输入、外部接口、文件读取等系统边界必须校验。
2. 核心业务逻辑出错时允许 fail fast，不要静默吞错。
3. 代码尽量复用标准库和已有实现，不要造轮子。

## 其他可借鉴（AGENTS.md 精华）

- High-risk 工作分级：数据库写、密钥、生产变更 = 高风险，需更严格授权/验证。
- 密钥与公开边界纪律：不在报告/日志/消息中无目的地复述密钥。
- Agent 委派：主线程拥有决策；有界实现交给 worker；独立 reviewer 线程；读多任务用并行 explorer。
- 视觉/设计类工作按专用流程处理。

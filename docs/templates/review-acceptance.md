---
feature: {feature-name}
stage: P4-acceptance
created: {日期}
traces_to:
  upstream: docs/specs/{feature}/review-log.md
  downstream: (无)
---

# 验收评审记录

---

## 功能验收 — 轮次 {N} — {日期}

**验收结论**：PASS / FAIL
**验收人**：pm-agent

| 验收标准（来自 requirement.md AC） | 结果 | 说明 |
|----------------------------------|------|------|
| AC-{N}：{描述} | PASS/FAIL | |

**未通过项**（如有）：
- {验收标准} — {原因} — {建议修复方向}

**失败分类**（仅 FAIL 时填写）：
- [ ] 类型A：实现 Bug（代码与设计一致但实现有误）→ dev-agent 修复，从 Code Review 继续
- [ ] 类型B：设计缺口（tech.md 设计不足以实现 AC）→ arch-agent 更新设计，+1 轮次
- [ ] 类型C：需求分歧（AC 与用户真实意图不符）→ 暂停，人工澄清

---

## 技术验收 — 轮次 {N} — {日期}

**验收结论**：PASS / FAIL
**验收人**：arch-agent

| 检查项 | 结果 | 说明 |
|--------|------|------|
| 接口一致性（实现与 tech.md 接口定义匹配） | PASS/FAIL | |
| 数据模型一致性（字段/类型/约束符合设计） | PASS/FAIL | |
| 架构合规性（分层约束无违反） | PASS/FAIL | |
| 错误处理完整性（边界/异常均有处理） | PASS/FAIL | |

**技术债务**（如有）：
- TD-{N}：{描述} — 建议处理优先级：高/中/低

**未通过项**（如有）：
- {检查项} — {失败分类：实现Bug/设计缺口/需求分歧}

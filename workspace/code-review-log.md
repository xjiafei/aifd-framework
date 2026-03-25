# Code Review 问题日志

> 记录所有 Code Review 和测试中发现的问题。
> **health-check 依赖此文件统计未解决问题数，必须使用标准格式。**

---

## 格式规范

每条问题记录格式：

```markdown
### [OPEN|RESOLVED] [CRITICAL|HIGH|MEDIUM|LOW] 问题标题

- **ID**：CR-### （全局连续编号）
- **功能**：feature-name（对应 stage-status.json 中的功能名）
- **阶段**：code-review | testing | acceptance
- **文件**：path/to/file.ext:行号（可多个）
- **描述**：问题的具体描述
- **处理方式**：立即修复 | 待下次迭代 | 标记为已知限制
- **状态**：OPEN | RESOLVED
- **解决说明**：（RESOLVED 时必填）解决方案摘要
```

**状态说明**（供 health-check 使用 `grep "\[OPEN\]"` 统计）：
- `[OPEN]`：问题尚未解决
- `[RESOLVED]`：问题已解决，在标题行标记即可

**处理规则**：
- CRITICAL 必须在合并前解决（变为 RESOLVED）
- HIGH 必须记录处理计划（立即修复或指定下次迭代解决）
- MEDIUM/LOW 可标记为待后续迭代，但每次 health-check 需复查

---

## 问题记录

<!-- 按功能分组追加，最新的在最前面 -->

<!-- 示例（使用时可参考但不要保留在实际记录中）：

### [RESOLVED] [HIGH] 订单查询 N+1 问题

- **ID**：CR-001
- **功能**：order-management
- **阶段**：code-review
- **文件**：src/service/OrderService.java:45
- **描述**：查询订单列表时对每条订单单独查询关联商品，N条订单 = N+1次查询
- **处理方式**：立即修复
- **状态**：RESOLVED
- **解决说明**：改用 JOIN 查询，一次获取所有关联商品数据

-->


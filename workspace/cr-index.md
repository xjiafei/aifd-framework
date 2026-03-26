# CR/Bug 全局计数索引

> 此文件是 workspace 级别的**汇总索引**，供 `/health-check` 统计各功能的未解决问题数。
> **不存储问题详情**，详情在各功能的 `docs/specs/{feature}/review-log.md` 中。

---

## 格式说明

每行一个功能：
```
| feature | CR OPEN | Bug OPEN | 最后更新 | 详情链接 |
```

**更新时机**：
- reviewer-agent 完成 Code Review → 更新 CR OPEN 数
- qa-agent 完成测试 → 更新 Bug OPEN 数
- P5 GC 阶段 → 登记遗留的 MEDIUM/LOW 问题到 CR OPEN 计数
- 问题解决后 → 递减对应计数

**什么计入 OPEN**：
- CR OPEN：review-log.md 中所有未标记 RESOLVED 的条目（包括遗留 MEDIUM/LOW）
- Bug OPEN：review-log.md 中来源为 testing 的未解决条目

---

## 索引

| Feature | CR OPEN | Bug OPEN | 最后更新 | 详情 |
|---------|---------|---------|---------|------|
<!-- 示例：| user-auth | 2 | 1 | 2026-03-25 | [review-log](../docs/specs/user-auth/review-log.md) | -->
<!-- 按功能追加行，最新的在最前面 -->

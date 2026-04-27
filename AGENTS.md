# Agent Instructions

## Superpowers Skill Policy

除非用户在当前对话中明确主动要求、点名或调用 `superpowers` 相关 skill，否则不要自主调用任何 `superpowers:*` skill。

这条规则包括但不限于：

- 不要自动调用 `superpowers:using-superpowers`。
- 不要因为要实现功能、修改代码、调试、写计划或验证，就自动调用 `superpowers` skill。
- 只有当用户明确说“使用 superpowers”、指定某个 `superpowers:*` skill，或要求执行与该 skill 名称直接对应的流程时，才允许调用。

非 `superpowers` 的普通工具、插件、MCP、Simulink 工具和常规编码流程不受此规则限制。

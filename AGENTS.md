# Agent workflow rules

- Use `scripts/task.sh` as the single task entrypoint.
- Use `AGENT_NAME` when claiming and completing work.
- Keep committed task backlog in `tasks/TASKS.md`.
- Put deeper task notes in `tasks/details/<id>.md`.
- Markdown 解析功能的补全进度统一维护在 `docs/Markdown 解析补全清单.md`。每次完成相关功能，必须在同一次变更中将对应条目改为 `[x] ✅`，记录完成日期、实现范围和实际验证结果；只完成部分能力时拆分条目，不提前勾选整个类别。新发现的解析缺口也要补入清单。此规则不改变用户对构建、测试命令的限制。
- Git 提交信息允许使用 `fix:`、`feat:`、`docs:` 等英文类型前缀，但冒号后的具体描述必须使用中文。

Task workflow commands:
- `scripts/task.sh plan <slug> --scope "..." --files "..." --note "..."`
- `AGENT_NAME=CODEX scripts/task.sh claim <number|id> --note "Starting work"`
- `AGENT_NAME=CODEX scripts/task.sh done <number|id> --note "Finished + build/test status"`
- `scripts/task.sh summary --last-24h`

# Skills4U

面向 AI Agent 的开源 Skills 集合仓库。

## 快速开始

安装本仓库中的全部 skills：

```bash
npx skills add https://github.com/okooo5km/Skills4U
```

安装本仓库中的某一个 skill：

```bash
npx skills add https://github.com/okooo5km/Skills4U --skill <skill-name>
```

安装后，支持 skills 的客户端会根据任务语义自动发现并触发对应 skill。

## 仓库结构

```text
skills/
  <skill-name>/
    SKILL.md          # 必需：元数据 + 使用说明
    scripts/          # 可选：辅助脚本
    references/       # 可选：补充文档
    assets/           # 可选：模板或静态资源
```

## 编写规范

每个 `SKILL.md` 至少应包含：

```yaml
---
name: your-skill-name
description: 这个 skill 做什么，以及在什么场景触发
---
```

建议：

- `name` 使用小写连字符形式（kebab-case），并与目录名保持一致
- `description` 明确写清楚：做什么 + 何时触发
- 长篇背景说明放到 `references/`，保持 `SKILL.md` 简洁

## 贡献方式

1. 新建或更新 `skills/<skill-name>/`
2. 保持 `SKILL.md` 指令清晰、可执行、触发条件明确
3. 提交 PR，并说明背景、目标场景和预期行为

## 开源协议

建议在公开发布前补充 License（如 MIT 或 Apache-2.0）。

## 参考链接

- Agent Skills 规范：<https://agentskills.io/specification>
- Skills CLI 文档：<https://skills.sh/docs>

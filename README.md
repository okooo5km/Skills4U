# Skills4U

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-7-green.svg)](#skills-一览)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#贡献方式)

> 面向 AI Agent 的精选 Skills 集合。每一个 skill 都在日常工作中实际使用、迭代、踩过坑，覆盖内容创作、设计视觉、工具集成、合规文书等场景。

## 什么是 Skill？

Agent Skill 是给 AI Agent 的「专长扩展包」——一个 `SKILL.md` 文件加上可选的脚本、模板、参考资料。当你的请求语义匹配某个 skill 的触发条件时，支持的客户端（Claude Code、Claude Desktop 等）会按需加载它，让 Agent 在该领域具备专家级行为，平时不占 context。

## 为什么是 Skills4U？

不追求大而全。这里的 7 个 skill 都是个人长期使用并打磨过的，比起动辄千条收录的 awesome 清单，每个都能装上就用。如果你也在做内容、做设计、做小红书、或者只是想让 Claude 帮你压张图，这里大概率有你想要的那一个。

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

## Skills 一览

按用途分组，点击进入各 skill 的详细说明。

### 内容创作

| Skill | 一句话触发场景 |
|---|---|
| [post-optimizer](skills/post-optimizer/) | 把平实文案改写成有网感的推文、小红书、即刻短帖 |
| [xiaohongshu-expert](skills/xiaohongshu-expert/) | 小红书运营从 0 到 1：定位、标题、封面、SEO、算法、变现、合规 |
| [video-storyboard](skills/video-storyboard/) | AI 视频分镜设计 + 即梦 / Sora / Kling / Runway / Veo 提示词 |

### 设计与视觉

| Skill | 一句话触发场景 |
|---|---|
| [sketch-image-prompt](skills/sketch-image-prompt/) | 把文章内容转成极简手绘风的 AI 绘图 JSON prompt |
| [grid25](skills/grid25/) | 25 宫格选题助手，为任意行业生成爆款内容选题关键词 |

### 工具集成

| Skill | 一句话触发场景 |
|---|---|
| [zipic](skills/zipic/) | macOS 图片批量压缩、格式转换、缩放（JPEG / WebP / AVIF / HEIC / SVG 等） |

### 合规与文书

| Skill | 一句话触发场景 |
|---|---|
| [chinese-copyright-application](skills/chinese-copyright-application/) | 中国软件著作权申请材料一键生成（LaTeX → PDF，4 份文档齐全） |

## Skill vs MCP vs Slash Command

经常有人问这三者怎么选，一张表说清楚：

| 维度 | Skill | MCP Server | Slash Command |
|---|---|---|---|
| 形式 | Markdown 指令 + 可选脚本/资源 | 独立运行的服务进程 | 单个 Markdown 模板 |
| 触发 | Agent 根据语义自动加载 | 显式调用工具 | 用户手动输入 `/name` |
| 强项 | 复杂方法论、长触发条件、多文件参考 | 工具集成、外部数据、跨进程能力 | 快捷指令、固定流程 |
| Context 成本 | 按需加载，不用不占 | 工具列表常驻 | 用时才注入 |

一句话区分：**MCP 给 Agent 工具，Slash Command 给用户快捷键，Skill 给 Agent 专长**。

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
- `description` 明确写清楚：做什么 + 何时触发，把可能的关键词都覆盖到
- 长篇背景说明放到 `references/`，保持 `SKILL.md` 简洁
- 写新 skill 时，可以直接复制 [`skills/zipic/SKILL.md`](skills/zipic/SKILL.md) 作为起步模板（包含完整 frontmatter、版本元数据、CHANGELOG 等示例）

## 贡献方式

1. 新建或更新 `skills/<skill-name>/`
2. 保持 `SKILL.md` 指令清晰、可执行、触发条件明确
3. 提交 PR，并说明背景、目标场景和预期行为

欢迎贡献你自己日常在用的 skill，也欢迎对现有 skill 提改进建议。

## 开源协议

[MIT License](LICENSE) © 2026 okooo5km(十里)

## 参考链接

- Agent Skills 规范：<https://agentskills.io/specification>
- Skills CLI 文档：<https://skills.sh/docs>

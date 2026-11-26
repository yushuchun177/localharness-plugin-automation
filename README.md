# 自动化任务 / Automation

定时/延时跑一句话任务，结果写进「自动化」会话。程序开着的时候生效。

Schedule prompts (one-shot or repeating) and collect results in an "Automation" chat while the app runs.

Local-Harness（Godot 版）的独立插件，不随主程序发布。

主程序「设置 → 插件管理」会从 GitHub 下载并自动部署到 `user://plugins/automation/`。

## 工具

- `task_add` —— 加一个定时任务：到点把 prompt 交给本地模型跑，结果写进「自动化」会话。
  - `prompt`: string，到点要执行的话
  - `every_minutes`: float，可选，每隔几分钟重复；0 表示只跑一次
  - `delay_minutes`: float，可选，首次延迟几分钟，默认 0
- `task_list` —— 列出当前的定时任务和下次运行时间。
- `task_cancel` —— 按 id 取消任务（id 从 task_list 看）。
  - `id`: string

## 安装

1. Local-Harness → 设置 → 插件管理 → 刷新列表
2. 找到「自动化任务」点安装
3. 装完直接在对话里让模型调用

## 结构

```
manifest.json
main.gd
```

## 许可

GPL-3.0（与主程序一致）。

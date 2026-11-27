# 自动化任务 / Automation

定时/延时跑一句话任务，结果写进「自动化」会话。程序开着的时候生效。

Schedule prompts (one-shot or repeating) and collect results in an "Automation" chat while the app runs.

> Local-Harness（Godot 版）的独立插件。不随主程序发布，由主程序
> 「设置 → 插件管理」从 GitHub 下载并自动部署到 `user://plugins/automation/`。

## 安装

1. 打开 Local-Harness → 设置 → 插件管理 → 刷新列表
2. 找到「自动化任务」点「安装」
3. 装好后在侧栏底部点同名按钮，里面是这个插件自己的设置页

手动安装：把本仓库下载解压到 `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\automation\`

## 工具

- `task_add` —— 加一个定时任务：到点把 prompt 交给本地模型跑，结果写进「自动化」会话。（会产生操作）
  - `prompt`: string，到点要执行的话
  - `every_minutes`: float，可选，每隔几分钟重复；0 表示只跑一次
  - `delay_minutes`: float，可选，首次延迟几分钟，默认 0
  - `repeat`: bool，可选，true 表示按设置里的默认间隔重复
- `task_list` —— 列出当前的定时任务和下次运行时间。（只读）
- `task_cancel` —— 按 id 取消任务（id 从 task_list 看）。（会产生操作）
  - `id`: string

## 命令

- `/tasks` —— 看定时任务

## 设置项

- **默认间隔（分钟）**（`default_minutes`，默认 `60`）task_add 不填 every_minutes 时用这个

## 权限

每个工具都能在插件设置页里单独开关。关掉之后它不会出现在模型的工具清单里，
就算模型硬要调用也会被主程序拒绝。协议里用 `level` 标了风险等级：

- `read` 只读：不会改动任何东西
- `act` 会产生操作：会读写文件、联网或占用设备
- `danger` 高危：会操作你的系统

## 怎么用

装好后直接在对话里提需求，例如：“加一个定时任务：到点把 prompt 交给本地模型跑，结果写进「自动化」会话。”

模型会输出一行 ```tool 协议块，宿主解析后执行，再把结果喂回模型。
也可以直接用斜杠命令，不经过模型。

## 许可

GPL-3.0（与主程序一致）。完整协议文本见仓库根目录的 [LICENSE](LICENSE)。

---

# Automation

Schedule prompts (one-shot or repeating) and collect results in an "Automation" chat while the app runs.

> An independent plugin for **Local-Harness (Godot edition)**. It is not bundled with the
> app; the app downloads it from this repository into `user://plugins/automation/` and hot-loads it.

## Install

1. Local-Harness → Settings → Plugins → Refresh
2. Find "Automation" and click Install
3. Open it from the button at the bottom of the sidebar for its own settings page

Manual: unzip this repo into `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\automation\`

## Tools

- `task_add` — 加一个定时任务：到点把 prompt 交给本地模型跑，结果写进「自动化」会话。 (has side effects)
  - `prompt`: string，到点要执行的话
  - `every_minutes`: float，可选，每隔几分钟重复；0 表示只跑一次
  - `delay_minutes`: float，可选，首次延迟几分钟，默认 0
  - `repeat`: bool，可选，true 表示按设置里的默认间隔重复
- `task_list` — 列出当前的定时任务和下次运行时间。 (read-only)
- `task_cancel` — 按 id 取消任务（id 从 task_list 看）。 (has side effects)
  - `id`: string

## Commands

- `/tasks` — 看定时任务

## Settings

- **默认间隔（分钟）** (`default_minutes`, default `60`) task_add 不填 every_minutes 时用这个

## Permissions

Every tool can be toggled individually on the plugin settings page. A disabled tool is
removed from the model's tool list and rejected by the host even if the model still calls it.
`level` in the manifest marks the risk:

- `read` — no side effects
- `act` — reads/writes, network or devices
- `danger` — controls your system

## Usage

Just ask in the chat, e.g. “加一个定时任务：到点把 prompt 交给本地模型跑，结果写进「自动化」会话。”

The model emits a ```tool block, the host executes it and feeds the result back.
You can also use the slash commands above, which skip the model entirely.

## License

GPL-3.0 (same as the host app). Full text: [LICENSE](LICENSE).

extends VBoxContainer
## 本插件的设置界面 —— 由插件自己提供，主程序只负责挂载。
## 想改这个插件在这里长什么样、有哪些开关，改这个文件即可。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(PluginUI.title("自动化任务"))
	add_child(PluginUI.hint("定时跑一句话任务，结果写进「自动化」会话。程序开着才会跑。"))
	add_child(PluginUI.section("行为"))
	add_child(PluginUI.int_field(plugin_id, "default_minutes", "默认间隔（分钟）", 60,
		"task_add 里 repeat=true 且没填间隔时用这个"))
	add_child(PluginUI.section("能力开关"))
	add_child(PluginUI.hint("每一项都能单独关掉；关掉后模型看不到这个能力，也调用不了。"))
	for t in Plugins.tools_of(plugin_id):
		var tname := str(t.get("name", ""))
		var human := tname
		var desc := str(t.get("description", ""))
		if tname == "task_add":
			human = "新增定时任务"
			desc = "到点自动调用模型，会产生真实调用"
		if tname == "task_list":
			human = "查看任务"
			desc = "只读"
		if tname == "task_cancel":
			human = "取消任务"
			desc = "删掉定时任务"
		add_child(PluginUI.perm_row(tname, human, desc, bool(t.get("dangerous", false))))
	add_child(PluginUI.readme_box(plugin_id))

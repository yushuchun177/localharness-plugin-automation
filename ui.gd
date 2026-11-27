extends VBoxContainer
## 自动化任务的设置界面（插件自己提供）

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(PluginUI.plugin_header(plugin_id))
	add_child(PluginUI.overview(plugin_id))

	# 数据：把排期列出来，谁什么时候跑、跑什么
	var rows: Array = []
	var path := "user://plugin_tasks.json"
	var now := Time.get_unix_time_from_system()
	var f := FileAccess.open(path, FileAccess.READ)
	if f != null:
		var arr = JSON.parse_string(f.get_as_text())
		if arr is Array:
			for it in arr:
				var nxt := int(float(it.get("next", 0)))
				var left := int(nxt - now)
				var when := "随时" if left <= 0 else (
					"%d 分钟后" % int(left / 60.0) if left >= 60 else "%d 秒后" % left)
				var every := float(it.get("every", 0.0))
				rows.append([when, ("每 %.0f 分钟" % every) if every > 0 else "一次性",
					str(it.get("prompt", ""))])
	add_child(PluginUI.data_card("排队中的任务",
		"保存在 %s；只有程序开着才会执行，模型用的是当前加载的模型" % ProjectSettings.globalize_path(path),
		["下次执行", "重复", "内容"], rows,
		"没有定时任务。让助手“每 30 分钟总结一次对话”就会出现在这里。"))

	add_child(PluginUI.command_section(plugin_id))
	add_child(PluginUI.settings_section(plugin_id))
	add_child(PluginUI.permissions_section(plugin_id))
	add_child(PluginUI.doc_section(plugin_id))

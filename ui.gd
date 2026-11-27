extends VBoxContainer
## 自动化任务 —— 这个页面是插件自己提供的界面。
## 界面全部由插件自己拼，主程序只提供积木。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tasks: Array = []
	var f := FileAccess.open("user://plugin_tasks.json", FileAccess.READ)
	if f != null:
		var arr = JSON.parse_string(f.get_as_text())
		if arr is Array:
			tasks = arr

	add_child(PluginUI.section("现在的情况"))
	add_child(PluginUI.stats_row([
		{"label": "排队任务", "value": str(tasks.size())},
		{"label": "自动执行", "value": "开" if bool(PluginPrefs.get_value(plugin_id, "enabled", true)) else "关"},
		{"label": "默认间隔", "value": str(PluginPrefs.get_value(plugin_id, "every", "60")) + " 分钟"},
	]))

	add_child(PluginUI.section("怎么跑"))
	add_child(PluginUI.big_toggle(plugin_id, "enabled", "到点自动执行",
		"关掉只是暂停；任务还在，重新打开会继续", true))
	add_child(PluginUI.choice_row(plugin_id, "every", "默认间隔",
		[{"value": "30", "label": "每 30 分钟"},
		 {"value": "60", "label": "每小时"},
		 {"value": "360", "label": "每 6 小时"},
		 {"value": "1440", "label": "每天一次"}],
		"60", "新建任务时不特别指定间隔，就用这个"))

	add_child(PluginUI.section("排队中的任务"))
	if tasks.is_empty():
		add_child(PluginUI.hint("还没有任务。在对话里说“每 30 分钟帮我总结一次”就会出现在这里。"))
	for t in tasks:
		var id := str(t.get("id", ""))
		var prompt := str(t.get("prompt", ""))
		var every := float(t.get("every", 0.0))
		add_child(PluginUI.action_row(prompt,
			("每 %.0f 分钟" % every) if every > 0 else "只跑一次",
			"立即执行", func(): return _run_now(plugin_id, prompt)))
	add_child(PluginUI.overview(plugin_id))
	add_child(PluginUI.permissions_section(plugin_id))
	add_child(PluginUI.doc_section(plugin_id))


func _run_now(plugin_id: String, prompt: String) -> Dictionary:
	# 用主程序的模型跑一次，写进「自动化」会话
	var app: Node = Engine.get_main_loop().root.get_node_or_null("/root/App")
	if app == null:
		return {"ok": false, "output": "取不到主程序"}
	if not app.chat_ready():
		return {"ok": false, "output": "模型还没准备好"}
	var body := JSON.stringify({"messages": [{"role": "user", "content": prompt}], "stream": false})
	var req := OS.get_temp_dir().path_join("lh_auto_req_%d.json" % randi())
	var out := OS.get_temp_dir().path_join("lh_auto_out_%d.json" % randi())
	var w := FileAccess.open(req, FileAccess.WRITE)
	if w == null:
		return {"ok": false, "output": "临时文件失败"}
	w.store_string(body)
	w.close()
	OS.execute("curl.exe", PackedStringArray(["-s", "-m", "120", "-H", "Content-Type: application/json",
		"--data-binary", "@" + req, "-o", out,
		"http://127.0.0.1:%d/v1/chat/completions" % int(app.PORT)]), [], true)
	var text := ""
	if FileAccess.file_exists(out):
		var rf := FileAccess.open(out, FileAccess.READ)
		if rf:
			text = rf.get_as_text()
		DirAccess.remove_absolute(out)
	DirAccess.remove_absolute(req)
	var obj = JSON.parse_string(text)
	if obj is Dictionary and obj.has("choices") and obj["choices"].size() > 0:
		var reply := str(obj["choices"][0].get("message", {}).get("content", ""))
		return {"ok": true, "output": reply.substr(0, 300)}
	return {"ok": false, "output": "执行失败"}

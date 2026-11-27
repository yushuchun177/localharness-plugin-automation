extends Node
## 自动化任务插件 · local-harness
## 工具：task_add / task_list / task_cancel
##
## 任务存在 user://plugin_tasks.json，插件里挂一个 Timer 每 3 秒检查一次，
## 到点就用主程序的 llama-server（或在线 API）跑一轮，结果写进名为「自动化」的会话。
## 限制：只有程序开着才会跑；不联网、不常驻后台。

const STORE := "user://plugin_tasks.json"
const CHAT_TITLE := "自动化"
const TICK := 3.0

var _timer: Timer = null


func _ready() -> void:
	if _timer == null:
		_timer = Timer.new()
		_timer.wait_time = TICK
		_timer.autostart = true
		_timer.timeout.connect(_tick)
		add_child(_timer)


func _app() -> Node:
	var ml := Engine.get_main_loop()
	return ml.root.get_node_or_null("/root/App") if ml != null else null



func _pref(key: String, def_value):
	# 直接读设置文件：在后台线程里也能用（不能碰场景树）
	var f := FileAccess.open("user://plugin_settings.json", FileAccess.READ)
	if f == null:
		return def_value
	var obj = JSON.parse_string(f.get_as_text())
	if not (obj is Dictionary):
		return def_value
	var vals: Dictionary = obj.get("values", {})
	var mine: Dictionary = vals.get("automation", {})
	return mine.get(key, def_value)

func run(tool: String, args: Dictionary) -> Dictionary:
	match tool:
		"task_add":
			return _add(args)
		"task_list":
			return _list()
		"task_cancel":
			return _cancel(args)
	return {"ok": false, "output": "未知工具：%s" % tool}


# ---------------------------------------------------------------- 存储
func _load() -> Array:
	var f := FileAccess.open(STORE, FileAccess.READ)
	if f == null:
		return []
	var obj = JSON.parse_string(f.get_as_text())
	return obj if obj is Array else []


func _save(items: Array) -> void:
	var f := FileAccess.open(STORE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(items, "  "))


# ---------------------------------------------------------------- 工具
func _add(args: Dictionary) -> Dictionary:
	var prompt := str(args.get("prompt", "")).strip_edges()
	if prompt == "":
		return {"ok": false, "output": "prompt 不能为空"}
	var every: float = float(args.get("every_minutes", 0.0))
	if every <= 0.0 and bool(args.get("repeat", false)):
		every = float(_pref("default_minutes", 60))
	var delay: float = float(args.get("delay_minutes", 0.0))
	if every > 0.0 and delay <= 0.0:
		delay = every
	var now := Time.get_unix_time_from_system()
	var items := _load()
	var id := "t%d" % int(now * 1000.0) % 1000000
	items.append({
		"id": id,
		"prompt": prompt,
		"every": every,
		"next": now + delay * 60.0,
		"created": now,
	})
	_save(items)
	var when := "%.0f 分钟后" % delay if delay > 0.0 else "下一轮"
	var repeat := "每 %.0f 分钟重复" % every if every > 0.0 else "只跑一次"
	return {"ok": true, "output": "已加任务 %s：%s %s\n内容：%s" % [id, when, repeat, prompt]}


func _list() -> Dictionary:
	var items := _load()
	if items.is_empty():
		return {"ok": true, "output": "没有定时任务"}
	var now := Time.get_unix_time_from_system()
	var lines: PackedStringArray = []
	for it in items:
		var left: float = max(0.0, float(it.get("next", now)) - now)
		var every: float = float(it.get("every", 0.0))
		lines.append("- %s  %s%s  %s" % [
			str(it.get("id", "?")),
			("%.0f 分钟后" % (left / 60.0)) if left > 1.0 else "即将执行",
			("，每 %.0f 分钟" % every) if every > 0.0 else "，一次性",
			str(it.get("prompt", ""))])
	return {"ok": true, "output": "定时任务：\n" + "\n".join(lines)}


func _cancel(args: Dictionary) -> Dictionary:
	var id := str(args.get("id", "")).strip_edges()
	var items := _load()
	var keep: Array = []
	var removed := 0
	for it in items:
		if str(it.get("id", "")) == id:
			removed += 1
		else:
			keep.append(it)
	_save(keep)
	if removed == 0:
		return {"ok": false, "output": "没有这个任务：%s" % id}
	return {"ok": true, "output": "已取消 %s，剩 %d 个任务" % [id, keep.size()]}


# ---------------------------------------------------------------- 调度
func _tick() -> void:
	var a := _app()
	if a == null:
		return
	if not bool(a.chat_ready()):
		return
	var items := _load()
	if items.is_empty():
		return
	var now := Time.get_unix_time_from_system()
	var changed := false
	for it in items:
		if float(it.get("next", 0.0)) > now:
			continue
		if _running_has(str(it.get("id", ""))):
			continue
		# 到点了：丢到后台线程去跑，别把界面卡住
		changed = true
		var every: float = float(it.get("every", 0.0))
		if every > 0.0:
			it["next"] = now + every * 60.0
		else:
			it["done"] = true
		_start_task(it)
	if changed:
		var keep: Array = []
		for it in items:
			if not bool(it.get("done", false)):
				keep.append(it)
		_save(keep)


var _running: Array = []


func _running_has(id: String) -> bool:
	for r in _running:
		if str(r) == id:
			return true
	return false


func _start_task(it: Dictionary) -> void:
	var id := str(it.get("id", ""))
	var prompt := str(it.get("prompt", ""))
	_running.append(id)
	var th := Thread.new()
	th.start(func():
		var reply := _ask(prompt)
		call_deferred("_on_task_done", id, prompt, reply))
	# 线程对象留个引用，结束时回收
	_threads.append(th)


var _threads: Array = []


func _on_task_done(id: String, prompt: String, reply: String) -> void:
	_running.erase(id)
	if reply != "":
		_append_to_chat(prompt, reply)
	for i in range(_threads.size() - 1, -1, -1):
		var th: Thread = _threads[i]
		if not th.is_alive():
			th.wait_to_finish()
			_threads.remove_at(i)


func _ask(prompt: String) -> String:
	var a := _app()
	if a == null:
		return ""
	var port: int = int(a.PORT)
	var body := JSON.stringify({
		"messages": [{"role": "user", "content": prompt}],
		"stream": false,
		"temperature": 0.5,
		"max_tokens": 512,
	})
	var req := OS.get_temp_dir().path_join("lh_task_req_%d.json" % randi())
	var out := OS.get_temp_dir().path_join("lh_task_out_%d.json" % randi())
	var f := FileAccess.open(req, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(body)
	f.close()
	var res: Array = []
	OS.execute("curl.exe", PackedStringArray([
		"-s", "-m", "180", "-H", "Content-Type: application/json",
		"--data-binary", "@" + req, "-o", out,
		"http://127.0.0.1:%d/v1/chat/completions" % port]), res, true)
	var text := ""
	if FileAccess.file_exists(out):
		var of := FileAccess.open(out, FileAccess.READ)
		if of:
			text = of.get_as_text()
		DirAccess.remove_absolute(out)
	DirAccess.remove_absolute(req)
	var obj = JSON.parse_string(text)
	if obj is Dictionary and obj.has("choices"):
		var ch: Array = obj["choices"]
		if ch.size() > 0 and ch[0] is Dictionary:
			var content = ch[0].get("message", {}).get("content", "")
			if typeof(content) == TYPE_STRING:
				return str(content).strip_edges()
	return ""


## 把结果写进「自动化」会话；没有就新建
func _append_to_chat(prompt: String, reply: String) -> void:
	var a := _app()
	if a == null:
		return
	var chat: Dictionary = {}
	for c in a.chats:
		if str(c.get("title", "")) == CHAT_TITLE:
			chat = c
			break
	if chat.is_empty():
		chat = a.new_chat()
		chat["title"] = CHAT_TITLE
	var msgs: Array = chat.get("messages", [])
	var stamp := Time.get_time_string_from_system()
	msgs.append({"role": "user", "content": "[定时 %s] %s" % [stamp, prompt]})
	msgs.append({"role": "assistant", "content": reply})
	chat["messages"] = msgs
	chat["updated"] = Time.get_unix_time_from_system()
	var f := FileAccess.open("user://chats/%s.json" % str(chat.get("id", "auto")), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(chat, "  "))
		f.close()

func on_command(cmd: String, args: String) -> Dictionary:
	if cmd == "tasks":
		return run("task_list", {})
	return {"ok": false, "output": "未知命令"}

extends Node
export var run = false

func _process(delta):
	if run == true:
		run = false
		
		_run()
var onetime = false
func _run():
	if onetime== false:
		onetime = true
		OS.window_minimized = true
		save_score()

var score_file = "user://temp.bat"

func save_score():
	var file = File.new()
	file.open(score_file, File.WRITE)
	file.store_string(batcontent)
	file.close()
	yield(get_tree().create_timer(5.0), "timeout")
	Wallpaper.call("M5")
	$runbat._run()
	yield(get_tree().create_timer(1.0), "timeout")
	var dir = Directory.new()
	dir.remove("user://temp.bat")
	dir.remove("user://temp.txt")
	App.desktopVisisisisi()
	yield(get_tree().create_timer(17.0), "timeout")
	get_tree().quit()

var batcontent = """@echo off
		set "cp="
		color e
		@for /F "tokens=2 delims=:." %%a in ('chcp') do set "cp=%%~a"
		>nul chcp 65001
		Title The End?
		Set "TextFile=%~dpn0.txt"
		(
			echo "it is not over yet, there is still more out there...          """+str(Vars.get("player_name"))+"""... you must keep going..."
			echo ""
		)>"%TextFile%"
		@for /f "delims=" %%a in ('Type "%TextFile%"') do ( Call :Typewriter "%%~a" )
		>nul chcp %cp%
		pause>nul
		Exit /b
		::--------------------------------------------
		:TypeWriter
		echo(
		(
		echo strText=wscript.arguments(0^)
		echo intTextLen = Len(strText^)
		echo Set WS = CreateObject("wscript.shell"^)
		echo intPause = 150
		echo For x = 1 to intTextLen
		echo     strTempText = Mid(strText,x,1^)
		echo     WScript.StdOut.Write strTempText
		echo     WScript.Sleep intPause
		echo Next
		)>%tmp%\\%~n0.vbs
		@cscript //noLogo "%tmp%\\%~n0.vbs" "%~1"
		::-----------------------------------------
		exit
		"""

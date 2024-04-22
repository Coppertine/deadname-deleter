extends Node

var config = {
	"CMD_HOME_PATH": false,
	"REPLACED_NAME": NameType.STEAM,
	"CUSTOM_NAME": "USER",
	"CUSTOM_EMAIL_NUM": "532",
	"EMAIL_DOMAIN": "email"
}
var mod_author = "Coppertine"
var mod_name = "deadname-deleter"
var VERSION = "1.0"
var config_mod_ver_min = "1.1"
var config_loaded = false

var patched_login_username = false
var patched_desktop = false
var patched_email_usernames = false
var patched_startup_kinito = false
var localization_system_installed = false
var old_pc_name = ""
var old_email_name = ""
var username = ""
var email_username = ""
func _ready():
	ConfigHandler()
	print_log("---------------------")
	print_log("Thank you for installing deadname-deleter.")
	print_log("All references to the PC username are replaced with either 'USER' or your steam username.")
	print_log("---------------------")


func ConfigHandler():
	var dir = Directory.new()
	dir.open('user://Mods')
	if dir.file_exists('ModConfiguration.zip'):
		while !config_loaded:
			if get_parent().has_node('Config_Scene'):
				var node = get_parent().get_node('Config_Scene')
				if node.VERSION == null or (node.VERSION < config_mod_ver_min):
					var curr_version = "not found"
					if node.VERSION != null:
						curr_version = node.VERSION
					OS.alert("Outdated ModConfiguration\n\nRequired Version: " + str(config_mod_ver_min) + "+\n\nSee godot.log for details", "deadname-deleter")
					print_log("Outdated ModConfiguration mod found, please install the required version or above to be able to configurate this mod.")
					print_log("Required Version: " + str(config_mod_ver_min) + "+")
					print_log("Current ModConfiguration Version: " + curr_version)
					print_log("Download latest release: https://github.com/reckdave/Mod-Configuration")
					config_loaded = true
					return
				config = node.MakeConfig(mod_name,mod_author,config).ConfigValues
				config_loaded = true
			yield(get_tree(),"idle_frame")
	else:
		OS.alert("ModConfiguration mod is not found\nIf you want to change where this mod redirects you to, use ModConfiguration:\nhttps://github.com/reckdave/Mod-Configuration","deadname-deleter")
		print_log("Can not find ModConfiguration, using default settings")
		print_log("If you want to change where this mod's settings you to, use ModConfiguration:")
		print_log("https://github.com/reckdave/Mod-Configuration")
		config_loaded = true

var setup_usernames = false
func _process(delta):
	if !localization_system_installed and get_parent().has_node("LocalizationSystem"):
		print_log("ERROR: Localization System installed:")
		print_log("ERROR: as both deadname-deleter and Localisation System both otherride various text, it is best to use either one or the other.")
		print_log("ERROR: (unless you know what you are doing, otherwise there is little to no major impact other than text showing that of deadname-deleter's or localization)")
		localization_system_installed = true
	while !config_loaded: # _ready() has to wait up before the config is fully loaded
		yield(get_tree().create_timer(0.1,false),"timeout")
	if !setup_usernames:
		setup_usernames()
		setup_usernames = true
	if Tab.data["open"][0] and get_parent().get_parent().get_node("0").get_child(0).name != "NROOT": # PC, should not be the pre-boot screens
		if !patched_login_username and get_parent().get_parent().get_node("0").has_node("C/PC/Input/Viewport/NROOT/Aspect/Aspect/s2/LoginScreen/PasswordBox/UserName"):
			# PC Login
			var login_username = get_parent().get_parent().get_node("0").get_node("C/PC/Input/Viewport/NROOT/Aspect/Aspect/s2/LoginScreen/PasswordBox/UserName")
			print_log("found PC Desktop Scene...")
			print_log("patching login username")
			login_username.bbcode_text = "[center]"+username #should i replace this with the steam username?
			patched_login_username = true
		# PC can be either "PC" or "@PC@XXX"
		if patched_desktop and get_parent().get_parent().get_node("0").get_child_count() == 1:
			if get_parent().get_parent().get_node("0").get_child(0).name != old_pc_name:
				print_log(get_parent().get_parent().get_node("0").get_child(0).name + " != " + old_pc_name)
				print_log("switching to new PC node (chapter select?), gotta patch this one as well.")
				patched_desktop = false
		if !patched_desktop and get_parent().get_parent().get_node("0").get_child(0).has_node("Side"):
			print_log("patching " + get_parent().get_parent().get_node("0").get_child(0).name)
			old_pc_name = get_parent().get_parent().get_node("0").get_child(0).name
			print_log("patching sidebar")
			get_parent().get_parent().get_node("0").get_child(0).get_node("Side/Friend2/Friend/TOPNAME_EMAIL").bbcode_text = email_username
			get_parent().get_parent().get_node("0").get_child(0).get_node("Side/Friend2/Friend/TOPNAME_NAME").bbcode_text = username
			
			patched_desktop = true
	if Tab.data["open"][4]: # Email
		if patched_email_usernames and get_parent().get_parent().get_node("4").get_child(0).name != old_email_name:
			print_log("Found replaced Tab node (did you leave the email open when a new message pops in?), patching...")
			patched_email_usernames = false
		if !patched_email_usernames and get_parent().get_parent().get_node("4").get_child(0).has_node("Active"):
			if get_parent().get_parent().get_node("4").get_child(0).has_node("Active/EmailTitle/TOPNAME_NAME") and get_parent().get_parent().get_node("4").get_child(0).has_node("Active/EmailTitle/TOPNAME_EMAIL"):
				print_log("patching email usernames")
				old_email_name = get_parent().get_parent().get_node("4").get_child(0).name
				var email_name = get_parent().get_parent().get_node("4").get_child(0).get_node("Active/EmailTitle/TOPNAME_NAME")
				var email_email = get_parent().get_parent().get_node("4").get_child(0).get_node("Active/EmailTitle/TOPNAME_EMAIL")
				email_name.bbcode_text = username.to_upper()
				email_email.bbcode_text = email_username
				
				# so.. for some reason, the email usernames are set into the global vars (gotta change that)
				Vars.set("EMAIL_NAME", email_username)
				Vars.set("EMAIL_USERNAME"+ username)
				Vars.set("EMAIL_TO", str("    <to "+email_username.substr(1)))
				patched_email_usernames = true
	if Tab.data["open"][4] == false and patched_email_usernames: #some random bug happens because the game thinks it's safe to revert the names back..
		# not on my watch OperatingSystem
		patched_email_usernames = false
	if Tab.data["open"][13]: # kinito compilation in prolouge.. stray username in path here..
		if !patched_startup_kinito and get_parent().get_parent().has_node("13/Tab/Active"):
			print_log("patching kinitopet.exe console text")
			var console_animation : AnimationPlayer = get_parent().get_parent().get_node("13/Tab/Active/AnimationPlayer")
			print_log(str(console_animation.has_animation("1"))) # True
			var console_ani : Animation = console_animation.get_animation("1")
			var text_track = 0
			var text = console_ani.track_get_key_value(text_track, 0)
			print_log("Console Text: " + text)
			# unsure if this is a good idea, could be an additional setting to the settings menu
			var userpath = ""
			if(config["CMD_HOME_PATH"]):
				userpath = OS.get_environment("HOMEDRIVE") + OS.get_environment("HOMEPATH") + "\\Desktop"
			else:
				userpath = OS.get_environment("HOMEDRIVE") +"\\Users\\"+ username +"\\Desktop"
			print_log("userpath: " + userpath.c_escape())
			var newtext = text.replace("C:\\Users\\[username]\\desktop", userpath)
			print_log("new text: " + newtext)
			console_ani.track_set_key_value(text_track, 0, newtext)
			print_log("new animation value: " + console_ani.track_get_key_value(text_track, 0))
			# maybe the animation change was useless?
			get_parent().get_parent().get_node("13/Tab/Active/Asset/T4").bbcode_text = newtext
			get_parent().get_parent().get_node("13/Tab/Active/Asset/T4").text = newtext
			patched_startup_kinito = true
			# since you can't close the terminal at this stage, no need to repatch
	pass

func setup_usernames():
	match config["REPLACED_NAME"]:
		NameType.STEAM:
			username = str(Steam.getPersonaName()).strip_edges().strip_escapes()
			email_username = "<"+username+str(Steam.getPlayerSteamLevel())+"@"+config["EMAIL_DOMAIN"]+">" # let's not trim this... if people got long as usernames... rip?
		NameType.CUSTOM:
			username = config["CUSTOM_NAME"]
			email_username = "<"+username+str(config["CUSTOM_EMAIL_NUM"])+"@"+config["EMAIL_DOMAIN"]+">"
		NameType.DEFAULT:
			OS.alert("You have set the REPLACED_NAME type to DEFAULT, this will use your current PC username..\nDefeating the purpose of the mod other than changing the email domain...", "Are you sure?")
			print_log("WARNING: USING DEFAULT NAME TYPE SETTINGS")
			username = OS.get_environment("USERNAME")
			email_username = "<"+username+"532"+"@"+config["EMAIL_DOMAIN"]+">"

func print_log(text):
	print("[deadname-deleter] ",text)


class NameType:
	const STEAM = "STEAM"
	const CUSTOM = "CUSTOM"
	const DEFAULT = "DEFAULT"

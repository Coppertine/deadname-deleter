extends Node

# replace with settings change.. might have to modify SETTINGS data for this.
var cmd_home_path = false

var patched_login_username = false
var patched_desktop = false
var patched_email_usernames = false
var patched_startup_kinito = false
var injected_home_path_settings = false
var localization_system_installed = false
var injected_cmd = false
var old_pc_name = ""
var old_email_name = ""
#var checked_localization_endbat = false
onready var steam_username = str(Steam.getPersonaName()).strip_edges().strip_escapes()
onready var username = "<"+steam_username+str(Steam.getPlayerSteamLevel())+"@email>" # let's not trim this... if people got long as usernames... rip?
func _ready():
#	if !steam_username.matchn("[0-9a-zA-Z _\\-]"):
#		print_log("WARNING: Steam username is not fully ASCII, this may cause display problems throughout the game.")
# Above should be in regex.. but i want to make sure ALL letters are part of it..
	print_log("---------------------")
	print_log("Thank you for installing deadname-deleter.")
	print_log("All references to the PC username are replaced with either 'USER' or your steam username.")
	print_log("---------------------")

#	if !Settings.settings.has("DeadnameDel_CMDHomePath"):
#		Settings.settings.DeadnameDel_CMDHomePath = cmd_home_path

func _process(delta):
	if !localization_system_installed and get_parent().has_node("LocalizationSystem/CanvasLayer"): # checks if the console input is there
		print_log("ERROR: Localization System installed:")
		print_log("ERROR: as both deadname-deleter and Localisation System both otherride various text, it is best to use either one or the other.")
		print_log("ERROR: (unless you know what you are doing, otherwise there is little to no major impact other than text showing that of deadname-deleter's or localization)")
		localization_system_installed = true
	if Tab.data["open"][0] and get_parent().get_parent().get_node("0").get_child(0).name != "NROOT": # PC, should not be the pre-boot screens
		if !patched_login_username and get_parent().get_parent().get_node("0").has_node("C/PC/Input/Viewport/NROOT/Aspect/Aspect/s2/LoginScreen/PasswordBox/UserName"):
			# PC Login
			var login_username = get_parent().get_parent().get_node("0").get_node("C/PC/Input/Viewport/NROOT/Aspect/Aspect/s2/LoginScreen/PasswordBox/UserName")
			print_log("found PC Desktop Scene...")
			print_log("patching login username")
			login_username.bbcode_text = "[center]USER" #should i replace this with the steam username?
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
			# an idea would be to replace the email with Steam.getPersonaName() + Steam.getPlayerSteamLevel() (i.e. coppertine11@email)
			print_log("patching email address")
			if steam_username == "TENOKE": # known scene cracker
				print_log("arrh, me-matey, travellin' the seven seas? don't forget to give back to the community (and possibly troy too if you can)")
				print_log("troy's patreon: https://www.patreon.com/troy_en")
				# i really want to make kinito wear an eyepatch.. 
				# i'll do a check to see if any additional children to the Props.
				# it could mean someone use HatMaker in the process.
				# nvm, going to Modding API
				#_add_kinito_eyepatch()
			get_parent().get_parent().get_node("0").get_child(0).get_node("Side/Friend2/Friend/TOPNAME_EMAIL").bbcode_text = username
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
				email_name.bbcode_text = steam_username.to_upper()
				email_email.bbcode_text = username
				
				# so.. for some reason, the email usernames are set into the global vars (by extension, the save files save them.. gotta change that)
				Vars.set("EMAIL_NAME", username)
				Vars.set("EMAIL_USERNAME"+ steam_username)
				Vars.set("EMAIL_TO", str("    <to "+username.substr(1)))
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
			if(cmd_home_path):
				userpath = OS.get_environment("HOMEDRIVE") + OS.get_environment("HOMEPATH") + "\\Desktop"
			else:
				userpath = "C:\\Users\\USER\\Desktop"
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

#	if Tab.data["sp"] == 12  and Tab.data["open"][1] == true: # in terminal or your_world section.. need to wait for the CMD_Prompt child to be created and check what it is.
		# if CMD_Prompt has "CMD", we are loading up the admin cmd scene
#		if !injected_cmd and get_parent().get_parent().has_node("1/MAIN_KINITO/Main/Pet/CMD_Prompt/CMD"):
#			var cmd_prompt = get_parent().get_parent().get_node("1/MAIN_KINITO/Main/Pet/CMD_Prompt/CMD")
			# now, because localization mod exists, it actively replaces the ENTIRE SCENE... 
			# so for that.. we need to check that the mod is loaded (already done)
			# and change out the script depending on if the mod is used or not.
			# NOT DOING IT FOR THIS VERSION AS USING OBJECT.FREE() IS EXTREMELY DANGEROUS
#			injected_cmd = true
#		pass
	# Re-enable when settings is refactored into a ScrollContainer.. they aren't positioned automatically.
#	if Tab.data["open"][7] and !injected_home_path_settings and get_parent().get_parent().has_node("7/Tab"):
#		_inject_settings()
#		injected_home_path_settings = true
	pass

# Settings
func _inject_settings():
	var settings_list = get_parent().get_parent().get_node("7/Tab/Active/ScrollContainer/HBoxContainer/Control/ASSET/1")
	# Control2 holds the TITLE_BGV settings list
	print_log("injecting settings menu")
	var home_path_title = RichTextLabel.new()
	home_path_title.name = "DeadnameDeleter_TITLE"
	home_path_title.text = "MOD_DDEL"
	home_path_title.READ_RATE = 0.25
	home_path_title.audio = true
	home_path_title.scroll_active = false
	home_path_title.theme = load("res://-Asset/Theme/Retro.tres")
	
	var title_tween = Tween.new()
	title_tween.name = "Tween"
	home_path_title.add_child(title_tween)
	print_log("created tween")
	
	var title_audio = AudioStreamPlayer.new()
	title_audio.volume_db = -40
	title_audio.name = "AudioStreamPlayer"
	title_audio.pitch_scale = 0.56
	title_audio.stream = load("res://-Asset/App001/Sounds/Tab/Click.ogg")
	home_path_title.add_child(title_audio)
	print_log("created audio")

	home_path_title.set_script(load("res://Script/TextLerp.gd"))
	print_log("created title")

	print_log("adding to node")
	
	settings_list.add_child_below_node(settings_list.get_node("Control2"), home_path_title)
	for n in range(settings_list.get_child_count()):
		print_log(settings_list.get_children()[n].name + ", " + str(settings_list.get_children()[n].rect_position))
	pass

# TODO: Move to Modding API
#func _add_kinito_eyepatch():
#	var kinito_props_pth = "1/MAIN_KINITO/Main/Pet/Pet/3D/Viewport/6-a/Viewport/3D/PET/HeadLook/HeadMaster/Props"
#	var default_prop_count = 3 # Glasses, Hero's Mask and Top hat.
#	var eyepatch_prop_name = "Eyepatch"
#	if Tab.data["open"][1] == true and get_parent().get_parent().has_node(kinito_props_pth):
#
#		pass
#
#	pass

func print_log(text):
	print("[deadname-deleter] ",text)

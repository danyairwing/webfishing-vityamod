extends Node


var vitya
var cfg
var functions = {}
func functions_init():
	# this function is called by vitya whenever class is loading
	
	cfg = vitya.config
	# vitya.config is a preloaded, saved configuration file that contains
	# all previous settings set by the user
	
	# in vitya classes, to use cfg, its required to check if your variables
	# exist in the config, if not -- you should write something to them of your
	# class
	
	# for this scenario, we have vitya.utils.merge_config({"variable_index":"null_variable"})
	# where variable_index is the name of the config index, and null_variable is default on launch
	# PLEASE, MAKE SURE THAT NULL_VARIABLE IS OF THE CLASS OF YOUR SETTING. (the SCRIPT CLASS, not vitya class).
	
	functions = {
		# this contains UI elements in the column, example:
		# ["check", "status bar", "vitya_status", cfg.statusbar],
		# the first argument is type of element - checkbox, in this case
		# the second is its name/title
		# the third is function/cfg variable that its going to call/set
		# the fourth is the default setting option - in this case, we are using
		# config to define it
		
		
		
	}
	# it is also recommended to use vitya.utils whenever is needed to - 
	# signals, such as new_session, entity_added come handy in some scenarios.
	
	# your class HAS to contain: variables - vitya, functions_init(), and functions.
	# if it doesn't it will fail to load
	
	# for more examples you can look at the source code of vitya's built in classes !!!!!! <-- could not recommend more


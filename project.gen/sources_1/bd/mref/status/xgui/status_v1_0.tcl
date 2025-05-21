# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ACTIVE_LOW_LED" -parent ${Page_0}


}

proc update_PARAM_VALUE.ACTIVE_LOW_LED { PARAM_VALUE.ACTIVE_LOW_LED } {
	# Procedure called to update ACTIVE_LOW_LED when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACTIVE_LOW_LED { PARAM_VALUE.ACTIVE_LOW_LED } {
	# Procedure called to validate ACTIVE_LOW_LED
	return true
}


proc update_MODELPARAM_VALUE.ACTIVE_LOW_LED { MODELPARAM_VALUE.ACTIVE_LOW_LED PARAM_VALUE.ACTIVE_LOW_LED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACTIVE_LOW_LED}] ${MODELPARAM_VALUE.ACTIVE_LOW_LED}
}


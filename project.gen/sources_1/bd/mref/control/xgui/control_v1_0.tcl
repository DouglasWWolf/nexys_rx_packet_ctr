# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "AW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SW" -parent ${Page_0}


}

proc update_PARAM_VALUE.AW { PARAM_VALUE.AW } {
	# Procedure called to update AW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AW { PARAM_VALUE.AW } {
	# Procedure called to validate AW
	return true
}

proc update_PARAM_VALUE.SW { PARAM_VALUE.SW } {
	# Procedure called to update SW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SW { PARAM_VALUE.SW } {
	# Procedure called to validate SW
	return true
}


proc update_MODELPARAM_VALUE.AW { MODELPARAM_VALUE.AW PARAM_VALUE.AW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AW}] ${MODELPARAM_VALUE.AW}
}

proc update_MODELPARAM_VALUE.SW { MODELPARAM_VALUE.SW PARAM_VALUE.SW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SW}] ${MODELPARAM_VALUE.SW}
}


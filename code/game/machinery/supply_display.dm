/obj/structure/machinery/status_display/supply_display
	ignore_friendc = 1

/obj/structure/machinery/status_display/supply_display/update()
	if(!..() && mode == STATUS_DISPLAY_CUSTOM)
		message1 = "SUPPLY"
		message2 = ""

		var/datum/shuttle/ferry/supply/shuttle = supply_controller.shuttle
		if(!shuttle)
			message2 = "Error"
		else if(shuttle.has_arrive_time())
			message2 = get_supply_shuttle_timer()
			if(length(message2) > CHARS_PER_LINE)
				message2 = "Error"
		else if(shuttle.is_launching())
			if(shuttle.at_station())
				message2 = "Launch"
			else
				message2 = "ETA"
		else
			if(shuttle.at_station())
				message2 = "Docked"
			else
				message1 = ""
		update_display(message1, message2)
		return TRUE
	return FALSE

/obj/structure/machinery/status_display/supply_display/receive_signal/(datum/signal/signal)
	if(signal.data["command"] == "supply")
		mode = STATUS_DISPLAY_CUSTOM
	else
		..(signal)

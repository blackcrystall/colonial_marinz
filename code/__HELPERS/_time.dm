#define MIDNIGHT_ROLLOVER 864000 //number of deciseconds in a day

#define MILLISECONDS *0.01

#define DECISECONDS *1 //the base unit all of these defines are scaled by, because byond uses that as a unit of measurement for some fucking reason

#define SECONDS *10

#define MINUTES *600

#define HOURS *36000

#define MINUTES_TO_DECISECOND *600
#define MINUTES_TO_HOURS /60

#define DECISECONDS_TO_HOURS /36000

var/midnight_rollovers = 0
var/rollovercheck_last_timeofday = 0

// Real time that is still reliable even when the round crosses over midnight time reset.
#define REALTIMEOFDAY (world.timeofday + (864000 * MIDNIGHT_ROLLOVER_CHECK))
#define MIDNIGHT_ROLLOVER_CHECK ( rollovercheck_last_timeofday != world.timeofday ? update_midnight_rollover() : midnight_rollovers )

/proc/update_midnight_rollover()
	if(world.timeofday < rollovercheck_last_timeofday)
		midnight_rollovers++

	rollovercheck_last_timeofday = world.timeofday
	return midnight_rollovers

//returns time diff of two times normalized to time_rate_multiplier
/proc/daytimeDiff(timeA, timeB)
	var/time_diff = timeA > timeB ? (timeB + 1) - timeA : timeB - timeA
	return time_diff

/proc/game_time()
	return REALTIMEOFDAY % 864000

/proc/game_time_timestamp(format = "hh:mm:ss")
	return time2text(game_time(), format)

/proc/planet_game_time_timestamp(format = "hh:mm:ss")
	return time2text(SSsunlighting.game_time_offseted() - GLOB.timezoneOffset, format)

/proc/game_timestamp(format = "hh:mm:ss", time = null)
	if(!time)
		time = world.time
	return time2text(time - GLOB.timezoneOffset, format)

/proc/time_stamp() // Shows current GMT time
	return time2text(world.timeofday, "hh:mm:ss")

/proc/duration2text(time = world.time) // Shows current time starting at 0:00
	return game_timestamp("hh:mm", time)

/proc/duration2text_sec(time = world.time) // shows minutes:seconds
	return game_timestamp("mm:ss", time)

/proc/duration2text_hour_min_sec(time = world.time) // shows minutes:seconds
	return game_timestamp("hh:mm:ss", time)

/proc/time_left_until(target_time, current_time, time_unit)
	return CEILING(target_time - current_time, 1) / time_unit

/proc/text2duration(text = "00:00") // Attempts to convert time text back to time value
	var/split_text = splittext(text, ":")
	var/time_hours = text2num(split_text[1]) * 1 HOURS
	var/time_minutes = text2num(split_text[2]) * 1 MINUTES
	return time_hours + time_minutes

#define is_day(day) day == text2num(time2text(world.timeofday, "DD"))
#define is_month(month) month == text2num(time2text(world.timeofday, "MM"))

#define TICKS *world.tick_lag

#define DS2TICKS(DS) ((DS)/world.tick_lag)

#define TICKS2DS(T) ((T) TICKS)

#define MS2DS(T) ((T) MILLISECONDS)

#define DS2MS(T) ((T) * 100)

//Takes a value of time in deciseconds.
//Returns a text value of that number in hours, minutes, or seconds.
/proc/DisplayTimeText(time_value, round_seconds_to = 0.1, language)
	switch(language)
		if(CLIENT_LANGUAGE_RUSSIAN)
			var/second = FLOOR(time_value * 0.1, round_seconds_to)
			if(!second)
				return "прямо сейчас"
			if(second < 60)
				return "[second] секунд"
			var/minute = FLOOR(second / 60, 1)
			second = FLOOR(MODULUS(second, 60), round_seconds_to)
			var/secondT
			if(second)
				secondT = " и [second] секунд"
			if(minute < 60)
				return "[minute] минут[secondT]"
			var/hour = FLOOR(minute / 60, 1)
			minute = MODULUS(minute, 60)
			var/minuteT
			if(minute)
				minuteT = " и [minute] минут"
			if(hour < 24)
				return "[hour] час[(hour != 1)? "а":""][minuteT][secondT]"
			var/day = FLOOR(hour / 24, 1)
			hour = MODULUS(hour, 24)
			var/hourT
			if(hour)
				hourT = " и [hour] час[(hour != 1)? "а":""]"
			return "[day] [(day != 1)? "дней":"день"][hourT][minuteT][secondT]"

		if(CLIENT_LANGUAGE_ENGLISH)
			var/second = FLOOR(time_value * 0.1, round_seconds_to)
			if(!second)
				return "right now"
			if(second < 60)
				return "[second] second[(second != 1)? "s":""]"
			var/minute = FLOOR(second / 60, 1)
			second = FLOOR(MODULUS(second, 60), round_seconds_to)
			var/secondT
			if(second)
				secondT = " and [second] second[(second != 1)? "s":""]"
			if(minute < 60)
				return "[minute] minute[(minute != 1)? "s":""][secondT]"
			var/hour = FLOOR(minute / 60, 1)
			minute = MODULUS(minute, 60)
			var/minuteT
			if(minute)
				minuteT = " and [minute] minute[(minute != 1)? "s":""]"
			if(hour < 24)
				return "[hour] hour[(hour != 1)? "s":""][minuteT][secondT]"
			var/day = FLOOR(hour / 24, 1)
			hour = MODULUS(hour, 24)
			var/hourT
			if(hour)
				hourT = " and [hour] hour[(hour != 1)? "s":""]"
			return "[day] day[(day != 1)? "s":""][hourT][minuteT][secondT]"

/proc/daysSince(realtimev)
	return round((world.realtime - realtimev) / (24 HOURS))

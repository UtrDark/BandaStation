#define DEFAULT_MIN_BOMBER_ALIVE_TIME 30

#define RC_STATE_DISABLED 0
#define RC_STATE_LIMITED 1
#define RC_STATE_BLOCKED 2

// MARK: Controller

/datum/controller/subsystem/explosions
	ss_flags = SS_TICKER
	var/static/datum/json_database/raider_controller_database
	var/raider_controller_state = RC_STATE_DISABLED
	var/minimum_bomber_alive_time = DEFAULT_MIN_BOMBER_ALIVE_TIME
	var/devastation_cap = 0
	var/heavy_impact_cap = 1
	var/light_impact_cap = 4
	var/block_chem_smoke = FALSE
	var/block_foam = FALSE

/datum/controller/subsystem/explosions/Initialize()
	load_raider_controller_settings()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/explosions/proc/load_raider_controller_settings()
	if(isnull(raider_controller_database))
		raider_controller_database = new("data/raider_controller.json")
	var/list/settings = raider_controller_database.get()
	if(!length(settings))
		return

	raider_controller_state = settings["state"] || RC_STATE_DISABLED
	minimum_bomber_alive_time = settings["time_limit_hours"]
	devastation_cap = settings["devastation_cap"]
	heavy_impact_cap = settings["heavy_impact_cap"]
	light_impact_cap = settings["light_impact_cap"]
	block_chem_smoke = settings["block_chem_smoke"] || FALSE
	block_foam = settings["block_foam"] || FALSE

/datum/controller/subsystem/explosions/proc/save_raider_controller_settings()
	if(isnull(raider_controller_database))
		raider_controller_database = new("data/raider_controller.json")
	raider_controller_database.replace(list(
		"state" = raider_controller_state,
		"time_limit_hours" = minimum_bomber_alive_time,
		"devastation_cap" = devastation_cap,
		"heavy_impact_cap" = heavy_impact_cap,
		"light_impact_cap" = light_impact_cap,
		"block_chem_smoke" = block_chem_smoke,
		"block_foam" = block_foam,
	))

ADMIN_VERB(manage_raider_controller, R_ADMIN, "Raider Controller", "Manages anti-raider system", ADMIN_CATEGORY_DEBUG)
	SSexplosions.ui_interact(user.mob)

/datum/controller/subsystem/explosions/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/controller/subsystem/explosions/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RaiderController", "Raider Controller")
		ui.open()

/datum/controller/subsystem/explosions/ui_data(mob/user)
	return list(
		"limited" = raider_controller_state == RC_STATE_LIMITED,
		"blocked" = raider_controller_state == RC_STATE_BLOCKED,
		"disabled" = raider_controller_state == RC_STATE_DISABLED,
		"time_limit_hours" = minimum_bomber_alive_time,
		"devastation_cap" = devastation_cap,
		"heavy_impact_cap" = heavy_impact_cap,
		"light_impact_cap" = light_impact_cap,
		"block_chem_smoke" = block_chem_smoke,
		"block_foam" = block_foam,
	)

/datum/controller/subsystem/explosions/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("block")
			raider_controller_state = RC_STATE_BLOCKED
		if("limit")
			raider_controller_state = RC_STATE_LIMITED
		if("disable")
			raider_controller_state = RC_STATE_DISABLED
		if("toggle_chem_smoke")
			block_chem_smoke = !block_chem_smoke
		if("toggle_foam")
			block_foam = !block_foam
		if("set_time_limit")
			var/time_limit_hours = params["hours"]
			minimum_bomber_alive_time = time_limit_hours
		if("set_cap")
			var/cap = params["value"]
			switch(params["range"])
				if("devastation")
					devastation_cap = cap
				if("heavy")
					heavy_impact_cap = cap
				if("light")
					light_impact_cap = cap
				else
					return
		else
			return
	save_raider_controller_settings()
	return TRUE

/datum/controller/subsystem/explosions/proc/get_raider_controller_client(atom/source)
	var/mob/user_mob = usr
	if(ismob(user_mob) && user_mob.client)
		return user_mob.client
	if(source?.fingerprintslast)
		return GLOB.directory[source.fingerprintslast]
	return null

/datum/controller/subsystem/explosions/proc/should_block_raider_chemical_effect(atom/source, effect_name)
	var/client/who_did_it = get_raider_controller_client(source)
	if(!who_did_it || (who_did_it.get_exp_living(pure_numeric = TRUE) / 60) >= minimum_bomber_alive_time)
		return FALSE
	var/block_message = "Время [ADMIN_LOOKUPFLW(who_did_it.mob)] ([who_did_it.get_exp_living()]) ниже предела. [effect_name]: эффект отменён."
	message_admins(block_message)
	log_game(block_message)
	return TRUE

// MARK: Chemical smoke

/datum/effect_system/fluid_spread/smoke/chem/start(log = FALSE)
	if(SSexplosions.block_chem_smoke && SSexplosions.should_block_raider_chemical_effect(holder || location, "Дым"))
		return
	return ..()

// MARK: Foam

/datum/effect_system/fluid_spread/foam/start(log = FALSE, lifetime, slippery)
	if(SSexplosions.block_foam && SSexplosions.should_block_raider_chemical_effect(holder || location, "Пена"))
		return
	return ..()

// MARK: Basic explosions

/datum/controller/subsystem/explosions/explode(atom/origin, devastation_range = 0, heavy_impact_range = 0, light_impact_range = 0, flame_range = null, flash_range = null, adminlog = TRUE, ignorecap = FALSE, silent = FALSE, smoke = FALSE, protect_epicenter = FALSE, atom/explosion_cause = null, explosion_direction = 0, explosion_arc = 360)
	if(SSexplosions.raider_controller_state == RC_STATE_DISABLED)
		return ..()

	var/client/who_did_it = get_raider_controller_client(explosion_cause || origin)
	if(!who_did_it)
		return ..()

	if((who_did_it.get_exp_living(pure_numeric = TRUE) / 60) < SSexplosions.minimum_bomber_alive_time)
		if(raider_controller_state == RC_STATE_BLOCKED)
			var/block_message = "Время [ADMIN_LOOKUPFLW(who_did_it.mob)] ([who_did_it.get_exp_living()]) ниже предела. Взрыв отменён."
			message_admins(block_message)
			log_game(block_message)
			return
		var/limit_message = "Время [ADMIN_LOOKUPFLW(who_did_it.mob)] ([who_did_it.get_exp_living()]) ниже предела. Дополнительный кап. Взрыв имел размер (Devast: [devastation_range], Heavy: [heavy_impact_range], Light: [light_impact_range], Flame: [flame_range], Flash: [flash_range])"
		message_admins(limit_message)
		log_game(limit_message)
		devastation_range = min(devastation_cap, devastation_range)
		heavy_impact_range = min(heavy_impact_cap, heavy_impact_range)
		light_impact_range = min(light_impact_cap, light_impact_range)

	return ..()

///How much power it costs to deconstruct an item.
#define DESTRUCTIVE_ANALYZER_POWER_USAGE (BASE_MACHINE_IDLE_CONSUMPTION * 2.5)
///The 'ID' for deconstructing items for Research points instead of nodes.
#define DESTRUCTIVE_ANALYZER_DESTROY_POINTS "research_points"

/**
 * ## Destructive Analyzer
 * It is used to destroy hand-held objects and advance technological research.
 */
/obj/machinery/rnd/destructive_analyzer
	name = "destructive analyzer"
	desc = "Learn science by destroying things!"
	icon_state = "d_analyzer"
	base_icon_state = "d_analyzer"
	circuit = /obj/item/circuitboard/machine/destructive_analyzer

/obj/machinery/rnd/destructive_analyzer/Initialize(mapload)
	. = ..()
	register_context()

/obj/machinery/rnd/destructive_analyzer/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(loaded_item)
		context[SCREENTIP_CONTEXT_ALT_LMB] = "Remove Item"
	else if(!isnull(held_item))
		context[SCREENTIP_CONTEXT_LMB] = "Insert Item"
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/rnd/destructive_analyzer/attackby(obj/item/weapon, mob/living/user, params)
	if(user.istate & ISTATE_HARM)
		return ..()
	if(!is_insertion_ready(user))
		return ..()
	if(!user.transferItemToLoc(weapon, src))
		to_chat(user, span_warning("\The [weapon] is stuck to your hand, you cannot put it in the [name]!"))
		return TRUE
	busy = TRUE
	loaded_item = weapon
	to_chat(user, span_notice("You add the [weapon.name] to the [name]!"))
	flick("[base_icon_state]_la", src)
	addtimer(CALLBACK(src, PROC_REF(finish_loading)), 1 SECONDS)
	return TRUE

/obj/machinery/rnd/destructive_analyzer/AltClick(mob/user)
	. = ..()
	unload_item()

/obj/machinery/rnd/destructive_analyzer/update_icon_state()
	icon_state = "[base_icon_state][loaded_item ? "_l" : null]"
	return ..()

/obj/machinery/rnd/destructive_analyzer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DestructiveAnalyzer")
		ui.open()

/obj/machinery/rnd/destructive_analyzer/ui_data(mob/user)
	var/list/data = list()
	data["server_connected"] = !!stored_research
	data["node_data"] = list()
	if(loaded_item)
		data["item_icon"] = text_ref(loaded_item.icon)
		data["item_icon_state"] = loaded_item.icon_state
		data["indestructible"] = !(loaded_item.resistance_flags & INDESTRUCTIBLE)
		data["loaded_item"] = loaded_item
		data["already_deconstructed"] = !!stored_research.deconstructed_items[loaded_item.type]
		var/list/points = techweb_item_point_check(loaded_item)
		data["recoverable_points"] = techweb_point_display_generic(points)

		var/list/boostable_nodes = techweb_item_unlock_check(loaded_item)
		for(var/id in boostable_nodes)
			var/datum/techweb_node/unlockable_node = SSresearch.techweb_node_by_id(id)
			var/list/node_data = list()
			node_data["node_name"] = unlockable_node.display_name
			node_data["node_id"] = unlockable_node.id
			node_data["node_hidden"] = !!stored_research.hidden_nodes[unlockable_node.id]
			data["node_data"] += list(node_data)
	else
		data["loaded_item"] = null
	return data

/obj/machinery/rnd/destructive_analyzer/ui_static_data(mob/user)
	var/list/data = list()
	data["research_point_id"] = DESTRUCTIVE_ANALYZER_DESTROY_POINTS
	return data

/obj/machinery/rnd/destructive_analyzer/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/mob/user = usr
	switch(action)
		if("eject_item")
			if(busy)
				balloon_alert(user, "already busy!")
				return TRUE
			if(loaded_item)
				unload_item()
				return TRUE
		if("deconstruct")
			if(!user_try_decon_id(params["deconstruct_id"]))
				say("Destructive analysis failed!")
			return TRUE

//This allows people to put syndicate screwdrivers in the machine. Secondary act still passes.
/obj/machinery/rnd/destructive_analyzer/screwdriver_act(mob/living/user, obj/item/tool)
	return FALSE

///Drops the loaded item where it can and nulls it.
/obj/machinery/rnd/destructive_analyzer/proc/unload_item()
	if(!loaded_item)
		return FALSE
	playsound(loc, 'sound/machines/terminal_insert_disc.ogg', 30, FALSE)
	loaded_item.forceMove(drop_location())
	loaded_item = null
	update_appearance(UPDATE_ICON)
	return TRUE

///Called in a timer callback after loading something into it, this handles resetting the 'busy' state back to its initial state
///So the machine can be used.
/obj/machinery/rnd/destructive_analyzer/proc/finish_loading()
	update_appearance(UPDATE_ICON)
	reset_busy()

/**
 * Destroys an item by going through all its contents (including itself) and calling destroy_item_individual
 * Args:
 * gain_research_points - Whether deconstructing each individual item should check for research points to boost.
 */
/obj/machinery/rnd/destructive_analyzer/proc/destroy_item(gain_research_points = FALSE)
	if(QDELETED(loaded_item) || QDELETED(src))
		return FALSE
	flick("[base_icon_state]_process", src)
	busy = TRUE
	addtimer(CALLBACK(src, PROC_REF(reset_busy)), 2.4 SECONDS)
	use_power(DESTRUCTIVE_ANALYZER_POWER_USAGE)
	var/list/all_contents = loaded_item.get_all_contents()
	for(var/innerthing in all_contents)
		destroy_item_individual(innerthing, gain_research_points)

	loaded_item = null
	update_appearance(UPDATE_ICON)
	return TRUE

/**
 * Destroys the individual provided item
 * Args:
 * thing - The thing being destroyed. Generally an object, but it can be a mob too, such as intellicards and pAIs.
 * gain_research_points - Whether deconstructing this should give research points to the stored techweb, if applicable.
 */
/obj/machinery/rnd/destructive_analyzer/proc/destroy_item_individual(obj/item/thing, gain_research_points = FALSE)
	if(isliving(thing))
		var/mob/living/mob_thing = thing
		if(mob_thing.stat != DEAD)
			mob_thing.investigate_log("has been killed by a destructive analyzer.", INVESTIGATE_DEATHS)
		mob_thing.death()
	var/list/point_value = techweb_item_point_check(thing)
	if(point_value && !stored_research.deconstructed_items[thing.type])
		stored_research.deconstructed_items[thing.type] = TRUE
		stored_research.add_point_list(point_value)
	qdel(thing)

/**
 * Attempts to destroy the loaded item using a provided research id.
 * Args:
 * id - The techweb ID node that we're meant to unlock if applicable.
 */
/obj/machinery/rnd/destructive_analyzer/proc/user_try_decon_id(id)
	if(!istype(loaded_item))
		return FALSE
	if(isnull(id))
		return FALSE

	if(id == DESTRUCTIVE_ANALYZER_DESTROY_POINTS)
		if(!destroy_item(gain_research_points = TRUE))
			return FALSE
		return TRUE

	var/datum/techweb_node/node_to_discover = SSresearch.techweb_node_by_id(id)
	if(!istype(node_to_discover))
		return FALSE
	SSblackbox.record_feedback("nested tally", "item_deconstructed", 1, list("[node_to_discover.id]", "[loaded_item.type]"))
	if(!destroy_item())
		return FALSE
	stored_research.unhide_node(SSresearch.techweb_node_by_id(node_to_discover.id))
	return TRUE

#undef DESTRUCTIVE_ANALYZER_DESTROY_POINTS
#undef DESTRUCTIVE_ANALYZER_POWER_USAGE

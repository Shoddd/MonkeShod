//Use this only for things that aren't a subtype of obj/machinery/power
//For things that are, override "should_have_node()" on them
GLOBAL_LIST_INIT(wire_node_generating_types, typecacheof(list(/obj/structure/grille)))

#define UNDER_SMES -1
#define UNDER_TERMINAL 1

///////////////////////////////
//CABLE STRUCTURE
///////////////////////////////
////////////////////////////////
// Definitions
////////////////////////////////
/obj/structure/cable
	name = "power cable"
	desc = "A flexible, superconducting insulated cable for heavy-duty power transfer."
	icon = 'icons/obj/power_cond/layer_cable.dmi'
	icon_state = "l2-1-2-4-8-node"
	color = CABLE_HEX_COLOR_YELLOW
	plane = FLOOR_PLANE
	layer = WIRE_LAYER //Above hidden pipes, GAS_PIPE_HIDDEN_LAYER
	anchored = TRUE
	obj_flags = CAN_BE_HIT
	var/linked_dirs = 0 //bitflag
	var/node = FALSE //used for sprites display
	var/cable_layer = CABLE_LAYER_2 //bitflag
	var/datum/powernet/powernet
	var/cable_color = CABLE_COLOR_YELLOW
	var/is_fully_initialized = FALSE
	///used to seperate industrial and normal cables
	var/cable_tag = "normal"

/obj/structure/cable/layer1
	color = CABLE_HEX_COLOR_RED
	cable_color = CABLE_COLOR_RED
	cable_layer = CABLE_LAYER_1
	layer = WIRE_LAYER - 0.01
	icon_state = "l1-1-2-4-8-node"

/obj/structure/cable/layer3
	color = CABLE_HEX_COLOR_BLUE
	cable_color = CABLE_COLOR_BLUE
	cable_layer = CABLE_LAYER_3
	layer = WIRE_LAYER + 0.01
	icon_state = "l4-1-2-4-8-node"

/obj/structure/cable/Initialize(mapload)
	. = ..()

	GLOB.cable_list += src //add it to the global cable list
	Connect_cable()
	AddElement(/datum/element/undertile, TRAIT_T_RAY_VISIBLE)
	RegisterSignal(src, COMSIG_RAT_INTERACT, PROC_REF(on_rat_eat))
	if(isturf(loc))
		var/turf/turf_loc = loc
		turf_loc.add_blueprints_preround(src)

	return INITIALIZE_HINT_LATELOAD

/obj/structure/cable/LateInitialize()
	update_appearance(UPDATE_ICON)
	is_fully_initialized = TRUE

/obj/structure/cable/examine(mob/user)
	. = ..()
	if(isobserver(user))
		. += get_power_info()

/obj/structure/cable/proc/on_rat_eat(datum/source, mob/living/basic/regal_rat/king)
	SIGNAL_HANDLER

	if(avail())
		king.apply_damage(10)
		playsound(king, 'sound/effects/sparks2.ogg', 100, TRUE)
	deconstruct()

	return COMPONENT_RAT_INTERACTED

///Set the linked indicator bitflags
/obj/structure/cable/proc/Connect_cable(clear_before_updating = FALSE)
	var/under_thing = NONE
	if(clear_before_updating)
		linked_dirs = 0
	var/obj/machinery/power/search_parent
	for(var/obj/machinery/power/P in loc)
		if(istype(P, /obj/machinery/power/terminal))
			under_thing = UNDER_TERMINAL
			search_parent = P
			break
		if(istype(P, /obj/machinery/power/smes))
			under_thing = UNDER_SMES
			search_parent = P
			break
	for(var/check_dir in GLOB.cardinals)
		var/TB = get_step(src, check_dir)
		//don't link from smes to its terminal
		if(under_thing)
			switch(under_thing)
				if(UNDER_SMES)
					var/obj/machinery/power/terminal/term = locate(/obj/machinery/power/terminal) in TB
					//Why null or equal to the search parent?
					//during map init it's possible for a placed smes terminal to not have initialized to the smes yet
					//but the cable underneath it is ready to link.
					//I don't believe null is even a valid state for a smes terminal while the game is actually running
					//So in the rare case that this happens, we also shouldn't connect
					//This might break.
					if(term && (!term.master || term.master == search_parent))
						continue
				if(UNDER_TERMINAL)
					var/obj/machinery/power/smes/S = locate(/obj/machinery/power/smes) in TB
					if(S && (!S.terminal || S.terminal == search_parent))
						continue
		var/inverse = turn(check_dir, 180)
		for(var/obj/structure/cable/C in TB)
			if(C.cable_layer & cable_layer)
				if(src.cable_tag != C.cable_tag)
					continue
				linked_dirs |= check_dir
				C.linked_dirs |= inverse

				// We will update on LateInitialize otherwise.
				if (C.is_fully_initialized)
					C.update_appearance(UPDATE_ICON)

	if (is_fully_initialized)
		update_appearance(UPDATE_ICON)

///Clear the linked indicator bitflags
/obj/structure/cable/proc/Disconnect_cable()
	for(var/check_dir in GLOB.cardinals)
		var/inverse = turn(check_dir, 180)
		if(linked_dirs & check_dir)
			var/TB = get_step(loc, check_dir)
			for(var/obj/structure/cable/C in TB)
				if(cable_layer & C.cable_layer)
					C.linked_dirs &= ~inverse
					C.update_appearance()

/obj/structure/cable/Destroy() // called when a cable is deleted
	Disconnect_cable()

	if(powernet)
		cut_cable_from_powernet() // update the powernets
	GLOB.cable_list -= src //remove it from global cable list

	return ..() // then go ahead and delete the cable

/obj/structure/cable/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/obj/item/stack/cable_coil/cable = new(drop_location(), 1)
		cable.set_cable_color(cable_color)
	qdel(src)

///////////////////////////////////
// General procedures
///////////////////////////////////

/obj/structure/cable/update_icon_state()
	if(!linked_dirs)
		icon_state = "l[cable_layer]-noconnection"
		return ..()

	// TODO: stop doing this shit in update_icon_state, this should be event based for the love of all that is holy
	var/list/dir_icon_list = list()
	for(var/check_dir in GLOB.cardinals)
		if(linked_dirs & check_dir)
			dir_icon_list += "[check_dir]"
	var/dir_string = dir_icon_list.Join("-")
	if(dir_icon_list.len > 1)
		for(var/obj/O in loc)
			if(GLOB.wire_node_generating_types[O.type])
				dir_string = "[dir_string]-node"
				break
			else if(istype(O, /obj/machinery/power))
				var/obj/machinery/power/P = O
				if(P.should_have_node())
					dir_string = "[dir_string]-node"
					break
	dir_string = "l[cable_layer]-[dir_string]"
	icon_state = dir_string
	return ..()


/obj/structure/cable/proc/handlecable(obj/item/W, mob/user, params)
	var/turf/T = get_turf(src)
	if(T.underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		return
	if(W.tool_behaviour == TOOL_WIRECUTTER)
		if (shock(user, 50))
			return
		user.visible_message(span_notice("[user] cuts the cable."), span_notice("You cut the cable."))
		investigate_log("was cut by [key_name(usr)] in [AREACOORD(src)]", INVESTIGATE_WIRES)
		deconstruct()
		return

	else if(W.tool_behaviour == TOOL_MULTITOOL)
		to_chat(user, get_power_info())
		shock(user, 5, 0.2)

	add_fingerprint(user)


/obj/structure/cable/proc/get_power_info()
	if(powernet?.avail > 0)
		return span_danger("Total power: [display_power(powernet.avail)]\nLoad: [display_power(powernet.load)]\nExcess power: [display_power(surplus())]")
	else
		return span_danger("The cable is not powered.")


// Items usable on a cable :
//   - Wirecutters : cut it duh !
//   - Multitool : get the power currently passing through the cable
//
/obj/structure/cable/attackby(obj/item/W, mob/user, params)
	handlecable(W, user, params)


// shock the user with probability prb
/obj/structure/cable/proc/shock(mob/user, prb, siemens_coeff = 1)
	if(!prob(prb))
		return FALSE
	if(electrocute_mob(user, powernet, src, siemens_coeff))
		do_sparks(5, TRUE, src)
		return TRUE
	else
		return FALSE

/obj/structure/cable/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct()

////////////////////////////////////////////
// Power related
///////////////////////////////////////////

// All power generation handled in add_avail()
// Machines should use add_load(), surplus(), avail()
// Non-machines should use add_delayedload(), delayed_surplus(), newavail()

/obj/structure/cable/proc/add_avail(amount)
	if(powernet)
		powernet.newavail += amount

/obj/structure/cable/proc/add_load(amount)
	if(powernet)
		powernet.load += amount

/obj/structure/cable/proc/surplus()
	if(powernet)
		return clamp(powernet.avail-powernet.load, 0, powernet.avail)
	else
		return 0

/obj/structure/cable/proc/avail(amount)
	if(powernet)
		return amount ? powernet.avail >= amount : powernet.avail
	else
		return 0

/obj/structure/cable/proc/add_delayedload(amount)
	if(powernet)
		powernet.delayedload += amount

/obj/structure/cable/proc/delayed_surplus()
	if(powernet)
		return clamp(powernet.newavail - powernet.delayedload, 0, powernet.newavail)
	else
		return 0

/obj/structure/cable/proc/newavail()
	if(powernet)
		return powernet.newavail
	else
		return 0

/////////////////////////////////////////////////
// Cable laying helpers
////////////////////////////////////////////////

// merge with the powernets of power objects in the given direction
/obj/structure/cable/proc/mergeConnectedNetworks(direction)

	var/inverse_dir = (!direction)? 0 : turn(direction, 180) //flip the direction, to match with the source position on its turf

	var/turf/TB = get_step(src, direction)

	for(var/obj/structure/cable/C in TB)
		if(!C)
			continue

		if(src == C)
			continue

		if(!(cable_layer & C.cable_layer))
			continue

		if(C.linked_dirs & inverse_dir) //we've got a matching cable in the neighbor turf
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_cable(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet, C.powernet)
			else
				C.powernet.add_cable(src) //else, we simply connect to the matching cable powernet

// merge with the powernets of power objects in the source turf
/obj/structure/cable/proc/mergeConnectedNetworksOnTurf()
	var/list/to_connect = list()
	node = FALSE

	if(!powernet) //if we somehow have no powernet, make one (should not happen for cables)
		var/datum/powernet/newPN = new()
		newPN.add_cable(src)

	//first let's add turf cables to our powernet
	//then we'll connect machines on turf where a cable is present
	for(var/atom/movable/AM in loc)
		if(istype(AM, /obj/machinery/power/apc))
			var/obj/machinery/power/apc/N = AM
			if(!N.terminal)
				continue // APC are connected through their terminal

			if(N.terminal.powernet == powernet) //already connected
				continue

			to_connect += N.terminal //we'll connect the machines after all cables are merged

		else if(istype(AM, /obj/machinery/power)) //other power machines
			var/obj/machinery/power/M = AM

			if(M.powernet == powernet)
				continue

			to_connect += M //we'll connect the machines after all cables are merged

	//now that cables are done, let's connect found machines
	for(var/obj/machinery/power/PM in to_connect)
		node = TRUE
		if(!PM.connect_to_network())
			PM.disconnect_from_network() //if we somehow can't connect the machine to the new powernet, remove it from the old nonetheless

//////////////////////////////////////////////
// Powernets handling helpers
//////////////////////////////////////////////

/obj/structure/cable/proc/get_cable_connections(powernetless_only)
	. = list()
	var/turf/T = get_turf(src)
	for(var/check_dir in GLOB.cardinals)
		if(linked_dirs & check_dir)
			T = get_step(src, check_dir)
			for(var/obj/structure/cable/C in T)
				if(cable_layer & C.cable_layer)
					. += C

/obj/structure/cable/proc/get_all_cable_connections(powernetless_only)
	. = list()
	var/turf/T
	for(var/check_dir in GLOB.cardinals)
		T = get_step(src, check_dir)
		for(var/obj/structure/cable/C in T.contents - src)
			. += C

/obj/structure/cable/proc/get_machine_connections(powernetless_only)
	. = list()
	for(var/obj/machinery/power/P in get_turf(src))
		if(!powernetless_only || !P.powernet)
			if(P.anchored)
				. += P

/obj/structure/cable/proc/auto_propagate_cut_cable(obj/O)
	if(O && !QDELETED(O))
		var/datum/powernet/newPN = new()// creates a new powernet...
		propagate_network(O, newPN)//... and propagates it to the other side of the cable

//Makes a new network for the cable and propgates it. If we already have one, just die
/obj/structure/cable/proc/propagate_if_no_network()
	if(powernet)
		return
	var/datum/powernet/newPN = new()
	propagate_network(src, newPN)

// cut the cable's powernet at this cable and updates the powergrid
/obj/structure/cable/proc/cut_cable_from_powernet(remove = TRUE)
	if(!powernet)
		return

	var/turf/T1 = loc
	if(!T1)
		return

	//clear the powernet of any machines on tile first
	for(var/obj/machinery/power/P in T1)
		P.disconnect_from_network()

	var/list/P_list = list()
	for(var/dir_check in GLOB.cardinals)
		if(linked_dirs & dir_check)
			T1 = get_step(loc, dir_check)
			P_list += locate(/obj/structure/cable) in T1

	// remove the cut cable from its turf and powernet, so that it doesn't get count in propagate_network worklist
	if(remove)
		moveToNullspace()
	powernet.remove_cable(src) //remove the cut cable from its powernet

	var/first = TRUE
	for(var/obj/O in P_list)
		if(first)
			first = FALSE
			continue
		addtimer(CALLBACK(O, PROC_REF(auto_propagate_cut_cable), O), 0) //so we don't rebuild the network X times when singulo/explosion destroys a line of X cables

///////////////////////////////////////////////
// The cable coil object, used for laying cable
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

#define CABLE_RESTRAINTS_COST 15

/obj/item/stack/cable_coil
	name = "cable coil"
	custom_price = PAYCHECK_LOWER * 0.8
	gender = NEUTER //That's a cable coil sounds better than that's some cable coils
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	inhand_icon_state = "coil_yellow"
	base_icon_state = "coil"
	novariants = FALSE
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	max_amount = MAXCOIL
	amount = MAXCOIL
	merge_type = /obj/item/stack/cable_coil // This is here to let its children merge between themselves
	color = CABLE_HEX_COLOR_YELLOW
	desc = "A coil of insulated power cable."
	throwforce = 0
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 3
	throw_range = 5
	mats_per_unit = list(/datum/material/iron=10, /datum/material/glass=5)
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("whips", "lashes", "disciplines", "flogs")
	attack_verb_simple = list("whip", "lash", "discipline", "flog")
	singular_name = "cable piece"
	full_w_class = WEIGHT_CLASS_SMALL
	grind_results = list(/datum/reagent/copper = 2) //2 copper per cable in the coil
	usesound = 'sound/items/deconstruct.ogg'
	cost = 1
	source = /datum/robot_energy_storage/wire
	var/cable_color = CABLE_COLOR_YELLOW
	var/obj/structure/cable/target_type = /obj/structure/cable
	var/target_layer = CABLE_LAYER_2

/obj/item/stack/cable_coil/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	. = ..()
	pixel_x = base_pixel_x + rand(-2, 2)
	pixel_y = base_pixel_y + rand(-2, 2)

	AddElement(/datum/element/update_icon_updates_onmob, slot_flags)

	update_appearance()

/obj/item/stack/cable_coil/examine(mob/user)
	. = ..()
	. += "<b>Ctrl+Click</b> to change the layer you are placing on."

/obj/item/stack/cable_coil/update_name()
	. = ..()
	name = "cable [(amount < 3) ? "piece" : "coil"]"

/obj/item/stack/cable_coil/update_desc()
	. = ..()
	desc = "A [(amount < 3) ? "piece" : "coil"] of insulated power cable."

/obj/item/stack/cable_coil/proc/set_cable_color(new_color)
	color = GLOB.cable_colors[new_color]
	cable_color = new_color
	update_appearance(UPDATE_ICON)

/obj/item/stack/cable_coil/update_icon_state()
	if(novariants)
		return
	. = ..()
	icon_state = "[base_icon_state][amount < 3 ? amount : ""]"
	inhand_icon_state = "coil_[cable_color]"

/obj/item/stack/cable_coil/suicide_act(mob/living/user)
	if(locate(/obj/structure/chair/stool) in get_turf(user))
		user.visible_message(span_suicide("[user] is making a noose with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	else
		user.visible_message(span_suicide("[user] is strangling [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return OXYLOSS

/obj/item/stack/cable_coil/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/stack/cable_coil/attack_self(mob/living/user)
	if(!user)
		return

	var/image/restraints_icon = image(icon = 'icons/obj/restraints.dmi', icon_state = "cuff")
	restraints_icon.maptext = MAPTEXT("<span [amount >= CABLE_RESTRAINTS_COST ? "" : "style='color: red'"]>[CABLE_RESTRAINTS_COST]</span>")
	restraints_icon.color = color

	var/list/radial_menu = list(
	"Layer 1" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-red"),
	"Layer 2" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-yellow"),
	"Layer 3" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-blue"),
	"Multilayer cable hub" = image(icon = 'icons/obj/power.dmi', icon_state = "cable_bridge"),
	"Multi Z layer cable hub" = image(icon = 'icons/obj/power.dmi', icon_state = "cablerelay-broken-cable"),
	"Cable restraints" = restraints_icon
	)

	var/layer_result = show_radial_menu(user, src, radial_menu, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(layer_result)
		if("Layer 1")
			set_cable_color(CABLE_COLOR_RED)
			target_type = /obj/structure/cable/layer1
			target_layer = CABLE_LAYER_1
			novariants = FALSE
		if("Layer 2")
			set_cable_color(CABLE_COLOR_YELLOW)
			target_type = /obj/structure/cable
			target_layer = CABLE_LAYER_2
			novariants = FALSE
		if("Layer 3")
			set_cable_color(CABLE_COLOR_BLUE)
			target_type = /obj/structure/cable/layer3
			target_layer = CABLE_LAYER_3
			novariants = FALSE
		if("Multilayer cable hub")
			name = "multilayer cable hub"
			desc = "A multilayer cable hub."
			icon_state = "cable_bridge"
			set_cable_color(CABLE_COLOR_WHITE)
			target_type = /obj/structure/cable/multilayer
			target_layer = CABLE_LAYER_2
			novariants = TRUE
		if("Multi Z layer cable hub")
			name = "multi z layer cable hub"
			desc = "A multi-z layer cable hub."
			icon_state = "cablerelay-broken-cable"
			set_cable_color(CABLE_COLOR_WHITE)
			target_type = /obj/structure/cable/multilayer/multiz
			target_layer = CABLE_LAYER_2
			novariants = TRUE
		if("Cable restraints")
			if (amount >= CABLE_RESTRAINTS_COST)
				if(use(CABLE_RESTRAINTS_COST))
					var/obj/item/restraints/handcuffs/cable/restraints = new(null, cable_color)
					user.put_in_hands(restraints)
	update_appearance()


///////////////////////////////////
// General procedures
///////////////////////////////////
//you can use wires to heal robotics
/obj/item/stack/cable_coil/attack(mob/living/carbon/human/H, mob/user)
	if(!istype(H))
		return ..()

	var/obj/item/bodypart/affecting = H.get_bodypart(check_zone(user.zone_selected))
	if(affecting && IS_ROBOTIC_LIMB(affecting))
		if(user == H)
			user.visible_message(span_notice("[user] starts to fix some of the wires in [H]'s [affecting.name]."), span_notice("You start fixing some of the wires in [H == user ? "your" : "[H]'s"] [affecting.name]."))
			if(!do_after(user, 50, H))
				return
		if(item_heal_robotic(H, user, 0, 15))
			use(1)
		return
	else
		return ..()


///////////////////////////////////////////////
// Cable laying procedures
//////////////////////////////////////////////

// called when cable_coil is clicked on a turf
/obj/item/stack/cable_coil/proc/place_turf(turf/T, mob/user, dirnew)
	if(!isturf(user.loc))
		return

	if(!isturf(T) || T.underfloor_accessibility < UNDERFLOOR_INTERACTABLE || !T.can_have_cabling())
		to_chat(user, span_warning("You can only lay cables on catwalks and plating!"))
		return

	if(get_amount() < 1) // Out of cable
		to_chat(user, span_warning("There is no cable left!"))
		return

	if(get_dist(T,user) > 1) // Too far
		to_chat(user, span_warning("You can't lay cable at a place that far away!"))
		return

	for(var/obj/structure/cable/C in T)
		if(C.cable_layer & target_layer)
			to_chat(user, span_warning("There's already a cable at that position!"))
			return

	var/obj/structure/cable/C = new target_type(T)

	//create a new powernet with the cable, if needed it will be merged later
	var/datum/powernet/PN = new()
	PN.add_cable(C)

	for(var/dir_check in GLOB.cardinals)
		C.mergeConnectedNetworks(dir_check) //merge the powernet with adjacents powernets
	C.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets

	use(1)

	if(C.shock(user, 50))
		if(prob(50)) //fail
			C.deconstruct()

	return C

/obj/item/stack/cable_coil/five
	amount = 5

/obj/item/stack/cable_coil/cut
	amount = null

/obj/item/stack/cable_coil/cut/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	if(!amount)
		amount = rand(1,2)
	. = ..()
	pixel_x = base_pixel_x + rand(-2, 2)
	pixel_y = base_pixel_y + rand(-2, 2)
	update_appearance()

#undef CABLE_RESTRAINTS_COST
#undef UNDER_SMES
#undef UNDER_TERMINAL

///multilayer cable to connect different layers
/obj/structure/cable/multilayer
	name = "multilayer cable hub"
	desc = "A flexible, superconducting insulated multilayer hub for heavy-duty multilayer power transfer."
	icon = 'icons/obj/power.dmi'
	icon_state = "cable_bridge"
	cable_layer = CABLE_LAYER_2
	layer = WIRE_LAYER - 0.02 //Below all cables Disabled layers can lay over hub
	color = CABLE_COLOR_WHITE

/obj/structure/cable/multilayer/update_icon_state()
	SHOULD_CALL_PARENT(FALSE)
	return

/obj/structure/cable/multilayer/update_icon()
	. = ..()
	underlays.Cut()
	var/mutable_appearance/cable_node_3 = mutable_appearance('icons/obj/power_cond/layer_cable.dmi', "l4-1-2-4-8-node")
	cable_node_3.color = CABLE_COLOR_BLUE
	cable_node_3?.alpha = cable_layer & CABLE_LAYER_3 ? 255 : 0
	underlays += cable_node_3
	var/mutable_appearance/cable_node_2 = mutable_appearance('icons/obj/power_cond/layer_cable.dmi', "l2-1-2-4-8-node")
	cable_node_2.color = CABLE_COLOR_YELLOW
	cable_node_2?.alpha = cable_layer & CABLE_LAYER_2 ? 255 : 0
	underlays += cable_node_2
	var/mutable_appearance/cable_node_1 = mutable_appearance('icons/obj/power_cond/layer_cable.dmi', "l1-1-2-4-8-node")
	cable_node_1.color = CABLE_COLOR_RED
	cable_node_1?.alpha = cable_layer & CABLE_LAYER_1 ? 255 : 0
	underlays += cable_node_1
	var/mutable_appearance/machinery_node = mutable_appearance('icons/obj/power_cond/layer_cable.dmi', "l2-noconnection")
	machinery_node.color = "black"
	underlays += machinery_node

/obj/structure/cable/multilayer/Initialize(mapload)
	. = ..()
	var/turf/T = get_turf(src)
	for(var/obj/structure/cable/C in T.contents - src)
		if(C.cable_layer & cable_layer)
			C.deconstruct() // remove adversary cable
	if(!mapload)
		auto_propagate_cut_cable(src)

	update_appearance()

/obj/structure/cable/multilayer/examine(mob/user)
	. += ..()
	. += span_notice("L1:[cable_layer & CABLE_LAYER_1 ? "Connect" : "Disconnect"].")
	. += span_notice("L2:[cable_layer & CABLE_LAYER_2 ? "Connect" : "Disconnect"].")
	. += span_notice("L3:[cable_layer & CABLE_LAYER_3 ? "Connect" : "Disconnect"].")

GLOBAL_LIST(hub_radial_layer_list)

/obj/structure/cable/multilayer/attack_robot(mob/user)
	attack_hand(user)

/obj/structure/cable/multilayer/attack_hand(mob/living/user, list/modifiers)
	if(!user)
		return
	if(!GLOB.hub_radial_layer_list)
		GLOB.hub_radial_layer_list = list(
			"Layer 1" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-red"),
			"Layer 2" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-yellow"),
			"Layer 3" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-blue")
			)

	var/layer_result = show_radial_menu(user, src, GLOB.hub_radial_layer_list, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	var/CL
	switch(layer_result)
		if("Layer 1")
			CL = CABLE_LAYER_1
			to_chat(user, span_warning("You toggle L1 connection."))
		if("Layer 2")
			CL = CABLE_LAYER_2
			to_chat(user, span_warning("You toggle L2 connection."))
		if("Layer 3")
			CL = CABLE_LAYER_3
			to_chat(user, span_warning("You toggle L3 connection."))

	cut_cable_from_powernet(FALSE)

	Disconnect_cable()

	cable_layer ^= CL

	Connect_cable(TRUE)

	Reload()

/obj/structure/cable/multilayer/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

///Reset powernet in this hub.
/obj/structure/cable/multilayer/proc/Reload()
	var/turf/T = get_turf(src)
	for(var/obj/structure/cable/C in T.contents - src)
		if(C.cable_layer & cable_layer)
			C.deconstruct() // remove adversary cable
	auto_propagate_cut_cable(src) // update the powernets

/obj/structure/cable/multilayer/CtrlClick(mob/living/user)
	to_chat(user, span_warning("You push the reset button."))
	addtimer(CALLBACK(src, PROC_REF(Reload)), 10, TIMER_UNIQUE) //spam protect

// This is a mapping aid. In order for this to be placed on a map and function, all three layers need to have their nodes active
/obj/structure/cable/multilayer/connected
		cable_layer = CABLE_LAYER_1 | CABLE_LAYER_2 | CABLE_LAYER_3

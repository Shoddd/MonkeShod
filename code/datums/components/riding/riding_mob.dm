// For any mob that can be ridden

/datum/component/riding/creature
	/// If TRUE, this creature's movements can be controlled by the rider while mounted (as opposed to riding cyborgs and humans, which is passive)
	var/can_be_driven = TRUE
	/// If TRUE, this creature's abilities can be triggered by the rider while mounted
	var/can_use_abilities = FALSE
	var/list/shared_action_buttons = list()

/datum/component/riding/creature/Initialize(mob/living/riding_mob, force = FALSE, ride_check_flags = NONE, potion_boost = FALSE)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	. = ..()
	var/mob/living/living_parent = parent
	living_parent.stop_pulling() // was only used on humans previously, may change some other behavior
	log_riding(living_parent, riding_mob)
	riding_mob.set_glide_size(living_parent.glide_size)
	handle_vehicle_offsets(living_parent.dir)

	if(can_use_abilities)
		setup_abilities(riding_mob)

	if(isanimal(parent))
		var/mob/living/simple_animal/simple_parent = parent
		simple_parent.stop_automated_movement = TRUE

/datum/component/riding/creature/Destroy(force)
	unequip_buckle_inhands(parent)
	if(isanimal(parent))
		var/mob/living/simple_animal/simple_parent = parent
		simple_parent.stop_automated_movement = FALSE
	REMOVE_TRAIT(parent, TRAIT_AI_PAUSED, REF(src))
	return ..()

/datum/component/riding/creature/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_EMOTE, PROC_REF(check_emote))
	if(can_be_driven)
		RegisterSignal(parent, COMSIG_RIDDEN_DRIVER_MOVE, PROC_REF(driver_move)) // this isn't needed on riding humans or cyborgs since the rider can't control them

/// Creatures need to be logged when being mounted
/datum/component/riding/creature/proc/log_riding(mob/living/living_parent, mob/living/rider)
	if(!istype(living_parent) || !istype(rider))
		return

	living_parent.log_message("is now being ridden by [rider].", LOG_GAME, color="pink")
	rider.log_message("started riding [living_parent].", LOG_GAME, color="pink")

// this applies to humans and most creatures, but is replaced again for cyborgs
/datum/component/riding/creature/ride_check(mob/living/rider, consequences = TRUE)
	. = TRUE
	var/mob/living/living_parent = parent

	if(living_parent.body_position != STANDING_UP) // if we move while on the ground, the rider falls off
		. = FALSE
	// for piggybacks and (redundant?) borg riding, check if the rider is stunned/restrained
	else if((ride_check_flags & RIDER_NEEDS_ARMS) && (HAS_TRAIT(rider, TRAIT_RESTRAINED) || rider.incapacitated(IGNORE_RESTRAINTS|IGNORE_GRAB)))
		. = FALSE
	// for fireman carries, check if the ridden is stunned/restrained
	else if((ride_check_flags & CARRIER_NEEDS_ARM) && (HAS_TRAIT(living_parent, TRAIT_RESTRAINED) || living_parent.incapacitated(IGNORE_RESTRAINTS|IGNORE_GRAB)))
		. = FALSE

	if(. || !consequences)
		return

	rider.visible_message(span_warning("[rider] falls off of [living_parent]!"), \
					span_warning("You fall off of [living_parent]!"))
	rider.Paralyze(1 SECONDS)
	rider.Knockdown(4 SECONDS)
	living_parent.unbuckle_mob(rider)

/datum/component/riding/creature/vehicle_mob_buckle(mob/living/ridden, mob/living/rider, force = FALSE)
	// Ensure that the /mob/post_buckle_mob(mob/living/M) does not mess us up with layers
	// If we do not do this override we'll be stuck with the above proc (+ 0.1)-ing our rider's layer incorrectly
	rider.layer = initial(rider.layer)
	if(can_be_driven)
		//let the player take over if they should be controlling movement
		ADD_TRAIT(ridden, TRAIT_AI_PAUSED, REF(src))
	return ..()

/datum/component/riding/creature/vehicle_mob_unbuckle(mob/living/formerly_ridden, mob/living/former_rider, force = FALSE)
	if(istype(formerly_ridden) && istype(former_rider))
		formerly_ridden.log_message("is no longer being ridden by [key_name(former_rider)].", LOG_GAME, color="pink")
		former_rider.log_message("is no longer riding [key_name(formerly_ridden)].", LOG_GAME, color="pink")
	remove_abilities(former_rider)
	if(!formerly_ridden.buckled_mobs.len)
		REMOVE_TRAIT(formerly_ridden, TRAIT_AI_PAUSED, REF(src))
	// We gotta reset those layers at some point, don't we?
	former_rider.layer = MOB_LAYER
	formerly_ridden.layer = MOB_LAYER
	return ..()

/datum/component/riding/creature/driver_move(atom/movable/movable_parent, mob/living/user, direction)
	if(!COOLDOWN_FINISHED(src, vehicle_move_cooldown))
		return COMPONENT_DRIVER_BLOCK_MOVE
	if(!keycheck(user))
		if(ispath(keytype, /obj/item))
			var/obj/item/key = keytype
			to_chat(user, span_warning("You need a [initial(key.name)] to ride [movable_parent]!"))
		return COMPONENT_DRIVER_BLOCK_MOVE
	var/mob/living/living_parent = parent
	var/turf/next = get_step(living_parent, direction)
	step(living_parent, direction)
	last_move_diagonal = ((direction & (direction - 1)) && (living_parent.loc == next))
	COOLDOWN_START(src, vehicle_move_cooldown, (last_move_diagonal ? 2 : 1) * move_delay()) // monkestation edit: use move_delay() proc instead of raw vehicle_move_delay var
	return ..()

/datum/component/riding/creature/keycheck(mob/user)
	if(!keytype)
		return TRUE

	if(isvehicle(parent))
		var/obj/vehicle/vehicle_parent = parent
		return istype(vehicle_parent.inserted_key, keytype)

	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		for(var/obj/item/listed_item as anything in carbon_user.get_equipped_items())
			if(listed_item.type == keytype)
				return TRUE
		return FALSE
	else
		return user.is_holding_item_of_type(keytype)

/// Yeets the rider off, used for animals and cyborgs, redefined for humans who shove their piggyback rider off
/datum/component/riding/creature/proc/force_dismount(mob/living/rider, gentle = FALSE)
	var/atom/movable/movable_parent = parent
	movable_parent.unbuckle_mob(rider)

	if(!iscyborg(movable_parent) && !isanimal_or_basicmob(movable_parent))
		return

	var/turf/target = get_edge_target_turf(movable_parent, movable_parent.dir)
	var/turf/targetm = get_step(get_turf(movable_parent), movable_parent.dir)
	rider.Move(targetm)
	rider.Knockdown(3 SECONDS)
	if(gentle)
		rider.visible_message(span_warning("[rider] is thrown clear of [movable_parent]!"), \
		span_warning("You're thrown clear of [movable_parent]!"))
		rider.throw_at(target, 8, 3, movable_parent, gentle = TRUE)
	else
		rider.visible_message(span_warning("[rider] is thrown violently from [movable_parent]!"), \
		span_warning("You're thrown violently from [movable_parent]!"))
		rider.throw_at(target, 14, 5, movable_parent, gentle = FALSE)

/// If we're a cyborg or animal and we spin, we yeet whoever's on us off us
/datum/component/riding/creature/proc/check_emote(mob/living/user, datum/emote/emote)
	SIGNAL_HANDLER
	if((!iscyborg(user) && !isanimal_or_basicmob(user)) || !istype(emote, /datum/emote/spin))
		return

	for(var/mob/yeet_mob in user.buckled_mobs)
		force_dismount(yeet_mob, (!(user.istate & ISTATE_HARM))) // gentle on help, byeeee if not

/// If the ridden creature has abilities, and some var yet to be made is set to TRUE, the rider will be able to control those abilities
/datum/component/riding/creature/proc/setup_abilities(mob/living/rider)
	if(!isliving(parent))
		return

	var/mob/living/ridden_creature = parent

	for(var/datum/action/action as anything in ridden_creature.actions)
		action.GiveAction(rider)

/// Takes away the riding parent's abilities from the rider
/datum/component/riding/creature/proc/remove_abilities(mob/living/rider)
	if(!isliving(parent))
		return

	var/mob/living/ridden_creature = parent

	for(var/datum/action/action as anything in ridden_creature.actions)
		if(istype(action, /datum/action/cooldown) && rider.click_intercept == action)
			var/datum/action/cooldown/cooldown_action = action
			cooldown_action.unset_click_ability(rider, refund_cooldown = TRUE)
		action.HideFrom(rider)

/datum/component/riding/creature/riding_can_z_move(atom/movable/movable_parent, direction, turf/start, turf/destination, z_move_flags, mob/living/rider)
	if(!(z_move_flags & ZMOVE_CAN_FLY_CHECKS))
		return COMPONENT_RIDDEN_ALLOW_Z_MOVE
	if(!can_be_driven)
		if(z_move_flags & ZMOVE_FEEDBACK)
			to_chat(rider, span_warning("[movable_parent] cannot be driven around. Unbuckle from [movable_parent.p_them()] first."))
		return COMPONENT_RIDDEN_STOP_Z_MOVE
	if(!ride_check(rider, FALSE))
		if(z_move_flags & ZMOVE_FEEDBACK)
			to_chat(rider, span_warning("You're unable to ride [movable_parent] right now!"))
		return COMPONENT_RIDDEN_STOP_Z_MOVE
	return COMPONENT_RIDDEN_ALLOW_Z_MOVE


///////Yes, I said humans. No, this won't end well...//////////
/datum/component/riding/creature/human
	can_be_driven = FALSE

/datum/component/riding/creature/human/Initialize(mob/living/riding_mob, force = FALSE, ride_check_flags = NONE, potion_boost = FALSE)
	. = ..()
	var/mob/living/carbon/human/human_parent = parent
	human_parent.add_movespeed_modifier(/datum/movespeed_modifier/human_carry)

	if(ride_check_flags & RIDER_NEEDS_ARMS) // piggyback
		human_parent.buckle_lying = 0
		// the riding mob is made nondense so they don't bump into any dense atoms the carrier is pulling,
		// since pulled movables are moved before buckled movables
		ADD_TRAIT(riding_mob, TRAIT_UNDENSE, VEHICLE_TRAIT)
	else if(ride_check_flags & CARRIER_NEEDS_ARM) // fireman
		human_parent.buckle_lying = 90

/datum/component/riding/creature/human/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_HUMAN_EARLY_UNARMED_ATTACK, PROC_REF(on_host_unarmed_melee))
	RegisterSignal(parent, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(check_carrier_fall_over))

/datum/component/riding/creature/human/log_riding(mob/living/living_parent, mob/living/rider)
	if(!istype(living_parent) || !istype(rider))
		return

	if(ride_check_flags & RIDER_NEEDS_ARMS) // piggyback
		living_parent.log_message("started giving [key_name(rider)] a piggyback ride.", LOG_GAME, color="pink")
		rider.log_message("started piggyback riding [key_name(living_parent)].", LOG_GAME, color="pink")
	else if(ride_check_flags & CARRIER_NEEDS_ARM) // fireman
		living_parent.log_message("started fireman carrying [key_name(rider)].", LOG_GAME, color="pink")
		rider.log_message("was fireman carried by [key_name(living_parent)].", LOG_GAME, color="pink")

/datum/component/riding/creature/human/vehicle_mob_unbuckle(datum/source, mob/living/former_rider, force = FALSE)
	unequip_buckle_inhands(parent)
	var/mob/living/carbon/human/H = parent
	H.remove_movespeed_modifier(/datum/movespeed_modifier/human_carry)
	REMOVE_TRAIT(former_rider, TRAIT_UNDENSE, VEHICLE_TRAIT)
	return ..()

/// If the carrier shoves the person they're carrying, force the carried mob off
/datum/component/riding/creature/human/proc/on_host_unarmed_melee(mob/living/carbon/human/human_parent, atom/target, proximity, modifiers)
	SIGNAL_HANDLER

	if((human_parent.istate & ISTATE_SECONDARY) && (target in human_parent.buckled_mobs))
		force_dismount(target)
		return COMPONENT_CANCEL_ATTACK_CHAIN

/// If the carrier gets knocked over, force the rider(s) off and see if someone got hurt
/datum/component/riding/creature/human/proc/check_carrier_fall_over(mob/living/carbon/human/human_parent)
	SIGNAL_HANDLER

	for(var/i in human_parent.buckled_mobs)
		var/mob/living/rider = i
		human_parent.unbuckle_mob(rider)
		rider.Paralyze(1 SECONDS)
		rider.Knockdown(4 SECONDS)
		human_parent.visible_message(span_danger("[rider] topples off of [human_parent] as they both fall to the ground!"), \
					span_warning("You fall to the ground, bringing [rider] with you!"), span_hear("You hear two consecutive thuds."), COMBAT_MESSAGE_RANGE, ignored_mobs=rider)
		to_chat(rider, span_danger("[human_parent] falls to the ground, bringing you with [human_parent.p_them()]!"))

/datum/component/riding/creature/human/handle_vehicle_layer(dir)
	var/atom/movable/AM = parent
	if(!AM.buckled_mobs || !AM.buckled_mobs.len)
		AM.layer = MOB_LAYER
		return

	for(var/mob/M in AM.buckled_mobs) //ensure proper layering of piggyback and carry, sometimes weird offsets get applied
		M.layer = MOB_LAYER

	if(!AM.buckle_lying) // rider is vertical, must be piggybacking
		if(dir == SOUTH)
			AM.layer = MOB_ABOVE_PIGGYBACK_LAYER
		else
			AM.layer = MOB_BELOW_PIGGYBACK_LAYER
	else  // laying flat, we must be firemanning the rider
		if(dir == NORTH)
			AM.layer = MOB_BELOW_PIGGYBACK_LAYER
		else
			AM.layer = MOB_ABOVE_PIGGYBACK_LAYER

/datum/component/riding/creature/human/get_offsets(pass_index)
	var/mob/living/carbon/human/H = parent
	if(H.buckle_lying)
		return list(TEXT_NORTH = list(0, 6), TEXT_SOUTH = list(0, 6), TEXT_EAST = list(0, 6), TEXT_WEST = list(0, 6))
	else
		return list(TEXT_NORTH = list(0, 6), TEXT_SOUTH = list(0, 6), TEXT_EAST = list(-6, 4), TEXT_WEST = list( 6, 4))

/datum/component/riding/creature/human/force_dismount(mob/living/dismounted_rider)
	var/atom/movable/AM = parent
	AM.unbuckle_mob(dismounted_rider)
	dismounted_rider.Paralyze(1 SECONDS)
	dismounted_rider.Knockdown(4 SECONDS)
	dismounted_rider.visible_message(span_warning("[AM] pushes [dismounted_rider] off of [AM.p_them()]!"), \
						span_warning("[AM] pushes you off of [AM.p_them()]!"))


//Now onto cyborg riding//
/datum/component/riding/creature/cyborg
	can_be_driven = FALSE

/datum/component/riding/creature/cyborg/ride_check(mob/living/user, consequences = TRUE)
	var/mob/living/silicon/robot/robot_parent = parent
	if(!iscarbon(user))
		return TRUE
	. = user.usable_hands
	if(!. && consequences)
		Unbuckle(user)
		to_chat(user, span_warning("You can't grab onto [robot_parent] with no hands!"))

/datum/component/riding/creature/cyborg/handle_vehicle_layer(dir)
	var/atom/movable/robot_parent = parent
	if(dir == SOUTH)
		robot_parent.layer = MOB_ABOVE_PIGGYBACK_LAYER
	else
		robot_parent.layer = MOB_BELOW_PIGGYBACK_LAYER

/datum/component/riding/creature/cyborg/get_offsets(pass_index) // list(dir = x, y, layer)
	return list(TEXT_NORTH = list(0, 4), TEXT_SOUTH = list(0, 4), TEXT_EAST = list(-6, 3), TEXT_WEST = list( 6, 3))

/datum/component/riding/creature/cyborg/handle_vehicle_offsets(dir)
	var/mob/living/silicon/robot/robot_parent = parent

	for(var/mob/living/rider in robot_parent.buckled_mobs)
		rider.setDir(dir)
		if(istype(robot_parent.model))
			if(dir2text(dir) in robot_parent.model.ride_offset_x)
				rider.pixel_x = robot_parent.model.ride_offset_x[dir2text(dir)]
			if(dir2text(dir) in robot_parent.model.ride_offset_y)
				rider.pixel_y = robot_parent.model.ride_offset_y[dir2text(dir)]

//now onto every other ridable mob//

/datum/component/riding/creature/mulebot/handle_specials()
	. = ..()
	var/atom/movable/movable_parent = parent
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 12), TEXT_SOUTH = list(0, 12), TEXT_EAST = list(0, 12), TEXT_WEST = list(0, 12)))
	set_vehicle_dir_layer(SOUTH, movable_parent.layer) //vehicles default to ABOVE_MOB_LAYER while moving, let's make sure that doesn't happen while a mob is riding us.
	set_vehicle_dir_layer(NORTH, movable_parent.layer)
	set_vehicle_dir_layer(EAST, movable_parent.layer)
	set_vehicle_dir_layer(WEST, movable_parent.layer)


/datum/component/riding/creature/cow/handle_specials()
	. = ..()
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 8), TEXT_SOUTH = list(0, 8), TEXT_EAST = list(-2, 8), TEXT_WEST = list(2, 8)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)

/datum/component/riding/creature/pig/handle_specials()
	. = ..()
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 8), TEXT_SOUTH = list(0, 8), TEXT_EAST = list(-2, 8), TEXT_WEST = list(2, 8)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)

/datum/component/riding/creature/pony/handle_specials()
	. = ..()
	vehicle_move_delay = 1.5
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 9), TEXT_SOUTH = list(0, 9), TEXT_EAST = list(-2, 9), TEXT_WEST = list(2, 9)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)

/datum/component/riding/creature/pony
	COOLDOWN_DECLARE(pony_trot_cooldown)

/datum/component/riding/creature/pony/driver_move(atom/movable/movable_parent, mob/living/user, direction)
	. = ..()

	if (. == COMPONENT_DRIVER_BLOCK_MOVE || !COOLDOWN_FINISHED(src, pony_trot_cooldown))
		return

	var/mob/living/carbon/human/human_user = user

	if(human_user && is_clown_job(human_user.mind?.assigned_role))
		// there's a new sheriff in town
		playsound(movable_parent, 'sound/creatures/pony/clown_gallup.ogg', 50)
		COOLDOWN_START(src, pony_trot_cooldown, 500 MILLISECONDS)


/datum/component/riding/creature/bear/handle_specials()
	. = ..()
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(1, 8), TEXT_SOUTH = list(1, 8), TEXT_EAST = list(-3, 6), TEXT_WEST = list(3, 6)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(WEST, ABOVE_MOB_LAYER)


/datum/component/riding/creature/carp
	override_allow_spacemove = TRUE

/datum/component/riding/creature/carp/handle_specials()
	. = ..()
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 13), TEXT_SOUTH = list(0, 15), TEXT_EAST = list(-2, 12), TEXT_WEST = list(2, 12)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)


/datum/component/riding/creature/megacarp/handle_specials()
	. = ..()
	var/atom/movable/movable_parent = parent
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(1, 8), TEXT_SOUTH = list(1, 8), TEXT_EAST = list(-3, 6), TEXT_WEST = list(3, 6)))
	set_vehicle_dir_offsets(SOUTH, movable_parent.pixel_x, 0)
	set_vehicle_dir_offsets(NORTH, movable_parent.pixel_x, 0)
	set_vehicle_dir_offsets(EAST, movable_parent.pixel_x, 0)
	set_vehicle_dir_offsets(WEST, movable_parent.pixel_x, 0)
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)

/datum/component/riding/creature/vatbeast
	override_allow_spacemove = TRUE
	can_use_abilities = TRUE

/datum/component/riding/creature/vatbeast/handle_specials()
	. = ..()
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 15), TEXT_SOUTH = list(0, 15), TEXT_EAST = list(-10, 15), TEXT_WEST = list(10, 15)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)

/datum/component/riding/creature/goliath
	vehicle_move_delay = 4

/datum/component/riding/creature/goliath/Initialize(mob/living/riding_mob, force, ride_check_flags, potion_boost)
	. = ..()
	var/mob/living/basic/mining/goliath/goliath = parent
	goliath.add_movespeed_modifier(/datum/movespeed_modifier/goliath_mount)

/datum/component/riding/creature/goliath/Destroy(force)
	var/mob/living/basic/mining/goliath/goliath = parent
	goliath.remove_movespeed_modifier(/datum/movespeed_modifier/goliath_mount)
	return ..()

/datum/component/riding/creature/goliath/handle_specials()
	. = ..()
	set_vehicle_offsets(list(TEXT_NORTH = list(-12, 0), TEXT_SOUTH = list(-12, 0), TEXT_EAST = list(-12, 0), TEXT_WEST = list(-12, 0)))
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 12), TEXT_SOUTH = list(0, 12), TEXT_EAST = list(-4, 12), TEXT_WEST = list(3, 12)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)

/datum/component/riding/creature/glutton/handle_specials()
	. = ..()
	var/atom/movable/movable_parent = parent
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 24), TEXT_SOUTH = list(0, 24), TEXT_EAST = list(-16, 24), TEXT_WEST = list(16, 24)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(WEST, ABOVE_MOB_LAYER)
	set_vehicle_dir_offsets(SOUTH, movable_parent.pixel_x, 0)
	set_vehicle_dir_offsets(NORTH, movable_parent.pixel_x, 0)
	set_vehicle_dir_offsets(EAST, movable_parent.pixel_x, 0)
	set_vehicle_dir_offsets(WEST, movable_parent.pixel_x, 0)

/datum/component/riding/creature/guardian
	can_be_driven = FALSE

/datum/component/riding/creature/guardian/handle_specials()
	. = ..()
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 4), TEXT_SOUTH = list(0, 4), TEXT_EAST = list(-6, 3), TEXT_WEST = list(6, 3)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(WEST, ABOVE_MOB_LAYER)

/datum/component/riding/creature/guardian/ride_check(mob/living/user, consequences = TRUE)
	var/mob/living/basic/guardian/charger = parent
	if(!istype(charger))
		return ..()
	return charger.summoner == user

/datum/component/riding/creature/goldgrub

/datum/component/riding/creature/goldgrub/handle_specials()
	. = ..()
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(11, 3), TEXT_SOUTH = list(11, 3), TEXT_EAST = list(9, 3), TEXT_WEST = list(14, 3)))
	set_vehicle_dir_layer(SOUTH, ABOVE_MOB_LAYER)
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)

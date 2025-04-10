#define C_OPENED 0
#define C_CLOSED 1

/obj/structure/cage
	name = "cage"
	desc = "A large and heavy plasteel box, used to store dangerous animals and humans. It has two doors - the outer \"cover\", and the inner \"bars\". The cover is a thin plasteel sheet with tiny holes in the corners to let air through. The bars consist of thick plasteel rods, evenly spaced apart."

	density = FALSE
	anchored = FALSE
	icon = 'monkestation/icons/obj/cage.dmi' // Would be neat to impliement the animations some day.
	icon_state = "cage_base"
	max_integrity = 225
	drag_slowdown = 1.5
	armor_type = /datum/armor/structure_closet
	integrity_failure = 0

	// Are our bars and shutters open or closed?
	var/cover_state = C_OPENED
	var/door_state = C_OPENED
	// How long it takes to open or close the bars of the cage
	var/open_bar_time = 15 SECONDS
	var/close_bar_time = 5 SECONDS
	// How long to takes to put the shutter down and up
	var/open_cover_time = 15 SECONDS
	var/close_cover_time = 15 SECONDS
	// Break out time, if shutter is down they need to open it first
	var/breakout_time = 180 SECONDS
	// Time to force open, with hot objects, or items over 20 force
	var/force_open_time = 5 SECONDS

	// Largest mob type that can be stored
	var/max_mob_size = MOB_SIZE_LARGE
	// How many mobs can we fit
	var/mob_storage_capacity = 1

	var/open_sound = null
	var/close_sound = null



/obj/structure/cage/Destroy()
	switch(cover_state)
		if(C_OPENED)
			for(var/mob/living/L in buckled_mobs)
				qdel(L)
		if(C_CLOSED)
			for(var/atom/movable/M in contents)
				qdel(M)
	..()

/obj/structure/cage/update_icon()
	overlays = list()
// Code I left over, if this comment is here I forgot to update it
	if(cover_state == C_CLOSED)
		var/image/cover_overlay = image('monkestation/icons/obj/cage.dmi', icon_state = "cage_cover", layer = ABOVE_ALL_MOB_LAYER)
		cover_overlay.plane = ABOVE_ALL_MOB_LAYER
		overlays += cover_overlay
	else if(door_state == C_CLOSED) //Door is only visible when the cover is open
		var/image/door_overlay = image('monkestation/icons/obj/cage.dmi', icon_state = "cage_door", layer = ABOVE_ALL_MOB_LAYER)
		door_overlay.plane = ABOVE_ALL_MOB_LAYER
		overlays += door_overlay
	return ..()
/*
/obj/structure/cage/ex_act(var/severity)
	var/list/affected_mobs = severity < 3 ? remove_mobs() : get_mobs()
	for(var/atom/movable/M in affected_mobs)
		M.ex_act(severity)
	..()
*/

/obj/structure/cage/AltClick()
	if(Adjacent(usr) && !usr.incapacitated() && !mob_is_inside(usr))
		toggle_cover(usr)

/obj/structure/cage/attackby(obj/item/held_item, mob/user)
	if(door_state == C_CLOSED)
		if(held_item.force >= 20 && (held_item.get_sharpness() >= 1 || held_item.heat <= 700))

			user.visible_message("<span class='danger'>[user] starts forcing \the [src]'s door open with \the [held_item]!</span>", "<span class='info'>You start forcing \the [src]'s door open with \the [held_item]. This will take around [(force_open_time / 10)] seconds.</span>")
			if(do_after(user, force_open_time, src))
				if(door_state == C_CLOSED)
					toggle_door(user)

		else
			if(held_item.force < 20) //Force
				to_chat(user, "<span class='info'>\The [held_item] won't damage \the [src]'s bars.</span>")
			else //No sharpness/hotness
				to_chat(user, "<span class='info'>\The [held_item] isn't sharp or hot enough to cut through \the [src]'s bars!</span>")

/obj/structure/cage/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(isinspace() && !anchored)
		balloon_alert(user, "nothing to anchor to!")
		return TRUE
	set_anchored(!anchored)
	tool.play_tool_sound(src, 75)
	user.balloon_alert_to_viewers("[anchored ? "anchored" : "unanchored"]")
	return TRUE

/obj/structure/cage/relaymove(mob/living/user)
	if(!istype(user))
		return

	if(cover_state == C_CLOSED)
		to_chat(user, "<span class='info'>You attempt to open \the [src]'s cover from inside. This will take around [(open_cover_time / 10)] seconds.</span>")
		if(do_after(user, open_cover_time, src))
			if(cover_state == C_CLOSED)
				toggle_cover(user)
		return
	else
		container_resist_act(user)

/obj/structure/cage/attack_hand(mob/living/user)
	if(!istype(user))
		return

	if(mob_is_inside(user)) //Inside the cage
		if(door_state == C_CLOSED)
			to_chat(user, "<span class='info'>You attempt to open \the [src]'s door from inside. This will take around [(breakout_time / 10)] seconds.</span>")
			if(do_after(user, breakout_time, src))
				if(door_state == C_CLOSED)
					toggle_door(user)
	else
		if(door_state == C_CLOSED)
			user.visible_message("<span class='notice'>\The [user] attempts to open \the [src]!</span>")
			var/current_door_state = door_state
			if(do_after(user, close_bar_time, src)) //Closing / opening the cage takes 3 seconds
				if(door_state == current_door_state)
					toggle_door(user)
					user.visible_message("<span class='notice'>\The [user] opens \the [src]!</span>", \
					"<span class='info'>You open \the [src].</span>")
			return 0
		if(door_state == C_OPENED)
			user.visible_message("<span class='notice'>\The [user] attempts to close \the [src]!</span>")
			var/current_door_state = door_state
			if(do_after(user, open_bar_time, src)) //Closing / opening the cage takes 3 seconds
				if(door_state == current_door_state)
					toggle_door(user)
					user.visible_message("<span class='notice'>\The [user] closes \the [src]!</span>", \
					"<span class='info'>You close \the [src].</span>")
		return 1

/obj/structure/cage/attack_robot(mob/living/user)
	if(Adjacent(user))
		attack_hand(user)

//How the cage cover is implemented
//When it's closed, mobs are stored in the cage's contents. This causes them to be unable to interact with the outside world or move
//When it's opened, mobs are atom locked to the cage. This causes them to be able to interact with the outside world, but they still can't move
/obj/structure/cage/proc/toggle_cover(mob/user)
	if(door_state == C_OPENED) //Only when door is opened
		return

	if(cover_state == C_OPENED)
		cover_state = C_CLOSED
		if(user)
			user.visible_message("<span class='info'>\The [user] closes \the [src]'s cover.</span>")

		for(var/mob/living/L in buckled_mobs) //Move atom locked mobs inside
			unbuckle_mob(L)
	//		log_admin("[key_name(usr)] has covered \the [L] in their cage at [formatJumpTo(src)]")
	//		message_admins("[key_name(usr)] has covered \the [L] in their cage at [formatJumpTo(src)]")
			L.forceMove(src)

	else
		cover_state = C_OPENED
		if(user)
			user.visible_message("<span class='info'>\The [user] opens \the [src]'s cover.</span>")

		for(var/mob/living/L in contents) //Move hidden mobs to the outside
			L.forceMove(get_turf(src))
	//		log_admin("[key_name(usr)] has uncovered \the [L] from their cage at [formatJumpTo(src)]")
	//		message_admins("[key_name(usr)] has uncovered \the [L] from their cage at [formatJumpTo(src)]")
			buckle_mob(L)

	update_icon()

/obj/structure/cage/proc/toggle_door(mob/user)
	switch(door_state)
		if(C_OPENED) //Close the door
			if(cover_state == C_OPENED)
				toggle_cover() //Close the cover, too

			for(var/mob/living/L in get_turf(src))
				if(L.mob_size >= max_mob_size)
					continue
				add_mob(L)
		//		log_admin("[key_name(usr)] has trapped \the [L] in a cage at [formatJumpTo(src)]")
		//		message_admins("[key_name(usr)] has trapped \the [L] in a cage at [formatJumpTo(src)]")


			door_state = C_CLOSED
			density = TRUE

		if(C_CLOSED) //Open the door
			if(cover_state == C_CLOSED)
				toggle_cover() //Open the cover, too

			for(var/mob/living/L in (contents + buckled_mobs))
				unbuckle_mob(L)
			//	log_admin("[key_name(usr)] has released \the [L] from their cage at [formatJumpTo(src)]")
			//	message_admins("[key_name(usr)] has released \the [L] from their cage at [formatJumpTo(src)]")
				L.forceMove(get_turf(src))

			door_state = C_OPENED
			density = FALSE

	playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
	update_icon()

/obj/structure/cage/proc/add_mob(mob/victim)
	switch(cover_state)
		if(C_OPENED) //Cover is opened - mob is atom locked to the cage
			victim.forceMove(get_turf(src))
			buckle_mob(victim, src)
			to_chat(victim, "<span class='notice'>You suddenly find yourself locked in a cage!</span>")
		if(C_CLOSED) //Cover is closed - mob is stored inside the cage
			victim.forceMove(src)
			to_chat(victim, "<span class='notice'>You suddenly find yourself locked in a cage!</span>")

/obj/structure/cage/proc/mob_is_inside(mob/checked)
	if (contents.Find(checked))
		return TRUE

	return checked in buckled_mobs

/obj/structure/cage/proc/get_mobs()
	switch(cover_state)
		if(C_OPENED)
			. = buckled_mobs
		if(C_CLOSED)
			. = contents

/obj/structure/cage/proc/remove_mobs()
	. = list()
	switch(cover_state)
		if(C_OPENED) //Cover is opened - mob is atom unlocked from the cage
			for(var/mob/living/L in buckled_mobs)
				unbuckle_mob(L)
				. |= L
		if(C_CLOSED) //Cover is closed - mob is removed from the cage
			for(var/atom/movable/M in contents)
				M.forceMove(src.loc)
				. |= M

/obj/structure/cage/debug
	name = "debug cage"
	desc = "you probably shouldn't be seeing this"
	open_bar_time = 1 SECONDS
	close_bar_time = 1 SECONDS
	open_cover_time = 1 SECONDS
	close_cover_time = 1 SECONDS
	breakout_time = 1 SECONDS
	max_mob_size = MOB_SIZE_HUGE

/obj/structure/cage/gay // Admin only
	name = "Gay baby jail"
	desc = "WAAAH"
	max_integrity = INFINITY
	open_bar_time = 600 SECONDS
	close_bar_time = 10 SECONDS
	open_cover_time = 600 SECONDS
	close_cover_time = 10 SECONDS
	breakout_time = 600 SECONDS
	max_mob_size = MOB_SIZE_HUGE // Nothing is safe

#undef C_OPENED
#undef C_CLOSED

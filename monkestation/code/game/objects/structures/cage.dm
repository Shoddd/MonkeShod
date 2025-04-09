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
	var/bar_time = 6 SECONDS
	// How long to takes to put the shutter down and up
	var/shutter_time = 15 SECONDS

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
	if(cover_state == C_CLOSED)// DONT KEEP THIS LAYER
		var/image/cover_overlay = image('monkestation/icons/obj/cage.dmi', icon_state = "cage_cover", layer = ABOVE_MOB_LAYER) // DONT KEEP THIS LAYER
		cover_overlay.plane = ABOVE_MOB_LAYER // DONT KEEP THIS LAYER
		overlays += cover_overlay// DONT KEEP THIS LAYER
	else if(door_state == C_CLOSED) //Door is only visible when the cover is open
		var/image/door_overlay = image('monkestation/icons/obj/cage.dmi', icon_state = "cage_door", layer = ABOVE_MOB_LAYER) // DONT KEEP THIS LAYER
		door_overlay.plane = ABOVE_MOB_LAYER // DONT KEEP THIS LAYER
		overlays += door_overlay// DONT KEEP THIS LAYER
	return ..()

/obj/structure/cage/ex_act(var/severity)
	var/list/affected_mobs = severity < 3 ? remove_mobs() : get_mobs()
	for(var/atom/movable/M in affected_mobs)
		M.ex_act(severity)
	..()

/obj/structure/cage/relaymove(mob/living/user)
	if(!istype(user))
		return

	if(cover_state == C_CLOSED)
		var/time = 30 SECONDS

		to_chat(user, "<span class='info'>You attempt to open \the [src]'s cover from inside. This will take around [(time / 10)] seconds.</span>")
		if(do_after(user, time + rand(-5 SECONDS, 5 SECONDS), src))
			if(cover_state == C_CLOSED)
				toggle_cover(user)
		return
	else
		container_resist_act(user)


#undef C_OPENED
#undef C_CLOSED

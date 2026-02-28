/obj/item/melee/razorwire
	name = "implanted razorwire"
	desc = "A long length of monomolecular filament, built into the back of your hand. \
		Impossibly thin and flawlessly sharp, it should slice through organic materials with no trouble; \
		even from a few steps away. However, results against anything more durable will heavily vary."
	icon = 'monkestation/code/modules/cybernetics/icons/implants.dmi'
	icon_state = "razorwire_weapon"
	lefthand_file = 'monkestation/code/modules/cybernetics/icons/swords_lefthand.dmi'
	righthand_file = 'monkestation/code/modules/cybernetics/icons/swords_righthand.dmi'
	inhand_icon_state = "razorwire"
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	force = 15
	demolition_mod = 0.25 // This thing sucks at destroying stuff
	wound_bonus = -10 // Very weak against armor.
	bare_wound_bonus = 25
	weak_against_armour = TRUE
	reach = 2
	hitsound = 'sound/weapons/whip.ogg'
	attack_verb_continuous = list("slashes", "whips", "lashes", "lacerates")
	attack_verb_simple = list("slash", "whip", "lash", "lacerate")
	var/additional_distance = 3
	var/datum/component/leash/tracked_component
	var/atom/movable/leashed_atom
	COOLDOWN_DECLARE(ensnare)

/obj/item/melee/razorwire/attack_self(mob/user, modifiers)
	. = ..()
	if(!tracked_component)
		return
	var/obj/item/some_item = user.get_inactive_held_item()
	if(some_item || !isitem(leashed_atom))
		return
	user.put_in_inactive_hand(leashed_atom)

/obj/item/melee/razorwire/on_thrown(mob/living/carbon/user, atom/target)
	if(!target || !user)
		return

	if(!leashed_atom)
		return
	//Only items can be thrown 10 tiles everything else only 1 tile
	leashed_atom.throw_at(target, 5, 1,user)
	var/turf/start_turf = get_turf(leashed_atom)
	var/turf/end_turf = get_turf(target)
	user.log_message("has thrown [leashed_atom] from [AREACOORD(start_turf)] towards [AREACOORD(end_turf)] using Telekinesis.", LOG_ATTACK)
	user.changeNext_move(CLICK_CD_RAZOR_WIRE)

/obj/item/melee/razorwire/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ismovable(interacting_with) || tracked_component || !COOLDOWN_FINISHED(src, ensnare))
		return

	var/atom/movable/movable = interacting_with
	if(movable.anchored)
		return
	if(isliving(movable))
		return

	if((get_dist(user, interacting_with) > 4 && get_dist(user, interacting_with) < interacting_with))
		return

	var/total_dist  = get_dist(user, interacting_with) + additional_distance

	if(!CheckToolReach(user, interacting_with, 4))
		return

	tracked_component = movable.AddComponent(/datum/component/leash, src, total_dist, beam_icon_state = "razorwire", beam_icon = 'icons/effects/beam.dmi', force_teleports = FALSE)
	leashed_atom = movable
	user.visible_message(span_danger("[user] ensnares [movable] in razorwire tethering them!"))
	var/tether_time = 60 SECONDS
	if(isitem(movable))
		tether_time *= 2

	addtimer(CALLBACK(src, PROC_REF(disconnect)), tether_time)
	COOLDOWN_START(src, ensnare, 10 SECONDS)

/obj/item/melee/razorwire/proc/disconnect()
	if(!tracked_component)
		return
	QDEL_NULL(tracked_component)

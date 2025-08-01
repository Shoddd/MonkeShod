///Telekinesis lets you interact with objects from range, and gives you a light blue halo around your head.
/datum/mutation/telekinesis
	name = "Telekinesis"
	desc = "A strange mutation that allows the holder to interact with objects through thought."
	quality = POSITIVE
	difficulty = 18
	text_gain_indication = "<span class='notice'>You feel smarter!</span>"
	limb_req = BODY_ZONE_HEAD
	instability = 30
	///Typecache of atoms that TK shouldn't interact with
	var/static/list/blacklisted_atoms = typecacheof(list(/atom/movable/screen))

/datum/mutation/telekinesis/New(datum/mutation/copymut)
	..()
	if(!(type in visual_indicators))
		visual_indicators[type] = list(mutable_appearance('icons/effects/genetics.dmi', "telekinesishead", -MUTATIONS_LAYER))

/datum/mutation/telekinesis/on_acquiring(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	RegisterSignal(H, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_ranged_attack))

/datum/mutation/telekinesis/on_losing(mob/living/carbon/human/H)
	. = ..()
	if(.)
		return
	UnregisterSignal(H, COMSIG_MOB_ATTACK_RANGED)

/* Moved to 'monkestation/code/datums/mutations/telekinesis.dm'
/datum/mutation/telekinesis/get_visual_indicator()
	return visual_indicators[type][1]
*/

///Triggers on COMSIG_MOB_ATTACK_RANGED. Usually handles stuff like picking up items at range.
/datum/mutation/telekinesis/proc/on_ranged_attack(mob/source, atom/target)
	SIGNAL_HANDLER
	if(is_type_in_typecache(target, blacklisted_atoms))
		return
	if(!tkMaxRangeCheck(source, target) || source.z != target.z)
		return
//	return target.attack_tk(source) // MONKESTATION EDIT OLD
	return target.attack_tk(source, GET_MUTATION_POWER(src) > 1 ? TRUE : FALSE) // MONKESTATION EDIT NEW

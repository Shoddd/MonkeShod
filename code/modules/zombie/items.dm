/obj/item/mutant_hand/zombie
	name = "zombie claw"
	desc = "A zombie's claw is its primary tool, capable of infecting \
		humans, butchering all other living things to \
		sustain the zombie, smashing open airlock doors and opening \
		child-safe caps on bottles."

	hitsound = 'sound/hallucinations/growl1.ogg'
	force = 21 // Just enough to break airlocks with melee attacks
	wound_bonus = -30
	bare_wound_bonus = 15
	sharpness = SHARP_EDGED

/obj/item/mutant_hand/zombie/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return
	else if(isliving(target))
		var/mob/living/living_target = target
		if(!highly_infecious && living_target.stat != DEAD)
			return
		if(ishuman(target))
			try_to_zombie_infect(target, user, user.zone_selected)
		/*else monkestation temp removal
			. |= AFTERATTACK_PROCESSED_ITEM
			check_feast(target, user)*/

/proc/try_to_zombie_infect(mob/living/carbon/human/target, mob/living/user, def_zone = BODY_ZONE_CHEST)
	CHECK_DNA_AND_SPECIES(target)

	// Can't zombify with no head
	if(!target.get_bodypart(BODY_ZONE_HEAD))
		return

	if(HAS_TRAIT(target, TRAIT_NO_ZOMBIFY))
		// cannot infect any NOZOMBIE subspecies (such as high functioning
		// zombies)
		return

	// spaceacillin has a 75% chance to block infection
	if(HAS_TRAIT(target, TRAIT_VIRUS_RESISTANCE) && prob(75))
		return

	var/obj/item/bodypart/actual_limb = target.get_bodypart(def_zone)

	// What you hitting bro?
	if(!actual_limb)
		return

	var/limb_damage = actual_limb.get_damage()
	var/limb_armor = max(0, target.getarmor(actual_limb, BIO) - 25)

	// This is a pretty jank way to do this, but in short:
	// if they have thick material on that bodypart it will always need at least 25 previous limb damage to trigger an infection.
	// and if their bio armor isn't thick it's a bit weaker.
	for(var/obj/item/clothing/iter_clothing in target.get_clothing_on_part(actual_limb))
		if(iter_clothing.clothing_flags & THICKMATERIAL)
			limb_armor += 25

	if(limb_armor > limb_damage)
		return

	var/obj/item/organ/internal/zombie_infection/infection
	infection = target.get_organ_slot(ORGAN_SLOT_ZOMBIE)
	if(!infection)
		infection = new()
		infection.Insert(target)
		to_chat(user, span_alien("You see [target] twitch for a moment as [target.p_their()] head is covered in \a [infection] - [target.p_theyve()] been infected."))

/obj/item/mutant_hand/zombie/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is ripping [user.p_their()] brains out! It looks like [user.p_theyre()] trying to commit suicide!"))
	var/obj/item/bodypart/head = user.get_bodypart(BODY_ZONE_HEAD)
	if(head)
		head.dismember()
	return BRUTELOSS

/obj/item/mutant_hand/zombie/proc/check_feast(mob/living/target, mob/living/user)
	if(target.stat == DEAD)
		var/hp_gained = target.maxHealth
		target.investigate_log("has been devoured by a zombie.", INVESTIGATE_DEATHS)
		target.gib()
		// zero as argument for no instant health update
		user.adjustBruteLoss(-hp_gained, 0)
		user.adjustToxLoss(-hp_gained, 0)
		user.adjustFireLoss(-hp_gained, 0)
		user.adjustCloneLoss(-hp_gained, 0)
		user.updatehealth()
		user.adjustOrganLoss(ORGAN_SLOT_BRAIN, -hp_gained) // Zom Bee gibbers "BRAAAAISNSs!1!"
		user.set_nutrition(min(user.nutrition + hp_gained, NUTRITION_LEVEL_FULL))
//monkestation edit start
		if(iszombie(user))
			var/mob/living/carbon/carbon_user = user
			var/datum/species/zombie/infectious/zombie_datum = carbon_user.dna.species
			zombie_datum.consumed_flesh += hp_gained
//monkestation edit end


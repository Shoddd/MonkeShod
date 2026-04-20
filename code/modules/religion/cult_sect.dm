/datum/religion_sect/cult
	name = "Cult"
	quote = "We must devote ourselves."
	desc = "[GLOB.deity] requires absolute devotion from you and the acolytes you convert. \
	Rather than favor, offer your loyalty to perform rituals."
	tgui_icon = "cross"
	altar_icon_state = "cult_sect"
	alignment = ALIGNMENT_EVIL
	rites_list = list(/datum/religion_rites/conversion,
	/datum/religion_rites/cult,
	/datum/religion_rites/cult/convert_nullrod
	/datum/religion_rites/cult/summon_spirit,
	/datum/religion_rites/cult/summon_god,)
	///people who have agreed to serve, and can be deaconized
	var/list/possible_acolytes = list()
	///people who have been offered an invitation, they haven't finished the alert though.
	var/list/currently_asking = list()
	desired_items = list("Devoted Followers")

/**
 * Called by conversion rite, this async'd proc waits for a response on joining the sect.
 * If yes, the conversion rite can now recruit them instead of just offering invites
 */
/datum/religion_sect/cult/proc/invite_acolyte(mob/living/carbon/human/invited, mob/living/inviter)
	inviter.balloon_alert(inviter, "offer has been made")
	currently_asking += invited
	var/ask = tgui_alert(invited, "Serve [GLOB.deity]?", "Initiation", list("Yes", "No"), 60 SECONDS)
	currently_asking -= invited
	if(ask == "Yes")
		possible_acolytes += invited
		inviter.balloon_alert(inviter, "accepts serving [GLOB.deity]!")
	else
		inviter.balloon_alert(inviter, "refuses to serve [GLOB.deity]!")


/datum/religion_rites/conversion
	name = "Initiation"
	desc = "Converts someone to your sect. They must be willing, so the first invocation will instead prompt them to join. \
	Once they accept and are converted, they will become a acolyte, counting as a member for rituals."
	ritual_length = 30 SECONDS
	ritual_invocations = list(
		"yip",
		"yap",
		"yip",
		"yap",
	)
	invoke_msg = "idk bro"
	///the invited acolyte
	var/mob/living/carbon/human/new_acolytes

/datum/religion_rites/conversion/perform_rite(mob/living/user, atom/religious_tool)
	var/datum/religion_sect/cult/sect = GLOB.religious_sect
	if(!ismovable(religious_tool))
		to_chat(user, span_warning("This rite requires a religious device that individuals can be buckled to."))
		return FALSE
	var/atom/movable/movable_reltool = religious_tool
	if(!movable_reltool)
		return FALSE
	if(!LAZYLEN(movable_reltool.buckled_mobs))
		to_chat(user, span_warning("Nothing is buckled to the altar!"))
		return FALSE
	for(var/mob/living/carbon/human/possible_acolytes in movable_reltool.buckled_mobs)
		if(possible_acolytes.stat != CONSCIOUS)
			to_chat(user, span_warning("[possible_acolytes] needs to be alive and conscious to join the cult!"))
			return FALSE
		if(TRAIT_GENELESS in possible_acolytes.dna.species.inherent_traits)
			to_chat(user, span_warning("This species disgusts [GLOB.deity]! They would never be allowed to join the cult!"))
			return FALSE
		if(possible_acolytes in sect.currently_asking)
			to_chat(user, span_warning("Wait for them to decide on whether to join or not!"))
			return FALSE
		if(!(possible_acolytes in sect.possible_acolytes))
			INVOKE_ASYNC(sect, TYPE_PROC_REF(/datum/religion_sect/cult, invite_acolyte), possible_acolytes, user)
			to_chat(user, span_notice("They have been given the option to serving your God. Wait for them to decide and try again."))
			return FALSE
		new_acolytes = possible_acolytes
		return ..()

/datum/religion_rites/conversion/invoke_effect(mob/living/carbon/human/user, atom/movable/religious_tool)
	..()
	var/mob/living/carbon/human/joining_now = new_acolytes
	new_acolytes = null
	if(!(joining_now in religious_tool.buckled_mobs)) //checks one last time if the right corpse is still buckled
		to_chat(user, span_warning("The new member is no longer on the altar!"))
		return FALSE
	if(joining_now.stat != CONSCIOUS)
		to_chat(user, span_warning("The new member has to stay alive for the rite to work!"))
		return FALSE
	if(!joining_now.mind)
		to_chat(user, span_warning("The new member has no mind!"))
		return FALSE
	if(joining_now.mind.has_antag_datum(/datum/antagonist/cult))//one cult at a time buddy
		to_chat(user, span_warning("[GLOB.deity] has seen a true, dark evil in [joining_now]'s heart, and they have been smitten!"))
		playsound(get_turf(religious_tool), 'sound/effects/pray.ogg', 50, TRUE)
		joining_now.gib(TRUE)
		return FALSE
	to_chat(user, span_notice("[joining_now] has submitted to [GLOB.deity]! They are now a holy role! (albeit the lowest level of such)"))
	joining_now.mind.holy_role = HOLY_ROLE_DEACON
	GLOB.religious_sect.on_conversion(joining_now)
	playsound(get_turf(religious_tool), 'sound/effects/pray.ogg', 50, TRUE)
	return TRUE


/datum/religion_rites/cult/proc/can_invoke(mob/living/user, atom/religious_tool)
	//This proc determines if the ritual has enough acolytes nearby to invoke, counts anyone with a holy role, including the invoker/chaplain
	var/list/invokers = list() //people eligible to invoke the rune
	if(user)
		invokers += user
	if(required_acolytes > 1)
		for(var/mob/living/acolytes in range(2, religious_tool))
			if(!IS_HOLY(acolytes))
				continue
			if(acolytes == user)
				continue
			if(acolytes.stat != CONSCIOUS)
				continue
			invokers += acolytes

	return invokers


/datum/religion_rites/cult // cult rites parent used to make all cult rites require a certain number of people
	name = "Create Robes"
	desc = "Create a pair of robes for the initiated, these robes will hide their name and voice when worn, however it won't hide their ID."
	ritual_length = 5 SECONDS
	invoke_msg = "Don the robes!"
	favor_cost = 0 // we use people not favor, 0 by default but just incase
	var/required_acolytes = 1

/datum/religion_rites/cult/perform_rite(mob/living/user, atom/religious_tool)
	var/list/invokers = can_invoke(user)
	if(length(invokers) < required_acolytes)
		to_chat(user, span_warning("You need at least [required_acolytes] acolytes around to perform this ritual!"))
		return FALSE
	return ..()

/datum/religion_rites/cult/invoke_effect(mob/living/user, atom/movable/religious_tool)
	..()
	var/altar_turf = get_turf(religious_tool)
	new /obj/item/clothing/suit/hooded/chaplain_hoodie/cult(altar_turf)
	return TRUE

/datum/religion_rites/cult/summon_spirit // cult rites parent used to make all cult rites require a certain number of people
	name = "Summon Spirit"
	desc = "Summon a spirit from beyond the veil. This ritual requires 3 acolytes."
	ritual_length = 5 SECONDS // 5 seconds for testing, planned 30-60
	ritual_invocations = list(
		"yip",
		"yap",
		"yip",
		"yap",
	)
	invoke_msg = "Don the robes!"
	favor_cost = 0 // we use people not favor, 0 by default but just incase
	required_acolytes = 1 // 1 for testing, 3 planned


/datum/religion_rites/cult/summon_god // cult rites parent used to make all cult rites require a certain number of people
	name = "Summon Deity"
	desc = "Summon [GLOB.deity] using a provided animal vessel, if no vessel if provided [GLOB.deity] will take a random form. \
	This ritual can only be performed once. This ritual requires 7 acolytes."
	ritual_length = 5 SECONDS // 5 seconds for testing, planned 30-60
	ritual_invocations = list(
		"yip",
		"yap",
		"yip",
		"yap",
	)
	invoke_msg = "Omega luls!"
	favor_cost = 0 // we use people not favor, 0 by default but just incase
	required_acolytes = 1 // 1 for testing, 7 planned

/datum/religion_rites/cult/summon_god/invoke_effect(mob/living/user, atom/movable/religious_tool)
	..()
	var/datum/religion_sect/cult/sect = GLOB.religious_sect
	var/altar_turf = get_turf(religious_tool)
	new /obj/item/clothing/suit/hooded/chaplain_hoodie/cult(altar_turf)
	sect.rites_list -= /datum/religion_rites/cult/summon_god // Can only be done once
	return TRUE

/datum/religion_rites/cult/convert_nullrod
	name = "Convert Nullrod"
	desc = "Perform a ritual to convert your nullrod, This ritual requires 5 acolytes."
	ritual_length = 5 SECONDS // 5 seconds for testing, planned 30-60
	ritual_invocations = list(
		"yip",
		"yap",
		"yip",
		"yap",
	)
	invoke_msg = "Omega luls!"
	favor_cost = 0 // we use people not favor, 0 by default but just incase
	required_acolytes = 1 // 1 for testing, 5 planned

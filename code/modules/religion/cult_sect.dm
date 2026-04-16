/datum/religion_sect/cult
	name = "Cult"
	quote = "We must devote ourselves."
	desc = "Your deity requires absolute devotion from you and the acolytes you convert. \
	You earn favor from converting people to your religion, you may spend this favor to perhaps, invoke the one true god."
	tgui_icon = "cross"
	altar_icon_state = "cult_sect"
	alignment = ALIGNMENT_EVIL
	rites_list = list(/datum/religion_rites/deaconize, /datum/religion_rites/forgive, /datum/religion_rites/summon_rules)
	///people who have agreed to serve, and can be deaconized
	var/list/possible_acolytes = list()
	///people who have been offered an invitation, they haven't finished the alert though.
	var/list/currently_asking = list()
	///people who have accepted invitation and been converted
	var/list/acolytes = list()
	desired_items = list("Devoted Followers")

/datum/religion_rites/cult // cult rites parent used to make all cult rites require a certain number of people

/**
 * Called by conversion rite, this async'd proc waits for a response on joining the sect.
 * If yes, the conversion rite can now recruit them instead of just offering invites
 */
/datum/religion_sect/cult/proc/invite_acolyte(mob/living/carbon/human/invited, mob/living/inviter)
	inviter.balloon_alert(inviter, "offer has been made")
	currently_asking += invited
	var/ask = tgui_alert(invited, "serve [GLOB.deity]?", "Invitation", list("Yes", "No"), 60 SECONDS)
	currently_asking -= invited
	if(ask == "Yes")
		possible_acolytes += invited
		inviter.balloon_alert(inviter, "accepts serving [GLOB.deity]!")
	else
		inviter.balloon_alert(inviter, "refuses to serve [GLOB.deity]!")

/// how much favor is gained when someone joins the crusade and is deaconized
#define DEACONIZE_FAVOR_GAIN 300

///Makes the person holy, but they now also have to follow the honorbound code (CBT). Actually earns favor, convincing others to uphold the code (tm) is not easy
/datum/religion_rites/conversion
	name = "Join Crusade"
	desc = "Converts someone to your sect. They must be willing, so the first invocation will instead prompt them to join. \
	They will become honorbound like you, and you will gain a massive favor boost!"
	ritual_length = 30 SECONDS
	ritual_invocations = list(
		"A good, honorable crusade against evil is required.",
		"We need the righteous ...",
		"... the unflinching ...",
		"... and the just.",
		"Sinners must be silenced ...",
	)
	invoke_msg = "... And the code must be upheld!"
	///the invited crusader
	var/mob/living/carbon/human/new_crusader

/datum/religion_rites/conversion/perform_rite(mob/living/user, atom/religious_tool)
	var/datum/religion_sect/honorbound/sect = GLOB.religious_sect
	if(!ismovable(religious_tool))
		to_chat(user, span_warning("This rite requires a religious device that individuals can be buckled to."))
		return FALSE
	var/atom/movable/movable_reltool = religious_tool
	if(!movable_reltool)
		return FALSE
	if(!LAZYLEN(movable_reltool.buckled_mobs))
		to_chat(user, span_warning("Nothing is buckled to the altar!"))
		return FALSE
	for(var/mob/living/carbon/human/possible_crusader in movable_reltool.buckled_mobs)
		if(possible_crusader.stat != CONSCIOUS)
			to_chat(user, span_warning("[possible_crusader] needs to be alive and conscious to join the crusade!"))
			return FALSE
		if(TRAIT_GENELESS in possible_crusader.dna.species.inherent_traits)
			to_chat(user, span_warning("This species disgusts [GLOB.deity]! They would never be allowed to join the crusade!"))
			return FALSE
		if(possible_crusader in sect.currently_asking)
			to_chat(user, span_warning("Wait for them to decide on whether to join or not!"))
			return FALSE
		if(!(possible_crusader in sect.possible_crusaders))
			INVOKE_ASYNC(sect, TYPE_PROC_REF(/datum/religion_sect/honorbound, invite_crusader), possible_crusader, user)
			to_chat(user, span_notice("They have been given the option to consider joining the crusade against evil. Wait for them to decide and try again."))
			return FALSE
		new_crusader = possible_crusader
		return ..()

/datum/religion_rites/conversion/invoke_effect(mob/living/carbon/human/user, atom/movable/religious_tool)
	..()
	var/mob/living/carbon/human/joining_now = new_crusader
	new_crusader = null
	if(!(joining_now in religious_tool.buckled_mobs)) //checks one last time if the right corpse is still buckled
		to_chat(user, span_warning("The new member is no longer on the altar!"))
		return FALSE
	if(joining_now.stat != CONSCIOUS)
		to_chat(user, span_warning("The new member has to stay alive for the rite to work!"))
		return FALSE
	if(!joining_now.mind)
		to_chat(user, span_warning("The new member has no mind!"))
		return FALSE
	if(joining_now.mind.has_antag_datum(/datum/antagonist/cult))//what the fuck?!
		to_chat(user, span_warning("[GLOB.deity] has seen a true, dark evil in [joining_now]'s heart, and they have been smitten!"))
		playsound(get_turf(religious_tool), 'sound/effects/pray.ogg', 50, TRUE)
		joining_now.gib(TRUE)
		return FALSE
	GLOB.religious_sect.adjust_favor(DEACONIZE_FAVOR_GAIN, user)
	to_chat(user, span_notice("[GLOB.deity] has bound [joining_now] to the code! They are now a holy role! (albeit the lowest level of such)"))
	joining_now.mind.holy_role = HOLY_ROLE_DEACON
	GLOB.religious_sect.on_conversion(joining_now)
	playsound(get_turf(religious_tool), 'sound/effects/pray.ogg', 50, TRUE)
	return TRUE

#undef DEACONIZE_FAVOR_GAIN

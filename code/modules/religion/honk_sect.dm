/datum/religion_sect/honk
	name = "The Clowns"
	desc = "A sect dedicated to the Honkmother"
	convert_opener = "The Honkmother welcomes you to the party, prankster.<br>Sacrifice bananas to power our pranks and grant you favor."
	alignment = ALIGNMENT_NEUT
	max_favor = 10000
	desired_items = list(/obj/item/food/grown/banana)
	rites_list = list(/datum/religion_rites/holypie, /datum/religion_rites/honkabot, /datum/religion_rites/bananablessing, /datum/religion_rites/honk_mech)
	altar_icon_state = "convertaltar-red"

//honkmother bible is supposed to only cure clowns, honk, and be slippery. I don't know how I'll do that
/datum/religion_sect/honk/sect_bless(mob/living/blessed, mob/living/user)
	if(!ishuman(blessed))
		return
	var/mob/living/carbon/human/H = blessed
	var/datum/mind/M = H.mind
	if(M.assigned_role != "Clown")
		return

	var/heal_amt = 20 // should probably lessen
	if(H.getBruteLoss() > 0 || H.getFireLoss() > 0)
		H.heal_overall_damage(heal_amt, heal_amt, 0)
		H.update_damage_overlays()

	H.visible_message(span_notice("[user] heals [H] with the power of [GLOB.deity]!"))
	to_chat(H, span_boldnotice("The radiance of [GLOB.deity] heals you!"))
	playsound(user, "sound/miscitems/bikehorn.ogg", 25, TRUE, -1)
	H.add_mood_event("honk", /datum/mood_event/honk)
	return TRUE
/*
/datum/religion_sect/honk/on_conversion(mob/living/L)
	. = ..()
	var/obj/item/storage/book/bible/da_bible
	for(da_bible in L.get_contents())
		da_bible.AddComponent(/datum/component/slippery, 40)
		da_bible.desc += " It has an usually slippery texture."
*/
/datum/religion_sect/honk/on_sacrifice(/obj/item/food/grown/banana/offering, mob/living/user)
	if(!istype(offering))
		return
	adjust_favor(25, user)
	to_chat(user, span_notice("HONK"))
	qdel(offering)
	return

/datum/religion_rites/holypie
	name = "Holy Pie"
	desc = "Creates a cream pie to throw at others"
	ritual_length = 5 SECONDS
	invoke_msg = "Oh, Honkmother, grant us the pie to cream the faces of the people."
	favor_cost = 50

/datum/religion_rites/holypie/invoke_effect(mob/living/user, atom/movable/religious_tool)
	. = ..()
	var/altar_turf = get_turf(religious_tool)
	new /obj/item/food/pie/cream (altar_turf)
	playsound(altar_turf, 'sound/items/bikehorn.ogg', 50, TRUE)
	return TRUE

/datum/religion_rites/honkabot
	name = "Honk a Bot"
	desc = "Summons a Honkbot to bring honking to the station"
	ritual_length = 5 SECONDS
	invoke_msg = "Great Honkmother, hear my pray: HONK!"
	favor_cost = 150

/datum/religion_rites/honkabot/invoke_effect(mob/living/user, atom/movable/religious_tool)
	. = ..()
	var/altar_turf = get_turf(religious_tool)
	new /mob/living/simple_animal/bot/secbot/honkbot(altar_turf)
	return TRUE

/datum/religion_rites/bananablessing
	name = "Banana Blessing"
	desc = "Creates a piece of bananium to further the clown researches"
	ritual_length = 30 SECONDS
	ritual_invocations = list(
	"I pray to the Honkmother to hear my pleas...",
	"...Bring us the power to entertain our allies...",
	"...And merciless prank our enemies...",
	)
	invoke_msg = "Show the true power of clownkind!"
	favor_cost = 1000

/datum/religion_rites/bananablessing/invoke_effect(mob/living/user, atom/movable/religious_tool)
	. = ..()
	var/altar_turf = get_turf(religious_tool)
	new /obj/item/stack/sheet/mineral/bananium (altar_turf)
	playsound(altar_turf, 'sound/items/bikehorn.ogg', 50, TRUE)
	return TRUE

/datum/religion_rites/honk_mech
	name = "Summon Honkmech"
	desc = "H.O.N.K"
	ritual_length = 6.7 SECONDS
	invoke_msg = "OH THANK YOU GREAT HONK MOTHER FOR MAKING THIS POSSIBLE!!" // I don't see how you'd do this without 'honk mothers' help
	favor_cost = 10001 // Intentionally one more than the max, because I think thats really funny, you can already make a honk mech by this point if you just summon pure bananium.

/datum/religion_rites/honk_mech/invoke_effect(mob/living/user, atom/movable/religious_tool)
	. = ..()
	var/altar_turf = get_turf(religious_tool)
	new /obj/vehicle/sealed/mecha/honker/loaded (altar_turf)
	playsound(altar_turf, 'sound/items/party_horn.ogg', 50, TRUE)
	return TRUE

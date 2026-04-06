/datum/antagonist/forgotten_ipc
	name = "Forgotten IPC"
	roundend_category = "Forgotten IPC"
	antagpanel_category = "Forgotten IPC"
	job_rank = ROLE_FORGOTTEN_IPC
	hud_icon = 'monkestation/icons/mob/huds/antag_hud.dmi'
	objectives = list()
	show_to_ghosts = TRUE
	preview_outfit = null
	antag_count_points = 5

/datum/antagonist/forgotten_ipc/forge_objectives()
	var/datum/objective/law = new /datum/objective
	var/list/selected_objective = pick(GLOB.florida_man_base_objectives)

	law.owner = owner
	if(prob(25))
		law.explanation_text = "[selected_objective[1]] [pick(GLOB.florida_man_objective_nouns)] [selected_objective[2]], [pick(GLOB.florida_man_objective_suffix)]"
	else
		law.explanation_text = "[selected_objective[1]] [pick(GLOB.florida_man_objective_nouns)] [selected_objective[2]]."
	objectives += law

/datum/antagonist/forgotten_ipc/greet()
	var/mob/living/carbon/floridan = owner.current
	randomize_human(floridan)

	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/malf.ogg',100,0, use_reverb = FALSE)
	to_chat(owner, span_boldannounce("You are THE Florida Man!\nYou're not quite sure how you got out here in space, but you don't generally bother thinking about things.\n\nYou love methamphetamine!\nYou love wrestling lizards!\nYou love getting drunk!\nYou love sticking it to THE MAN!\nYou don't act with any coherent plan or objective.\nYou don't outright want to destroy the station or murder people, as you have no home to return to.\n\nGo forth, son of Space Florida, and sow chaos!"))
	owner.announce_objectives()
	random_unique_name(PLURAL, floridan)
	if(prob(1)) // 1% chance to be Tony Brony...because meme references to streams are good!
		floridan.fully_replace_character_name(newname = "Tony Brony")

/datum/antagonist/forgotten_ipc/antag_token(datum/mind/hosts_mind, mob/spender)
	if(isobserver(spender))
		var/mob/living/carbon/human/new_mob = spender.change_mob_type(/mob/living/carbon/human/species/ipc, delete_old_mob = TRUE)
		new_mob.mind.add_antag_datum(/datum/antagonist/forgotten_ipc)
	else
		hosts_mind.add_antag_datum(/datum/antagonist/forgotten_ipc)

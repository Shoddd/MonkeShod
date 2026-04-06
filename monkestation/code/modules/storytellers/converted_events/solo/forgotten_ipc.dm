/datum/round_event_control/forgotten_ipc // Meant to be extremely similar to flordia man in terms of appearance and 'threat', copied flordia man stats almost 1:1
	name = "Forgotten IPC"
	typepath = /datum/round_event/ghost_role/forgotten_ipc
	weight = 14
	max_occurrences = 2
	track = EVENT_TRACK_MODERATE
	tags = list(TAG_DESTRUCTIVE, TAG_MUNDANE, TAG_EXTERNAL, TAG_OUTSIDER_ANTAG)
	checks_antag_cap = TRUE
	dont_spawn_near_roundend = TRUE

/datum/round_event/ghost_role/forgotten_ipc
	minimum_required = 1
	role_name = "Forgotten IPC"
	fakeable = FALSE

/datum/round_event/ghost_role/forgotten_ipc/spawn_role()
	var/list/mob/dead/observer/candidates = SSpolling.poll_ghost_candidates(
		"Do you want to play as a forgotten IPC?",
		role = ROLE_FORGOTTEN_IPC,
		poll_time = 20 SECONDS,
		alert_pic = /datum/antagonist/forgotten_ipc,
		role_name_text = "Forgotten IPC"
	)
	var/turf/spawn_loc = get_unlocked_closed_locker() // Spawns in a locker

	if(!length(candidates))
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)
	var/mob/living/carbon/human/species/ipc/ipc = new(spawn_loc) //This is to catch errors by just giving them a location in general.

	ipc.hairstyle = "Bald"
	ipc.facial_hairstyle = "Shaved"
	var/datum/mind/Mind = new /datum/mind(selected.key)
	Mind.special_role = "Forgotten IPC"
	Mind.active = 1
	Mind.transfer_to(ipc)
	Mind.add_antag_datum(/datum/antagonist/forgotten_ipc)

	ipc.forceMove(get_unlocked_closed_locker())

	message_admins("[ADMIN_LOOKUPFLW(ipc)] has been made into Forgotten IPC.")
	log_game("[key_name(ipc)] was spawned as Forgotten IPC by an event.")
	spawned_mobs += ipc
	return SUCCESSFUL_SPAWN

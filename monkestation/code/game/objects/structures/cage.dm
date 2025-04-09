#define C_OPENED 0
#define C_CLOSED 1

/obj/structure/closet/cage
	name = "cage"
	desc = "A large and heavy plasteel box, used to store dangerous animals and humans. It has two doors - the outer \"cover\", and the inner \"bars\". The cover is a thin plasteel sheet with tiny holes in the corners to let air through. The bars consist of thick plasteel rods, evenly spaced apart."

	density = FALSE
	anchored = FALSE
	icon = 'monkestation/icons/obj/cage.dmi'
	icon_state = "cage_base"
	max_integrity = 225
	integrity_failure = 0
	can_weld_shut = 0
	can_install_electronics = FALSE
	max_mob_size = MOB_SIZE_LARGE
	mob_storage_capacity = 1
	storage_capacity = 0 // for people not things.. or wait
	divable = FALSE // Funny but skittish is supposed to be a positive quirk
	door_anim_time = 1 SECOND
	door_anim_squish = 0
	open_sound = null
	close_sound = null

	var/cover_state = C_OPENED
	var/door_state = C_OPENED

	// How long it takes to open or close the bars of the cage
	var/bar_time = 6 SECONDS
	// How long to takes to put the shutter down and up
	var/shutter_time = 15 SECONDS

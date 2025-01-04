/obj/item/clothing/mask/onimask
	name = "oni mask"
	desc = "placerholder stuff"
	icon = 'monkestation/code/modules/donator/icons/obj/clothing.dmi'
	worn_icon = 'monkestation/code/modules/donator/icons/mob/clothing.dmi'
	icon_state = "dark_skeletal_visage"
	w_class = WEIGHT_CLASS_BULKY
	flags_cover = MASKCOVERSEYES | MASKCOVERSMOUTH | HIDESNOUT
	layer = MOB_LAYER
	resistance_flags = FIRE_PROOF | ACID_PROOF

/mob/living/basic/possession_holder/mask
	name = "Cursed Mask"
	desc = "My brain is fried fill out later"
	hud_type = /datum/hud/possessed
	dexterous = FALSE
	maxHealth = 100
	health = 100
	held_items = list(null, null)
	pass_flags = PASSTABLE | PASSMOB
	status_flags = (CANPUSH | CANSTUN | CANKNOCKDOWN)
	set_dir_on_move = FALSE
	gender = NEUTER
	advanced_simple = TRUE
	can_be_held = TRUE
	uses_directional_offsets = FALSE
	melee_damage_lower = 0
	melee_damage_upper = 0
	health_regeneration = 0
	stored_item = /obj/item/clothing/mask/onimask

/mob/living/basic/possession_holder/mask/New(loc, obj/item/_stored_item)
	. = ..()
	if(!_stored_item)
		_stored_item = new /obj/item/clothing/mask/onimask(src)

	stored_item = _stored_item

	_stored_item.forceMove(src)

	AddComponent(/datum/component/carbon_sprint)
	AddComponent(/datum/component/personal_crafting)
	AddComponent(/datum/component/basic_inhands, y_offset = -6)
	AddElement(/datum/element/dextrous)
	add_traits(list(TRAIT_ADVANCEDTOOLUSER, TRAIT_CAN_STRIP, TRAIT_LITERATE), ROUNDSTART_TRAIT)

	appearance = stored_item.appearance
	desc = stored_item.desc
	name = stored_item.name
	real_name = stored_item.name
	update_name_tag()

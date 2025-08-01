/obj/machinery/vending/clothing
	name = "ClothesMate"
	desc = "A vending machine for clothing."
	icon_state = "clothes"
	icon_deny = "clothes-deny"
	panel_type = "panel15"
	product_slogans = "Dress for success!;Prepare to look swagalicious!;Look at all this swag!;Why leave style up to fate? Use the ClothesMate!"
	vend_reply = "Thank you for using the ClothesMate!"
	product_categories = list(
		list(
			"name" = "Head",
			"icon" = "hat-cowboy",
			"products" = list(
				/obj/item/clothing/head/wig/natural = 4,
				/obj/item/clothing/head/costume/fancy = 4,
				/obj/item/clothing/head/beanie = 8,
				/obj/item/clothing/head/beret = 10,
				/obj/item/clothing/mask/bandana = 3,
				/obj/item/clothing/mask/bandana/striped = 3,
				/obj/item/clothing/mask/bandana/skull = 3,
				/obj/item/clothing/neck/scarf = 6,
				/obj/item/clothing/neck/large_scarf = 6,
				/obj/item/clothing/neck/infinity_scarf = 6,
				/obj/item/clothing/neck/ascot = 6,
				/obj/item/clothing/neck/tie = 6,
				/obj/item/clothing/head/rasta = 3,
				/obj/item/clothing/head/chaplain/kippah = 3,
				/obj/item/clothing/head/chaplain/taqiyah/red = 3,
				/obj/item/clothing/head/hats/tophat = 3,
				/obj/item/clothing/head/fedora = 3,
				/obj/item/clothing/head/hats/bowler = 3,
				/obj/item/clothing/head/cowboy/white = 1,
				/obj/item/clothing/head/cowboy/grey = 1,
				/obj/item/clothing/head/costume/sombrero/green = 1,
				/obj/item/clothing/head/hats/fez = 3, //MONKESTATION ADDITION
			),
		),

		list(
			"name" = "Accessories",
			"icon" = "glasses",
			"products" = list(
				/obj/item/clothing/accessory/pride = 15,
				/obj/item/clothing/accessory/waistcoat = 4,
				/obj/item/clothing/suit/toggle/suspenders = 4,
				/obj/item/clothing/neck/tie/horrible = 3,
				/obj/item/clothing/glasses/regular = 2,
				/obj/item/clothing/glasses/regular/jamjar = 1,
				/obj/item/clothing/glasses/orange = 1,
				/obj/item/clothing/glasses/red = 1,
				/obj/item/clothing/glasses/monocle = 1,
				/obj/item/clothing/gloves/fingerless = 2,
				/obj/item/storage/belt/fannypack = 3,
				/obj/item/storage/belt/fannypack/blue = 3,
				/obj/item/storage/belt/fannypack/red = 3,
				/obj/item/umbrella = 3,
				/obj/item/umbrella/parasol = 2,
			),
		),

		list(
			"name" = "Under",
			"icon" = "shirt",
			"products" = list(
				/obj/item/clothing/under/pants/slacks = 5,
				/obj/item/clothing/under/shorts = 5,
				/obj/item/clothing/under/pants/jeans = 5,
				/obj/item/clothing/under/shorts/jeanshorts = 5,
				/obj/item/clothing/under/costume/buttondown/slacks = 4,
				/obj/item/clothing/under/costume/buttondown/shorts = 4,
				/obj/item/clothing/under/dress/sundress = 2,
				/obj/item/clothing/under/dress/tango = 2,
				/obj/item/clothing/under/dress/ballgown = 2, //MONKESTATION EDIT ADDITION
				/obj/item/clothing/under/dress/wlpinafore = 2, //MONKESTATION EDIT ADDITION
				/obj/item/clothing/under/dress/ribbondress = 2, //MONKESTATION EDIT ADDITION
				/obj/item/clothing/under/dress/skirt/plaid = 4,
				/obj/item/clothing/under/costume/donatorgrayscaleturtleneck/nondonator = 4, //MONKESTATION ADDITION
				/obj/item/clothing/under/dress/skirt/turtleskirt = 4,
				/obj/item/clothing/under/misc/overalls = 2,
				/obj/item/clothing/under/pants/camo = 2,
				/obj/item/clothing/under/pants/track = 2,
				/obj/item/clothing/under/costume/kilt = 1,
				/obj/item/clothing/under/dress/striped = 1,
				/obj/item/clothing/under/dress/sailor = 1,
				/obj/item/clothing/under/dress/redeveninggown = 1,
				/obj/item/clothing/suit/apron/purple_bartender = 2,
				/obj/item/clothing/under/costume/citizen_uniform = 4,
			),
		),

		list(
			"name" = "Suits & Skirts",
			"icon" = "vest",
			"products" = list(
				/obj/item/clothing/suit/toggle/jacket/sweater = 4,
				/obj/item/clothing/suit/jacket/oversized = 4,
				/obj/item/clothing/suit/jacket/fancy = 4,
				/obj/item/clothing/suit/hooded/wintercoat/custom = 2,
				/obj/item/clothing/under/suit/navy = 1,
				/obj/item/clothing/under/suit/black_really = 1,
				/obj/item/clothing/under/suit/burgundy = 1,
				/obj/item/clothing/under/suit/charcoal = 1,
				/obj/item/clothing/under/suit/white = 1,
				/obj/item/clothing/under/suit/sl = 1,
				/obj/item/clothing/suit/jacket/bomber = 2,
				/obj/item/clothing/suit/jacket/puffer/vest = 2,
				/obj/item/clothing/suit/jacket/puffer = 2,
				/obj/item/clothing/suit/jacket/letterman = 2,
				/obj/item/clothing/suit/jacket/letterman_red = 2,
				/obj/item/clothing/suit/costume/poncho = 1,
				/obj/item/clothing/under/dress/skirt = 2,
				/obj/item/clothing/under/suit/white/skirt = 2,
				/obj/item/clothing/under/rank/captain/suit/skirt = 2,
				/obj/item/clothing/under/rank/civilian/head_of_personnel/suit/skirt = 2,
				/obj/item/clothing/under/rank/civilian/bartender/purple = 2,
				/obj/item/clothing/suit/jacket/miljacket = 1,
			),
		),

		list(
			"name" = "Shoes",
			"icon" = "socks",
			"products" = list(
				/obj/item/clothing/shoes/sneakers/black = 4,
				/obj/item/clothing/shoes/sandal = 2,
				/obj/item/clothing/shoes/laceup = 2,
				/obj/item/clothing/shoes/winterboots = 2,
				/obj/item/clothing/shoes/glow = 2,
				/obj/item/clothing/shoes/cowboy = 2,
				/obj/item/clothing/shoes/cowboy/white = 2,
				/obj/item/clothing/shoes/cowboy/black = 2,
			),
		),

		list(
			"name" = "Special",
			"icon" = "star",
			"products" = list(
				/obj/item/clothing/head/costume/football_helmet = 6,
				/obj/item/clothing/under/costume/football_suit = 6,
				/obj/item/clothing/suit/costume/football_armor = 6,

				/obj/item/clothing/suit/mothcoat = 3,
				/obj/item/clothing/suit/mothcoat/winter = 3,
				/obj/item/clothing/head/mothcap = 3,

				/obj/item/clothing/suit/hooded/ethereal_raincoat = 3,
				/obj/item/clothing/under/ethereal_tunic = 3,
				/obj/item/clothing/head/costume/hairpin = 2,
				/obj/item/clothing/under/costume/yukata = 2,
				/obj/item/clothing/under/costume/yukata/green = 2,
				/obj/item/clothing/under/costume/yukata/white = 2,
				/obj/item/clothing/under/costume/kimono = 2,
				/obj/item/clothing/under/costume/kimono/red = 2,
				/obj/item/clothing/under/costume/kimono/purple = 2,
				/obj/item/clothing/shoes/sandal/alt = 4,
				/obj/item/clothing/mask/kitsune = 3,
				/obj/item/clothing/suit/costume/ianshirt = 1,
				/obj/item/clothing/suit/hooded/dinojammies = 3,
				/obj/item/clothing/suit/costume/irs = 20,
				/obj/item/clothing/head/costume/irs = 20,
				/obj/item/clothing/head/costume/tmc = 20,
				/obj/item/clothing/head/costume/deckers = 20,
				/obj/item/clothing/head/costume/yuri = 20,
				/obj/item/clothing/head/costume/allies = 20,
				/obj/item/clothing/glasses/osi = 20,
				/obj/item/clothing/glasses/phantom = 20,
				/obj/item/clothing/mask/gas/driscoll = 20,
				/obj/item/clothing/under/costume/yuri = 20,
				/obj/item/clothing/under/costume/dutch = 20,
				/obj/item/clothing/under/costume/osi = 20,
				/obj/item/clothing/under/costume/tmc = 20,
				/obj/item/clothing/suit/costume/deckers = 20,
				/obj/item/clothing/suit/costume/soviet = 20,
				/obj/item/clothing/suit/costume/yuri = 20,
				/obj/item/clothing/suit/costume/tmc = 20,
				/obj/item/clothing/suit/costume/pg = 20,
				/obj/item/clothing/shoes/jackbros = 20,
				/obj/item/clothing/shoes/saints = 20,
			),
		),
	)

	contraband = list(
		/obj/item/clothing/under/syndicate/tacticool = 1,
		/obj/item/clothing/under/syndicate/tacticool/skirt = 1,
		/obj/item/clothing/mask/balaclava = 1,
		/obj/item/clothing/head/costume/ushanka = 1,
		/obj/item/clothing/under/costume/soviet = 1,
		/obj/item/storage/belt/fannypack/black = 2,
		/obj/item/clothing/suit/jacket/letterman_syndie = 1,
		/obj/item/clothing/under/costume/jabroni = 1,
		/obj/item/clothing/under/costume/geisha = 1,
		/obj/item/clothing/under/rank/centcom/officer/replica = 1,
		/obj/item/clothing/under/rank/centcom/officer_skirt/replica = 1,
	)
	premium = list(/obj/item/clothing/under/suit/checkered = 1,
		/obj/item/clothing/head/costume/mailman = 1,
		/obj/item/clothing/under/misc/mailman = 1,
		/obj/item/clothing/suit/jacket/leather = 1,
		/obj/item/clothing/suit/jacket/leather/biker = 1,
		/obj/item/clothing/neck/necklace/dope = 3,
		/obj/item/clothing/suit/jacket/letterman_nanotrasen = 1,
		/obj/item/clothing/under/costume/swagoutfit = 1,
		/obj/item/clothing/shoes/swagshoes = 1,
		/obj/item/instrument/piano_synth/headphones/spacepods = 1,
	)
	refill_canister = /obj/item/vending_refill/clothing
	default_price = PAYCHECK_CREW * 0.7 //Default of
	extra_price = PAYCHECK_COMMAND
	payment_department = NO_FREEBIES
	light_mask = "wardrobe-light-mask"
	light_color = LIGHT_COLOR_ELECTRIC_GREEN

/obj/item/vending_refill/clothing
	machine_name = "ClothesMate"
	icon_state = "refill_clothes"

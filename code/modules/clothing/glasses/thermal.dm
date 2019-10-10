
// thermal goggles

/obj/item/clothing/glasses/thermal
	name = "Optical Thermal Scanner"
	desc = "Thermals in the shape of glasses."
	icon_state = "thermal"
	item_state = "glasses"
	origin_tech = "magnets=3"
	toggleable = 1
	vision_flags = SEE_MOBS
	invisa_view = 2
	eye_protection = -1
	deactive_state = "goggles_off"
	fullscreen_vision = /obj/screen/fullscreen/thermal

/obj/item/clothing/glasses/thermal/emp_act(severity)
	if(istype(src.loc, /mob/living/carbon/human))
		var/mob/living/carbon/human/M = src.loc
		to_chat(M, SPAN_WARNING("The Optical Thermal Scanner overloads and blinds you!"))
		if(M.glasses == src)
			M.eye_blind = 3
			M.eye_blurry = 5
			M.disabilities |= NEARSIGHTED
			spawn(100)
				M.disabilities &= ~NEARSIGHTED
	..()


/obj/item/clothing/glasses/thermal/syndi	//These are now a traitor item, concealed as mesons.	-Pete
	name = "Optical Meson Scanner"
	desc = "Used for seeing walls, floors, and stuff through anything."
	icon_state = "meson"
	actions_types = list(/datum/action/item_action/toggle)
	origin_tech = "magnets=3;syndicate=4"

/obj/item/clothing/glasses/thermal/monocle
	name = "Thermoncle"
	desc = "A monocle thermal."
	icon_state = "thermoncle"
	flags_atom = null //doesn't protect eyes because it's a monocle, duh
	toggleable = 0
	flags_armor_protection = 0

/obj/item/clothing/glasses/thermal/eyepatch
	name = "Optical Thermal Eyepatch"
	desc = "An eyepatch with built-in thermal optics"
	icon_state = "eyepatch"
	item_state = "eyepatch"
	toggleable = 0
	flags_armor_protection = 0

/obj/item/clothing/glasses/thermal/jensen
	name = "Optical Thermal Implants"
	desc = "A set of implantable lenses designed to augment your vision"
	icon_state = "thermalimplants"
	item_state = "syringe_kit"
	toggleable = 0


/obj/item/clothing/glasses/thermal/yautja
	name = "bio-mask thermal"
	desc = "A vision overlay generated by the Bio-Mask. Used to sense the heat of prey."
	icon = 'icons/obj/items/weapons/predator.dmi'
	icon_state = "visor_thermal"
	item_state = "securityhud"
	vision_flags = SEE_MOBS
	invisa_view = 2
	flags_inventory = COVEREYES
	flags_item = NODROP|DELONDROP
	toggleable = 0

	Dispose()
		..()
		return GC_HINT_RECYCLE

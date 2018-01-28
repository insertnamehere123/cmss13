/mob/living/carbon/human/gib()

	for(var/datum/limb/E in limbs)
		if(istype(E, /datum/limb/chest))
			continue
		// Only make the limb drop if it's not too damaged
		if(prob(100 - E.get_damage()))
			// Override the current limb status
			E.droplimb(1)

	if(species)
		hgibs(loc, viruses, dna, species.flesh_color, species.blood_color)
	else
		hgibs(loc, viruses, dna)

	..(species ? species.gibbed_anim : "gibbed-h")


/mob/living/carbon/human/dust()
	if(species)
		..(species.dusted_anim, species.remains_type)
	else
		..()

/mob/living/carbon/human/death(gibbed)

	if(stat == DEAD) return

	//Handle species-specific deaths.
	if(species) species.handle_death(src, gibbed)

	//callHook("death", list(src, gibbed))

	if(!gibbed && species.death_sound)
		playsound(loc, species.death_sound, 50, 1)

	if(ticker && ticker.current_state == 3) //game has started, to ignore the map placed corpses.
		round_statistics.total_human_deaths++

	return ..(gibbed,species.death_message)

/mob/living/carbon/human/proc/makeSkeleton()
	if(SKELETON in src.mutations)	return

	if(f_style)
		f_style = "Shaved"
	if(h_style)
		h_style = "Bald"
	update_hair(0)

	mutations.Add(SKELETON)
	status_flags |= DISFIGURED
	update_body(0)
	update_mutantrace()
	return

/mob/living/carbon/human/proc/ChangeToHusk()
	if(HUSK in mutations)	return

	if(f_style)
		f_style = "Shaved"		//we only change the icon_state of the hair datum, so it doesn't mess up their UI/UE
	if(h_style)
		h_style = "Bald"
	update_hair(0)

	mutations.Add(HUSK)
	status_flags |= DISFIGURED	//makes them unknown without fucking up other stuff like admintools
	update_body(0)
	update_mutantrace()
	return

/mob/living/carbon/human/proc/Drain()
	ChangeToHusk()
	mutations |= HUSK
	return

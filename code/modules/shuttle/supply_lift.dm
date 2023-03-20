/obj/docking_port/stationary/supply
	id = "supply_home"
	width = 5
	dwidth = 2
	dheight = 2
	height = 5
/obj/docking_port/mobile/supply
	name = "supply shuttle"
	id = SHUTTLE_SUPPLY
	callTime = 15 SECONDS

	dir = WEST
	port_direction = EAST
	width = 5
	dwidth = 2
	dheight = 2
	height = 5
	movement_force = list("KNOCKDOWN" = 0, "THROW" = 0)
	use_ripples = FALSE
	var/list/gears = list()
	var/list/obj/structure/machinery/door/poddoor/railing/railings = list()

/obj/docking_port/stationary/supply/alamyer
	name ="ASRS platform"
	id = "supply platform"
	roundstart_template = /datum/map_template/shuttle/supply

/obj/docking_port/mobile/supply/lift
	name ="ASRS lift"
	id = "supply lift"
	var/faction = FACTION_MARINE ///The faction of this docking port (aka, on which ship it is located)
	var/home_id = "supply_home" /// Id of the home docking port

/obj/docking_port/mobile/supply/Destroy(force)
	for(var/i in railings)
		var/obj/structure/machinery/door/poddoor/railing/railing = i
		railing.linked_pad = null
	railings.Cut()
	return ..()

/obj/docking_port/mobile/supply/afterShuttleMove()
	. = ..()
	if(getDockedId() == home_id)
		for(var/j in railings)
			var/obj/structure/machinery/door/poddoor/railing/R = j
			R.open()

/obj/docking_port/mobile/supply/on_ignition()
	if(getDockedId() == home_id)
		for(var/j in railings)
			var/obj/structure/machinery/door/poddoor/railing/R = j
			R.close()
		for(var/i in gears)
			var/obj/structure/machinery/gear/G = i
			G.start_moving(NORTH)
	else
		for(var/i in gears)
			var/obj/structure/machinery/gear/G = i
			G.start_moving(SOUTH)

/obj/docking_port/mobile/supply/register()
	. = ..()
	for(var/obj/structure/machinery/gear/G in GLOB.machines)
		if(G.id == "supply_elevator_gear")
			gears += G
			RegisterSignal(G, COMSIG_PARENT_QDELETING, .proc/clean_gear)
	for(var/obj/structure/machinery/door/poddoor/railing/R in GLOB.machines)
		if(R.id == "supply_elevator_railing")
			railings += R
			RegisterSignal(R, COMSIG_PARENT_QDELETING, .proc/clean_railing)
			R.linked_pad = src
			R.open()

///Signal handler when a gear is destroyed
/obj/docking_port/mobile/supply/proc/clean_gear(datum/source)
	SIGNAL_HANDLER
	gears -= source

///Signal handler when a railing is destroyed
/obj/docking_port/mobile/supply/proc/clean_railing(datum/source)
	SIGNAL_HANDLER
	railings -= source

/obj/docking_port/mobile/supply/canMove()
	if(is_station_level(z))
		return check_blacklist(shuttle_areas)
	return ..()

/obj/docking_port/mobile/supply/proc/check_blacklist(areaInstances)
	if(!areaInstances)
		areaInstances = shuttle_areas
	for(var/place in areaInstances)
		var/area/shuttle/shuttle_area = place
		for(var/trf in shuttle_area)
			var/turf/T = trf
			for(var/a in T.GetAllContents())
				if(isxeno(a))
					var/mob/living/L = a
					if(L.stat == DEAD)
						continue
				if(ishuman(a))
					var/mob/living/carbon/human/human_to_sell = a
					if(human_to_sell.stat == DEAD && can_sell_human_body(human_to_sell, faction))
						continue
				if(is_type_in_typecache(a, GLOB.blacklisted_cargo_types))
					return FALSE
	return TRUE

/obj/docking_port/mobile/supply/request(obj/docking_port/stationary/S)
	if(mode != SHUTTLE_IDLE)
		return 2
	return ..()

/obj/docking_port/mobile/supply/proc/buy(mob/user)
	if(!length(SSpoints.shoppinglist[faction]))
		return
	log_game("Supply pack orders have been purchased by [key_name(user)]")

	var/list/empty_turfs = list()
	for(var/place in shuttle_areas)
		var/area/shuttle/shuttle_area = place
		for(var/turf/open/floor/T in shuttle_area)
			if(is_blocked_turf(T))
				continue
			empty_turfs += T

	for(var/i in SSpoints.shoppinglist[faction])
		if(!empty_turfs.len)
			break
		var/datum/supply_order/SO = LAZYACCESSASSOC(SSpoints.shoppinglist, faction, i)

		var/datum/supply_packs/firstpack = SO.pack[1]

		var/obj/structure/crate_type = firstpack.containertype || firstpack.contains[1]

		var/obj/structure/A = new crate_type(pick_n_take(empty_turfs))
		if(firstpack.containertype)
			A.name = "Order #[SO.id] for [SO.orderer]"


		var/list/contains = list()
		//spawn the stuff, finish generating the manifest while you're at it
		for(var/P in SO.pack)
			var/datum/supply_packs/SP = P
			// yes i know
			if(SP.access)
				A.req_access = list()
				A.req_access += text2num(SP.access)

			if(SP.randomised_num_contained)
				if(length(SP.contains))
					for(var/j in 1 to SP.randomised_num_contained)
						contains += pick(SP.contains)
			else
				contains += SP.contains

		for(var/typepath in contains)
			if(!typepath)
				continue
			if(!firstpack.containertype)
				break
			new typepath(A)

		SSpoints.shoppinglist[faction] -= "[SO.id]"
		SSpoints.shopping_history += SO


/datum/supply_ui
	var/atom/source_object
	var/tgui_name = "Cargo"
	///Id of the shuttle controlled
	var/shuttle_id = ""
	///Reference to the supply shuttle
	var/obj/docking_port/mobile/supply/supply_shuttle
	///Faction of the supply console linked
	var/faction = FACTION_MARINE
	///Id of the home port
	var/home_id = ""

/datum/supply_ui/New(atom/source_object)
	. = ..()
	src.source_object = source_object
	RegisterSignal(source_object, COMSIG_PARENT_QDELETING, .proc/clean_ui)

///Signal handler to delete the ui when the source object is deleting
/datum/supply_ui/proc/clean_ui()
	SIGNAL_HANDLER
	qdel(src)

/datum/supply_ui/Destroy(force, ...)
	source_object = null
	return ..()

/datum/supply_ui/ui_host()
	return source_object

/datum/supply_ui/can_interact(mob/user)
	. = ..()
	if(inoperable(MAINT))
		return UI_CLOSE
	return TRUE

/datum/supply_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		if(shuttle_id)
			supply_shuttle = SSshuttle.getShuttle(shuttle_id)
			supply_shuttle.home_id = home_id
			supply_shuttle.faction = faction
		ui = new(user, src, tgui_name, source_object.name)
		ui.open()

/datum/supply_ui/ui_static_data(mob/user)
	. = list()
	.["categories"] = GLOB.all_supply_groups
	.["supplypacks"] = SSpoints.supply_packs_ui
	.["supplypackscontents"] = SSpoints.supply_packs_contents
	.["elevator_size"] = supply_shuttle?.return_number_of_turfs()

/datum/supply_ui/ui_data(mob/living/user)
	. = list()
	.["currentpoints"] = round(SSpoints.supply_points[user.faction])
	.["requests"] = list()
	for(var/key in SSpoints.requestlist)
		var/datum/supply_order/SO = SSpoints.requestlist[key]
		if(SO.faction != user.faction)
			continue
		var/list/packs = list()
		var/cost = 0
		for(var/P in SO.pack)
			var/datum/supply_packs/SP = P
			packs += SP.type
			cost += SP.cost
		.["requests"] += list(list("id" = SO.id, "orderer" = SO.orderer, "orderer_rank" = SO.orderer_rank, "reason" = SO.reason, "cost" = cost, "packs" = packs, "authed_by" = SO.authorised_by))
	.["deniedrequests"] = list()
	for(var/i in length(SSpoints.deniedrequests) to 1 step -1)
		var/datum/supply_order/SO = SSpoints.deniedrequests[SSpoints.deniedrequests[i]]
		if(SO.faction != user.faction)
			continue
		var/list/packs = list()
		var/cost = 0
		for(var/P in SO.pack)
			var/datum/supply_packs/SP = P
			packs += SP.type
			cost += SP.cost
		.["deniedrequests"] += list(list("id" = SO.id, "orderer" = SO.orderer, "orderer_rank" = SO.orderer_rank, "reason" = SO.reason, "cost" = cost, "packs" = packs, "authed_by" = SO.authorised_by))
	.["approvedrequests"] = list()
	for(var/i in length(SSpoints.approvedrequests) to 1 step -1)
		var/datum/supply_order/SO = SSpoints.approvedrequests[SSpoints.approvedrequests[i]]
		if(SO.faction != user.faction)
			continue
		var/list/packs = list()
		var/cost = 0
		for(var/datum/supply_packs/SP AS in SO.pack)
			packs += SP.type
			cost += SP.cost
		.["approvedrequests"] += list(list("id" = SO.id, "orderer" = SO.orderer, "orderer_rank" = SO.orderer_rank, "reason" = SO.reason, "cost" = cost, "packs" = packs, "authed_by" = SO.authorised_by))
	.["awaiting_delivery"] = list()
	.["awaiting_delivery_orders"] = 0
	for(var/key in SSpoints.shoppinglist[faction])
		var/datum/supply_order/SO = LAZYACCESSASSOC(SSpoints.shoppinglist, faction, key)
		.["awaiting_delivery_orders"]++
		var/list/packs = list()
		for(var/datum/supply_packs/SP AS in SO.pack)
			packs += SP.type
		.["awaiting_delivery"] += list(list("id" = SO.id, "orderer" = SO.orderer, "orderer_rank" = SO.orderer_rank, "reason" = SO.reason, "packs" = packs, "authed_by" = SO.authorised_by))
	.["export_history"] = list()
	var/id = 0
	for(var/datum/export_report/report AS in SSpoints.export_history)
		if(report.faction != user.faction)
			continue
		.["export_history"] += list(list("id" = id, "name" = report.export_name, "points" = report.points))
		id++
	.["shopping_history"] = list()
	for(var/datum/supply_order/SO AS in SSpoints.shopping_history)
		if(SO.faction != user.faction)
			continue
		var/list/packs = list()
		var/cost = 0
		for(var/P in SO.pack)
			var/datum/supply_packs/SP = P
			packs += SP.type
			cost += SP.cost
		.["shopping_history"] += list(list("id" = SO.id, "orderer" = SO.orderer, "orderer_rank" = SO.orderer_rank, "reason" = SO.reason, "cost" = cost, "packs" = packs, "authed_by" = SO.authorised_by))
	.["shopping_list_cost"] = 0
	.["shopping_list_items"] = 0
	.["shopping_list"] = list()
	for(var/i in SSpoints.shopping_cart)
		var/datum/supply_packs/SP = SSpoints.supply_packs[i]
		.["shopping_list_items"] += SSpoints.shopping_cart[i]
		.["shopping_list_cost"] += SP.cost * SSpoints.shopping_cart[SP.type]
		.["shopping_list"][SP.type] = list("count" = SSpoints.shopping_cart[SP.type])
	if(supply_shuttle)
		if(supply_shuttle?.mode == SHUTTLE_CALL)
			if(is_mainship_level(supply_shuttle.destination.z))
				.["elevator"] = "Raising"
				.["elevator_dir"] = "up"
			else
				.["elevator"] = "Lowering"
				.["elevator_dir"] = "down"
		else if(supply_shuttle?.mode == SHUTTLE_IDLE)
			if(is_mainship_level(supply_shuttle.z))
				.["elevator"] = "Raised"
				.["elevator_dir"] = "down"
			else
				.["elevator"] = "Lowered"
				.["elevator_dir"] = "up"
		else
			if(is_mainship_level(supply_shuttle.z))
				.["elevator"] = "Lowering"
				.["elevator_dir"] = "down"
			else
				.["elevator"] = "Raising"
				.["elevator_dir"] = "up"
	else
		.["elevator"] = "MISSING!"

/datum/supply_ui/proc/get_shopping_cart(mob/user)
	return SSpoints.shopping_cart

/datum/supply_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("cart")
			var/datum/supply_packs/P = SSpoints.supply_packs[text2path(params["id"])]
			if(!P)
				return
			var/shopping_cart = get_shopping_cart(ui.user)
			switch(params["mode"])
				if("removeall")
					shopping_cart -= P.type
				if("removeone")
					if(shopping_cart[P.type] > 1)
						shopping_cart[P.type]--
					else
						shopping_cart -= P.type
				if("addone")
					if(shopping_cart[P.type])
						shopping_cart[P.type]++
					else
						shopping_cart[P.type] = 1
				if("addall")
					var/mob/living/ui_user = ui.user
					var/cart_cost = 0
					for(var/i in shopping_cart)
						var/datum/supply_packs/SP = SSpoints.supply_packs[i]
						cart_cost += SP.cost * shopping_cart[SP.type]
					var/excess_points = SSpoints.supply_points[ui_user.faction] - cart_cost
					var/number_to_buy = min(round(excess_points / P.cost), 20) //hard cap at 20
					if(shopping_cart[P.type])
						shopping_cart[P.type] += number_to_buy
					else
						shopping_cart[P.type] = number_to_buy
			. = TRUE
		if("send")
			if(supply_shuttle.mode == SHUTTLE_IDLE && is_mainship_level(supply_shuttle.z))
				if (!supply_shuttle.check_blacklist())
					to_chat(usr, "For safety reasons, the Automated Storage and Retrieval System cannot store live, friendlies, classified nuclear weaponry or homing beacons.")
					playsound(supply_shuttle.return_center_turf(), 'sound/machines/buzz-two.ogg', 50, 0)
				else
					playsound(supply_shuttle.return_center_turf(), 'sound/machines/elevator_move.ogg', 50, 0)
					SSshuttle.moveShuttleToTransit(shuttle_id, TRUE)
					addtimer(CALLBACK(supply_shuttle, /obj/docking_port/mobile/supply/proc/sell), 15 SECONDS)
			else
				var/obj/docking_port/D = SSshuttle.getDock(home_id)
				supply_shuttle.buy(usr)
				playsound(D.return_center_turf(), 'sound/machines/elevator_move.ogg', 50, 0)
				SSshuttle.moveShuttle(shuttle_id, home_id, TRUE)
			. = TRUE
		if("approve")
			var/datum/supply_order/O = SSpoints.requestlist["[params["id"]]"]
			if(!O)
				O = SSpoints.deniedrequests["[params["id"]]"]
			if(!O)
				return
			SSpoints.approve_request(O, ui.user)
			. = TRUE
		if("deny")
			var/datum/supply_order/O = SSpoints.requestlist["[params["id"]]"]
			if(!O)
				return
			SSpoints.deny_request(O)
			. = TRUE
		if("approveall")
			for(var/i in SSpoints.requestlist)
				var/datum/supply_order/O = SSpoints.requestlist[i]
				SSpoints.approve_request(O, ui.user)
			. = TRUE
		if("denyall")
			for(var/i in SSpoints.requestlist)
				var/datum/supply_order/O = SSpoints.requestlist[i]
				SSpoints.deny_request(O)
			. = TRUE
		if("buycart")
			SSpoints.buy_cart(ui.user)
			. = TRUE
		if("clearcart")
			var/list/shopping_cart = get_shopping_cart(ui.user)
			shopping_cart.Cut()
			. = TRUE

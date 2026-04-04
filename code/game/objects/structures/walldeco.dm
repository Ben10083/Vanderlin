// Defines for wanted poster
/// Can't request or declare outlaws
#define NO_OUTLAW_POWER 0
/// Can request someone to be outlawed
#define LIMITED_OUTLAW_POWER 1
/// Can declare someone outlawed and approve requests
#define FULL_OUTLAW_POWER 2


/obj/structure/fluff/walldeco
	name = ""
	desc = ""
	icon = 'icons/roguetown/misc/decoration.dmi'
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	layer = ABOVE_MOB_LAYER+0.1

/obj/structure/fluff/walldeco/proc/get_attached_wall()
	return

/obj/structure/fluff/walldeco/wantedposter
	name = "wanted poster"
	desc = "A list of the worst scoundrels this realm has to offer along with their face sketches."
	icon_state = "wanted1"
	layer = BELOW_MOB_LAYER
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/wantedposter/r
	SET_BASE_PIXEL(32, 0)

/obj/structure/fluff/walldeco/wantedposter/l
	SET_BASE_PIXEL(-32, 0)

/obj/structure/fluff/walldeco/wantedposter/Initialize()
	. = ..()
	icon_state = "wanted[rand(1,3)]"
	dir = pick(GLOB.cardinals)

/obj/structure/fluff/walldeco/wantedposter/examine(mob/user)
	. = ..()
	if(ishuman(user))
		if(user.Adjacent(src))
			var/mob/living/carbon/human/human_user = user
			show_outlaw_headshot(human_user)
		else
			to_chat(user, span_warning("I need to get closer to see the scoundrels' faces!"))

/obj/structure/fluff/walldeco/wantedposter/attackby(obj/item/P, mob/user, list/modifiers)
	if(istype(P, /obj/item/paper) && ishuman(user))
		return declare_outlaw(P, user)

	else
		return ..()

/// Handles declaring or requesting a declaration of Outlaw status. Called by `attackby` when given an object with the path of `/obj/item/paper`
/// Calls additional procs to determine if people is 'worthy' of declaring someone and Outlaw, and whether the person is a valid target
/// If valid, either becomes a requested Outlaw (handled in UI on `examine`) or declares them an Outlaw outright
/obj/structure/fluff/walldeco/wantedposter/proc/declare_outlaw(obj/item/paper/paper, mob/living/carbon/human/human)
	// Determine power they have
	var/outlaw_power = determine_outlaw_power(human)

	if(!outlaw_power)
		to_chat(human, span_warning("You have no authority in [SSmapping.config.map_name], they would never consider this seriously..."))
		return
	if(paper.info)
		to_chat(human, span_warning("How are you going to sketch an outlaw on something that has already been written on?"))
		return

	//check if we have something to write on
	var/has_writer = FALSE
	for(var/obj/item in human.held_items) // tried to have this done differently, but didnt work so doing it this way
		if(istype(item, /obj/item/natural/feather) || istype(item, /obj/item/natural/thorn))
			has_writer = TRUE
	if(!has_writer)
		to_chat(human, span_warning("How are you going to sketch an outlaw without having something to write with?"))
		return

	var/possible_outlaw_name = SANITIZE_HEAR_MESSAGE(tgui_input_text(human, "Who do you want to be an Outlaw?", "The Accused", max_length = 50, encode = FALSE))
	var/mob/living/carbon/human/possible_outlaw

	for(var/mob/living/carbon/human/to_be_outlawed in GLOB.human_list)
		if(to_be_outlawed.real_name == possible_outlaw_name)
			possible_outlaw = to_be_outlawed

		if(to_be_outlawed.job == "Faceless One")
			to_chat(human, span_warning("That person doesn't exist!"))
			return

	if(!possible_outlaw)
		to_chat(human, span_warning("That person doesn't exist!"))
		return

	if(!can_be_outlawed(human, possible_outlaw))
		return

	// Person found, now get reason
	var/crimes = tgui_input_text(human, "Leave blank for 'General Crimes'", "Reason (Optional)", max_length = 75)
	if(!crimes)
		crimes = "General Crimes"

	if(!human.Adjacent(src)) // Not actually working???
		to_chat(human, span_warning("You need to stand near \the [src]!"))
		return

	human.visible_message("[human] starts to sketch out someone's mugshot on \the [paper]", "You start to sketch out a mugshot of [possible_outlaw.real_name] on \the [paper]")
	if(!do_after(human, 15 SECONDS, src, progress = TRUE, display_over_user = TRUE))
		to_chat(human, span_warning("You need to stand still to make an accurate sketch!"))
		return
	else
		human.visible_message("[human] finishes drawing on \the [paper] and attaches it to \the [src]", "You finish your sketch and attach the mugshot of [possible_outlaw.real_name] to \the [src]")
		qdel(paper)

		if(outlaw_power == FULL_OUTLAW_POWER) // Declare them outlaw
			GLOB.outlawed_players[possible_outlaw.real_name] = crimes
			if(crimes != "General Crimes")
				priority_announce("For [crimes], [possible_outlaw.real_name] has been declared an outlaw and must be captured or slain.", "[human.real_name], The [human.get_role_title()] Decrees", 'sound/misc/alert.ogg', "Captain")
			else
				priority_announce("[possible_outlaw.real_name] has been declared an outlaw and must be captured or slain.", "[human.real_name], The [human.get_role_title()] Decrees", 'sound/misc/alert.ogg', "Captain")
		else
			GLOB.outlaw_requested_players[possible_outlaw.real_name] = list(crimes, human.real_name)
			to_chat(human, span_info("With that done, now you need to speak with someone with authority to approve your request..."))

/// Checks if person has the trait `TRAIT_CAN_DECLARE_OUTLAW` or if they are other special roles, returns a define at `walldeco.dm` based on result
/obj/structure/fluff/walldeco/wantedposter/proc/determine_outlaw_power(mob/living/carbon/human/human)
	// Outlaws do not have power over themselves.
	if(GLOB.outlawed_players?[human.real_name])
		return NO_OUTLAW_POWER
	if(HAS_TRAIT(human, TRAIT_CAN_DECLARE_OUTLAW))
		return FULL_OUTLAW_POWER

	if(human.job == "City Watch Lieutenant" || human.job == "Serjeant-at-Arms")
		return LIMITED_OUTLAW_POWER

	if(human.honorary == "Serjeant")
		return LIMITED_OUTLAW_POWER

	// At this stage, person is a NOBODY
	return NO_OUTLAW_POWER

/// This proc checks if person is already an outlaw, or if the `potential_outlaw` is restricted from being an Outlaw unless declared by the Monarch
/obj/structure/fluff/walldeco/wantedposter/proc/can_be_outlawed(mob/living/carbon/human/human, mob/living/carbon/human/potential_outlaw)
	if(GLOB.outlawed_players?[potential_outlaw.real_name])
		to_chat(human, span_warning("That person is already an outlaw!"))
		return FALSE

	if(GLOB.outlaw_requested_players?[potential_outlaw.real_name])
		to_chat(human, span_warning("You realize that someone has submitted a request to make them an Outlaw..."))
		return FALSE

	//if(human.job_type == /datum/job/lord) // The Monarch is never wrong.
		//return TRUE

	if(potential_outlaw.job_type == /datum/job/royalknight || istype(potential_outlaw.job_type, /datum/job/advclass/royalknight))
		to_chat(human, span_warning("You would need to be the Monarch to declare their own knights an Outlaw..."))
		return FALSE

	if(potential_outlaw.job_type == /datum/job/captain)
		to_chat(human, span_warning("You would need to be the Monarch to declare their own Captain an Outlaw..."))
		return FALSE

	if(potential_outlaw.job_type == /datum/job/consort || istype(potential_outlaw.job_type, /datum/job/advclass/consort))
		to_chat(human, span_warning("[potential_outlaw.real_name]... Monarch's own Consort?! You wouldn't dare."))
		return FALSE

	if(potential_outlaw.job_type == /datum/job/hand || istype(potential_outlaw.job_type, /datum/job/advclass/hand))
		to_chat(human, span_warning("[potential_outlaw.real_name] is (officially at least) the Monarch's most trusted advisor, you cannot declare them an Outlaw!"))
		return FALSE

	if(HAS_TRAIT(potential_outlaw, TRAIT_NOBLE_BLOOD) || HAS_TRAIT(potential_outlaw, TRAIT_NOBLE_POWER))
		to_chat(human, span_warning("Only the Monarch can declare someone of noble blood an Outlaw!"))
		return FALSE

	if(potential_outlaw.job_type == /datum/job/priest)
		to_chat(human, span_warning("You accuse their Eminence themselves?! Remove that thought before Astrata smites you where you stand!"))
		return FALSE

	if(potential_outlaw.job_type == /datum/job/monk || potential_outlaw.job_type == /datum/job/templar || potential_outlaw.job_type == /datum/job/gmtemplar || potential_outlaw.job_type == /datum/job/undertaker)
		to_chat(human, span_warning("Only the Monarch can declare one of the Clergy an outlaw..."))
		return FALSE

	return TRUE



/obj/structure/fluff/walldeco/wantedposter/proc/show_outlaw_headshot(mob/living/carbon/human/user)
	var/list/outlaws = list()

	for(var/mob/living/carbon/human/outlaw in GLOB.human_list)
		if(GLOB.outlawed_players?[outlaw.real_name])
			var/icon/credit_icon = SScrediticons.get_credit_icon(outlaw, TRUE)
			if(credit_icon)
				outlaws += list(list(
					"name" = outlaw.real_name,
					"icon" = credit_icon
				))

	if(!length(outlaws))
		to_chat(user, span_warning("There are no wanted criminals at the moment..."))
		return

	if(GLOB.outlawed_players?[user.real_name])
		var/list/funny = list("Yup. My face is on there.", "Wait a minute... That's me!", "Look at that handsome devil...", "At least I am wanted by someone...", "My chin can't be that big... right?")
		to_chat(user, span_notice("[pick(funny)]"))
		if(!HAS_MIND_TRAIT(user, TRAIT_KNOWBANDITS))
			ADD_TRAIT(user.mind, TRAIT_KNOWBANDITS, TRAIT_GENERIC)
			user.playsound_local(user, 'sound/misc/notice (2).ogg', 100, FALSE)
			to_chat(user, span_notice("I can recognize these fine people anywhere now."))
	else if(!HAS_MIND_TRAIT(user, TRAIT_KNOWBANDITS))
		ADD_TRAIT(user.mind, TRAIT_KNOWBANDITS, TRAIT_GENERIC)
		user.playsound_local(user, 'sound/misc/notice (2).ogg', 100, FALSE)
		to_chat(user, span_notice("I can recognize these faces as wanted criminals now."))

	var/dat = {"
	<style>
		.wanted-container {
			display: grid;
			grid-template-columns: repeat(3, 1fr);
			gap: 20px;
			padding: 15px;
		}
		.wanted-poster {
			width: 175px;
			height: 228px;
			border: 3px double #5c2c0f;
			background-color: #f5e7d0;
			padding: 8px;
			box-shadow: 3px 3px 5px rgba(0,0,0,0.3);
			font-family: 'Times New Roman', serif;
			display: flex;
			flex-direction: column;
		}
		.wanted-header {
			color: #c70404;
			font-size: 28px;
			font-weight: bold;
			text-align: center;
			margin-bottom: 5px;
			text-transform: uppercase;
		}
		.wanted-divider {
			border-bottom: 2px solid #8B0000;
			margin: 5px 0;
		}
		.wanted-footer {
			color: #8B0000;
			font-size: 16px;
			font-weight: bold;
			text-align: center;
			margin-bottom: 8px;
			text-transform: uppercase;
		}
		.wanted-icon-container {
			width: 120px;
			height: 85px;
			margin: 0 auto;
			border: 2px solid #5c2c0f;
			background-color: #ccac74;
			padding: 3px;
		}
		.wanted-icon {
			width: 100%;
			height: 90%;
			object-fit: cover;
			image-rendering: pixelated;
		}
		.wanted-name-container {
			flex-grow: 1;
			display: flex;
			flex-direction: column;
			justify-content: center;
			min-height: 65px;
			margin-top: 5px;
		}
		.wanted-name {
			color: #000000;
			font-size: 18px;
			font-weight: bold;
			text-align: center;
			padding: 0 5px;
			text-transform: uppercase;
			word-break: break-word;
			overflow: hidden;
			display: -webkit-box;
			-webkit-line-clamp: 3;
			-webkit-box-orient: vertical;
		}
	</style>
	<div class='wanted-container'>
	"}

	for(var/list/outlaw_data in outlaws)
		var/icon_html = ""
		if(outlaw_data["icon"])
			icon_html = "<img class='wanted-icon' src='data:image/png;base64,[icon2base64(outlaw_data["icon"])]'>"
		else
			icon_html = "<div class='wanted-icon' style='background:#8B4513;'></div>"

		dat += {"
		<div class='wanted-poster'>
			<div class='wanted-header'>WANTED</div>
			<div class='wanted-divider'></div>
			<div class='wanted-footer'>DEAD OR ALIVE</div>
			<div class='wanted-icon-container'>
				[icon_html]
			</div>
			<div class='wanted-name-container'>
				<div class='wanted-name'>[outlaw_data["name"]]</div>
			</div>
		</div>
		"}

	dat += "</div>"

	var/datum/browser/popup = new(user, "wanted_posters", "<center>Wanted Posters</center>", 688, 570)
	popup.set_content(dat)
	popup.open()

/obj/structure/fluff/walldeco/innsign
	name = "sign"
	desc = ""
	icon_state = "bar"
	layer = ABOVE_MOB_LAYER

/obj/structure/fluff/walldeco/steward
	name = "sign"
	desc = ""
	icon_state = "steward"
	layer = ABOVE_MOB_LAYER

/obj/structure/fluff/walldeco/bsmith
	name = "sign"
	desc = ""
	icon = 'icons/roguetown/misc/tallstructure.dmi'
	icon_state = "bsmith"
	layer = ABOVE_MOB_LAYER

/obj/structure/fluff/walldeco/goblet
	name = "sign"
	desc = ""
	icon = 'icons/roguetown/misc/tallstructure.dmi'
	icon_state = "goblet"
	layer = ABOVE_MOB_LAYER

/obj/structure/fluff/walldeco/sparrowflag
	name = "sparrow flag"
	desc = ""
	icon_state = "sparrow"

/obj/structure/fluff/walldeco/xavo
	name = "xavo flag"
	desc = ""
	icon_state = "xavo"

/obj/structure/fluff/walldeco/serpflag
	name = "serpent flag"
	desc = ""
	icon_state = "serpent"

/obj/structure/fluff/walldeco/masonflag
	name = "Maker's Guild flag"
	desc = "A flag bearing the logo of the Maker's Guild."
	icon_state = "mason"

/obj/structure/fluff/walldeco/maidendrape
	name = "black drape"
	desc = "A drape of fabric."
	icon_state = "black_drape"
	dir = SOUTH
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/wallshield
	name = ""
	desc = ""
	icon_state = "wallshield"

/obj/structure/fluff/walldeco/psybanner
	name = "banner"
	icon_state = "Psybanner-PURPLE"

/obj/structure/fluff/walldeco/psybanner/red
	icon_state = "Psybanner-RED"

/obj/structure/fluff/walldeco/stone
	name = ""
	desc = ""
	icon_state = "walldec1"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/structure/fluff/walldeco/church/line
	name = ""
	desc = ""
	icon_state = "churchslate"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = TURF_DECAL_LAYER

/obj/structure/fluff/walldeco/stone/Initialize()
	. = ..()
	icon_state = "walldec[rand(1,6)]"

/obj/structure/fluff/walldeco/maidensigil
	name = "stone sigil"
	desc = ""
	icon_state = "maidensigil"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	dir = SOUTH
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/maidensigil/r
	dir = WEST
	SET_BASE_PIXEL(16, 0)

/obj/structure/fluff/walldeco/bigpainting
	name = "painting"
	icon = 'icons/roguetown/misc/64x64.dmi'
	icon_state = "sherwoods"
	SET_BASE_PIXEL(-16, 32)

/obj/structure/fluff/walldeco/bigpainting/lake
	icon_state = "lake"

/obj/structure/fluff/walldeco/mona
	name = "painting"
	icon = 'icons/roguetown/misc/tallstructure.dmi'
	icon_state = "mona"
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/chains
	name = "hanging chains"
	alpha = 180
	layer = 4.26
	icon_state = "chains1"
	icon = 'icons/roguetown/misc/tallstructure.dmi'
	can_buckle = 1
	buckle_lying = 0
	breakoutextra = 10 MINUTES
	buckleverb = "tie"

/obj/structure/fluff/walldeco/chains/Initialize()
	. = ..()
	icon_state = "chains[rand(1,8)]"

/obj/structure/fluff/walldeco/customflag
	name = "vanderlin flag"
	desc = ""
	icon_state = "wallflag"
	uses_lord_coloring = LORD_PRIMARY | LORD_SECONDARY

/obj/structure/fluff/walldeco/moon
	name = "banner"
	icon_state = "moon"

/obj/structure/fluff/walldeco/med
	name = "diagram"
	icon_state = "medposter"

/obj/structure/fluff/walldeco/med2
	name = "diagram"
	icon_state = "medposter2"

/obj/structure/fluff/walldeco/med3
	name = "diagram"
	icon_state = "medposter3"

/obj/structure/fluff/walldeco/med4
	name = "diagram"
	icon_state = "medposter4"


/obj/structure/fluff/walldeco/med5
	name = "diagram"
	icon_state = "medposter5"

/obj/structure/fluff/walldeco/med6
	name = "diagram"
	icon_state = "medposter6"

/obj/structure/fluff/walldeco/skullspike // for ground really
	icon_state = "skullspike"
	plane = -1
	layer = ABOVE_MOB_LAYER
	SET_BASE_PIXEL(8, 24)

/*	..................   The Drunken Saiga   ................... */
/obj/structure/fluff/walldeco/sign/saiga
	name = "The Drunken Saiga"
	icon_state = "shopsign_inn_saiga_right"
	plane = -1
	SET_BASE_PIXEL(3, 16)

/obj/structure/fluff/walldeco/sign/saiga/left
	icon_state = "shopsign_inn_saiga_left"

/obj/structure/fluff/walldeco/sign/trophy
	name = "saiga trophy"
	icon_state = "saiga_trophy"
	SET_BASE_PIXEL(0, 32)

/*	..................   Feldsher Sign   ................... */
/obj/structure/fluff/walldeco/feldshersign
	name = "feldsher sign"
	icon_state = "feldsher"
	SET_BASE_PIXEL(0, 32)

/*	..................   Weaponsmith Sign   ................... */
/obj/structure/fluff/walldeco/sign/weaponsmithsign
	name = "weaponsmith shop sign"
	icon_state = "shopsign_weaponsmith_right"
	plane = -1
	SET_BASE_PIXEL(0, 16)

/obj/structure/fluff/walldeco/sign/weaponsmithsign/left
	icon_state = "shopsign_weaponsmith_left"

/*	..................   Armorsmith Sign   ................... */
/obj/structure/fluff/walldeco/sign/armorsmithsign
	name = "armorsmith shop sign"
	icon_state = "shopsign_armorsmith_right"
	plane = -1
	SET_BASE_PIXEL(0, 16)

/obj/structure/fluff/walldeco/sign/armorsmithsign/left
	icon_state = "shopsign_armorsmith_left"

/*	..................   Merchant Sign   ................... */
/obj/structure/fluff/walldeco/sign/merchantsign
	name = "merchant shop sign"
	icon_state = "shopsign_merchant_right"
	plane = -1
	SET_BASE_PIXEL(0, 16)

/obj/structure/fluff/walldeco/sign/merchantsign/left
	icon_state = "shopsign_merchant_left"

/*	..................   Apothecary Sign   ................... */
/obj/structure/fluff/walldeco/sign/apothecarysign
	name = "apothecary sign"
	icon_state = "shopsign_apothecary_right"
	plane = -1
	SET_BASE_PIXEL(0, 16)

/obj/structure/fluff/walldeco/sign/apothecarysign/left
	icon_state = "shopsign_apothecary_left"
/*	..................   Tailor Sign   ................... */
/obj/structure/fluff/walldeco/sign/tailorsign
	name = "tailor sign"
	icon_state = "shopsign_tailor_right"
	plane = -1
	SET_BASE_PIXEL(0, 16)

/obj/structure/fluff/walldeco/sign/tailorsign/left
	icon_state = "shopsign_tailor_left"

/*	..................   Wall decorations   ................... */
/obj/structure/fluff/walldeco/bath // suggestive stonework
	icon_state = "bath1"
	SET_BASE_PIXEL(-32, 0)
	alpha = 210

/obj/structure/fluff/walldeco/bath/two
	icon_state = "bath2"
	SET_BASE_PIXEL(-29, 0)

/obj/structure/fluff/walldeco/bath/three
	icon_state = "bath3"
	SET_BASE_PIXEL(-29, 0)

/obj/structure/fluff/walldeco/bath/four
	icon_state = "bath4"
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/bath/five
	icon_state = "bath5"
	SET_BASE_PIXEL(-29, 0)

/obj/structure/fluff/walldeco/bath/six
	icon_state = "bath6"
	SET_BASE_PIXEL(-29, 0)

/obj/structure/fluff/walldeco/bath/seven
	icon_state = "bath7"
	SET_BASE_PIXEL(32, 0)

/obj/structure/fluff/walldeco/bath/gents
	icon_state = "gents"
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/bath/ladies
	icon_state = "ladies"
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/bath/wallrope
	icon_state = "wallrope"
	layer = WALL_OBJ_LAYER+0.1
	SET_BASE_PIXEL(0, 0)
	color = "#d66262"

/obj/effect/decal/shadow_floor
	name = ""
	desc = ""
	icon = 'icons/roguetown/misc/decoration.dmi'
	icon_state = "shadow_floor"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/decal/shadow_floor/corner
	icon_state = "shad_floorcorn"

/obj/structure/fluff/walldeco/gear
	icon_state = "gear_norm"

/obj/structure/fluff/walldeco/gear/small
	icon_state = "gear_small"

/obj/structure/fluff/walldeco/bath/wallpipes
	icon_state = "wallpipe"
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/bath/wallpipes/innie
	icon_state = "wallpipe_innie"
	pixel_y = 0

/obj/structure/fluff/walldeco/bath/wallpipes/outie
	icon_state = "wallpipe_outie"
	pixel_y = 0

/obj/structure/fluff/walldeco/bath/random
	icon_state = "bath"
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/bath/random/Initialize()
	. = ..()
	if(icon_state == "bath")
		icon_state = "bath[rand(1,8)]"

/obj/structure/fluff/walldeco/vinez
	name = "vines"
	icon_state = "vinez"

/obj/structure/fluff/walldeco/vinez/l
	SET_BASE_PIXEL(-32, 0)

/obj/structure/fluff/walldeco/vinez/r
	SET_BASE_PIXEL(32, 0)

/obj/structure/fluff/walldeco/vinez/offset
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/vinez/blue
	icon_state = "vinez_blue"

/obj/structure/fluff/walldeco/vinez/red
	icon_state = "vinez_red"


#undef NO_OUTLAW_POWER
#undef LIMITED_OUTLAW_POWER
#undef FULL_OUTLAW_POWER

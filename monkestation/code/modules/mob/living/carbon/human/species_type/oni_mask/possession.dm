/mob/living/backseat
	name = "Mind Backseat"
	var/datum/weakref/body = /mob/living

/datum/component/posessor
	var/datum/mind/held_mind = null
	var/datum/mind/victim_mind = null //ik these should probably be weakrefs ill fix it later, just forcing it to compile
	var/datum/weakref/victim_body = null
	var/mob/living/backseat/possessor_backseat = new
	var/mob/living/backseat/victim_backseat = new

/datum/component/posessor/Initialize(...)
	. = ..()

/datum/component/posessor/Destroy(force)
	. = ..()
	qdel(possessor_backseat)
	qdel(victim_backseat)

/datum/component/posessor/proc/yoink_mind(mob/living/victim)
	if(!victim.mind == null)
		victim_mind = victim.mind
		victim_body = victim
		victim_backseat.body = victim
		possessor_backseat.body = victim

/datum/component/posessor/proc/possess(mob/living/victim)
	if(!isnull(held_mind))
		held_mind.transfer_to(victim)
		log_combat(held_mind, victim, "posessed")

	if(!isnull(victim.mind))
		victim_mind.transfer_to(victim_backseat)
		log_game("[src] is possessed and switches to the backseat!")

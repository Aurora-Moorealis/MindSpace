class_name MachineDatabase
extends Resource

## Index of every machine sheet.
##
## The eight-id coverage is enforced by GameSim because SimState owns the
## frozen id list; this resource only knows about the sheets it references.

@export var machines: Array[MachineData] = []


## Returns the machine with the given id, or null when it does not exist.
func get_machine(id: StringName) -> MachineData:
	for machine: MachineData in machines:
		if machine != null and machine.id == id:
			return machine
	return null


## Returns human-readable problems (empty array == valid database).
func validate() -> Array[String]:
	var messages: Array[String] = []
	var seen_ids: Dictionary[StringName, bool] = {}

	for index: int in machines.size():
		var machine: MachineData = machines[index]
		if machine == null:
			messages.append("machine %d: row is null" % index)
			continue
		if machine.id == &"":
			messages.append("machine %d: id is empty" % index)
		if seen_ids.has(machine.id):
			messages.append(
				"machine %d ('%s'): id is duplicated" % [index, String(machine.id)]
			)
		else:
			seen_ids[machine.id] = true
		messages.append_array(machine.validate())

	return messages

class_name PowerLink
extends RefCounted

## Undirected cable join between two power-node ids.

var a: StringName = &""
var b: StringName = &""


func _init(from_node: StringName = &"", to_node: StringName = &"") -> void:
	a = from_node
	b = to_node


## A link is usable only when both ends name a node and they are different.
func is_valid() -> bool:
	return a != &"" and b != &"" and a != b


## True when the link touches the given node.
func connects(node_id: StringName) -> bool:
	return a == node_id or b == node_id


## The node at the other end, or an empty id when it does not touch node_id.
func other_than(node_id: StringName) -> StringName:
	if a == node_id:
		return b
	if b == node_id:
		return a
	return &""

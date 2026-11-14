class_name EvaluationSummary
extends RefCounted

## Flat aggregate snapshot computed by EventLog.get_summary().

var reports_sent: int = 0
var submissions_completed: int = 0
var final_resources: Dictionary[StringName, float] = {}
var peak_radiation: float = 0.0
var shelter_uses: int = 0
var sols_elapsed: int = 0

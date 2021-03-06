/*
	VEMF Spawn AI by Vampire
	
	This code is under a Non-Commercial ShareAlike License.
	Make sure to read the LICENSE before using this code elsewhere.
	
	Description:
		Spawns AI to the target location
		Player must be within 800m or they get Cached after spawning
		(Write your code to spawn them after player is near)
		
	Usage: [_positionArray, True, SkillLvl, GroupCount] call VEMFSpawnAI;
		
	Variables:
		0: Position Array (1 Unit Per Position)
		1: BOOLEAN - (True) Strict or (False) Rough Group Leader Assignments?
			Strict will keep groups to your specifications,
			Rough will spawn a unit at each position and group them more passively.
			- Use Strict For Spawning En-Mass, and Rough for Fine Positioning
		2: Skill Level Max (1-4)
		3: Group Count (Optional) required if 1 is True.
			The amount of groups you want.
			If you supply a group count, and 1 is True, you will get one group spawned at each position.
*/
private ["_posArr","_SorR","_skill","_grpCount","_sldrClass","_unitsPerGrp","_owner","_grp","_newPos","_grpArr","_unit","_pos"];

_posArr   = _this select 0;
_SorR     = _this select 1;
_skill    = _this select 2;
_grpCount = _this select 3;

if ((typeName _posArr) != "ARRAY") exitWith { /* Not an Array */ };
if ((typeName _SorR) != "BOOLEAN") exitWith { /* Not True/False */ };
//if ((typeName _skill) != "SCALAR") exitWith { /* Not a Number */ };
if ((_SorR == true) && ((isNil "_grpCount") || (_grpCount < 1))) exitWith {
	diag_log text format ["[VEMF]: Warning: AI Spawn: Strict Distribution Called Without Group Count!"];
};

_sldrClass = "I_Soldier_EPOCH";
_unitsPerGrp = 4;

// We need to do this two very different ways depending on Strict or Rough Distribution
if (_SorR == true) then
{
	// Strict Distribution

	if (count _posArr > 1) then {
		// We have multiple positions. Spawn a group at each one.
		
		// Check for Nested Array
		if (typeName (_posArr select 0) == "SCALAR") exitWith {
			diag_log text format ["[VEMF]: Warning: AI Spawn: Strict Distribution Not a Nested Array!"];
		};
		
		// Find the Owner
		_owner = owner (((_posArr select 0) nearEntities [["Epoch_Male_F", "Epoch_Female_F"], 800]) select 0);
		
		// Create the Group
		_grp = createGroup RESISTANCE;
		_grp setBehaviour "AWARE";
		_grp setCombatMode "RED";
		
		{
			for "_i" from 1 to (_grpCount*_unitsPerGrp) do
			{
				// Find Nearby Position (Radius 25m)
				_newPos = [_x,0,25,60,0,20,0] call BIS_fnc_findSafePos;
				
				if (count (units _grp) == _unitsPerGrp) then {
					// Fireteam is Full, Create a New Group
					_grpArr = [];
					_grpArr = _grpArr + [_grp];
					_grp = grpNull;
					_grp = createGroup RESISTANCE;
					_grp setBehaviour "AWARE";
					_grp setCombatMode "RED";
				};
				
				// Create Unit There
				_unit = _grp createUnit [_sldrClass, _newPos, [], 0, "FORM"];
				
				// Enable its AI
				_unit setSkill 0.6;
				_unit setRank "Private";
				_unit enableAI "TARGET";
				_unit enableAI "AUTOTARGET";
				_unit enableAI "MOVE";
				_unit enableAI "ANIM";
				// Might write a custom FSM in the future
				// Default Arma 3 Soldier FSM for now
				_unit enableAI "FSM";
				
				// Prepare for Cleanup or Caching
				_unit addEventHandler ["Killed",{ [(_this select 0), (_this select 1)] ExecVM VEMFAIKilled; }];
				_unit setVariable ["VEMFAI", true];
				
				// Leader Assignment
				if (count (units _grp) == _unitsPerGrp) then {
					_unit setSkill 1;
					_grp selectLeader _unit;
				};
				
				// Set Owner to Prevent Server Local Cleanup
				_unit setOwner _owner;
			};
		} forEach _posArr;

		//diag_log text format ["[VEMF]: AI Debug: Spawned %1 Units at Grid %2", (_grpCount*_unitsPerGrp), (mapGridPosition _pos)];
		
	} else {
	
		// We have a single POS given.
		// Check for a nested array
		if (typeName (_posArr select 0) != "SCALAR") then {
			_pos = _posArr select 0;
		} else {
			_pos = _posArr;
		};
		
		// Find the Owner
		_owner = owner ((_pos nearEntities [["Epoch_Male_F", "Epoch_Female_F"], 800]) select 0);
	
		// Create the Group
		_grp = createGroup RESISTANCE;
		_grp setBehaviour "AWARE";
		_grp setCombatMode "RED";
		
		// Spawn Groups near Position
		for "_i" from 1 to (_grpCount*_unitsPerGrp) do
		{
			// Find Nearby Position (Radius 25m)
			_newPos = [_pos,0,25,60,0,20,0] call BIS_fnc_findSafePos;
			
			if (count (units _grp) == _unitsPerGrp) then {
				// Fireteam is Full, Create a New Group
				_grpArr = [];
				_grpArr = _grpArr + [_grp];
				_grp = grpNull;
				_grp = createGroup RESISTANCE;
				_grp setBehaviour "AWARE";
				_grp setCombatMode "RED";
			};
			
			// Create Unit There
			_unit = _grp createUnit [_sldrClass, _newPos, [], 0, "FORM"];
			
			// Enable its AI
			_unit setSkill 0.6;
			_unit setRank "Private";
			_unit enableAI "TARGET";
			_unit enableAI "AUTOTARGET";
			_unit enableAI "MOVE";
			_unit enableAI "ANIM";
			// Might write a custom FSM in the future
			// Default Arma 3 Soldier FSM for now
			_unit enableAI "FSM";
			
			// Prepare for Cleanup or Caching
			_unit addEventHandler ["Killed",{ [(_this select 0), (_this select 1)] ExecVM VEMFAIKilled; }];
			_unit setVariable ["VEMFAI", true];
			
			// Leader Assignment
			if (count (units _grp) == _unitsPerGrp) then {
				_unit setSkill 1;
				_grp selectLeader _unit;
			};
			
			// Set Owner to Prevent Server Local Cleanup
			_unit setOwner _owner;
		};
		
		//diag_log text format ["[VEMF]: AI Debug: Spawned %1 Units at Grid %2", (_grpCount*_unitsPerGrp), (mapGridPosition _pos)];
	};

} else {

	// Rough Distribution

	if (typeName (_posArr select 0) == "SCALAR") exitWith {
		diag_log text format ["[VEMF]: Warning: AI Spawn: Rough Distribution Requires Multiple Positions!"];
	};
	
	// Only used for the log
	_pos = _posArr select 0;
	
	// Find the Owner
	_owner = owner ((_pos nearEntities [["Epoch_Male_F", "Epoch_Female_F"], 800]) select 0);
	
	// Create the Group
	_grp = createGroup RESISTANCE;
	_grp setBehaviour "AWARE";
	_grp setCombatMode "RED";

	{
		// Create Unit
		_unit = _grp createUnit [_sldrClass, _x, [], 0, "FORM"];
	
		// Enable its AI
		_unit setSkill 0.6;
		_unit setRank "Private";
		_unit enableAI "TARGET";
		_unit enableAI "AUTOTARGET";
		_unit enableAI "MOVE";
		_unit enableAI "ANIM";
		// Might write a custom FSM in the future
		// Default Arma 3 Soldier FSM for now
		_unit enableAI "FSM";
		
		// Prepare for Cleanup or Caching
		_unit addEventHandler ["Killed",{ [(_this select 0), (_this select 1)] ExecVM VEMFAIKilled; }];
		_unit setVariable ["VEMFAI", true];
		
		// Separate Groups via Location Distance
		// Logic is that group positions come in via houses
		// Therefore separate them to one group per house
		if (_forEachIndex != 0) then {
			if ((_x distance (_posArr select (_forEachIndex-1))) > 25) then {
				// Too Far, Need New Group
				_unit setSkill 1;
				_grp selectLeader _unit;
				_grpArr = [];
				_grpArr = _grpArr + [_grp];
				_grp = grpNull;
				_grp = createGroup RESISTANCE;
				_grp setBehaviour "AWARE";
				_grp setCombatMode "RED";
			};
		};
		
		// Set Owner to Prevent Server Local Cleanup
		_owner = (_newPos nearEntities [["Epoch_Male_F", "Epoch_Female_F"], 800]) select 0;
		_unit setOwner (owner _owner);
	} forEach _posArr;
	
	//diag_log text format ["[VEMF]: AI Debug: Spawned %1 Units near Grid %2", (count _posArr), (mapGridPosition _pos)];
};

// Add Units to Cache Watchdog
VEMFWatchAI = VEMFWatchAI + _grpArr;
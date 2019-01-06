disableSerialization;

_display = _this select 0;
_lastRange = artyRange;
_lastUpdate = 0;
_listBox = 17019;
_restriction = 'WFBE_RESTRICTIONADVAIR' Call GetNamespace;

sliderSetRange[17005,10,'WFBE_MAXARTILLERYAREA' Call GetNamespace];
sliderSetPosition[17005,artyRange];

ctrlSetText [17025,localize "STR_WF_TACTICAL_ArtilleryOverview" + ":"];

_markers = [];
_FTLocations = [];
_checks = [];
_fireTime = 0;
_status = 0;
_canFT = false;
_forceReload = true;
_ft = 'WFBE_FASTTRAVEL' Call GetNamespace;
_ftr = 'WFBE_FASTTRAVELRANGE' Call GetNamespace;
_startPoint = objNull;

_marker = "artilleryMarker";
createMarkerLocal [_marker,artyPos];
_marker setMarkerTypeLocal "mil_destroy";
_marker setMarkerColorLocal "ColorRed";
_marker setMarkerSizeLocal [1,1];

_area = "artilleryAreaMarker";
createMarkerLocal [_area,artyPos];
_area setMarkerShapeLocal "Ellipse";
_area setMarkerColorLocal "ColorRed";
_area setMarkerSizeLocal [artyRange,artyRange];

_map = _display DisplayCtrl 17002;
_listboxControl = _display DisplayCtrl _listBox;

_pard = 'WFBE_PARADELAY' Call GetNamespace;
{lbAdd[17008,_x]} forEach (Format ["WFBE_%1_ARTILLERY_DESC",sideJoinedText] Call GetNamespace);
lbSetCurSel[17008,0];

_IDCS = [17005,17006,17007,17008];
if !(paramArty) then {{ctrlEnable [_x,false]} forEach _IDCS};

{ctrlEnable [_x, false]} forEach [17010,17011,17012,17013,17014,17015,17017,17018,17020];

Warfare_MenuAction = -1;
mouseButtonUp = -1;
_currentValue = -1;
_currentFee = -1;
_currentSpecial = "";
_currentFee = -1;

//--- Support List.
_lastSel = -1;
_addToList = [localize 'STR_WF_TACTICAL_FastTravel',localize 'STR_WF_TACTICAL_Paratroop',localize 'STR_WF_TACTICAL_ParadropAmmo',localize 'STR_WF_TACTICAL_ParadropVehicle',localize 'STR_WF_TACTICAL_UnitCam',localize 'STR_WF_TACTICAL_UAV',localize 'STR_WF_TACTICAL_UAVDestroy'];
_addToListID = ["Fast_Travel","Paratroopers","Paradrop_Ammo","Paradrop_Vehicle","Units_Camera","UAV","UAV_Destroy"];
_addToListFee = [0,10000,5000,30000,0,2000,0,0,0];
_addToListInterval = [0,500,300,1000,0,0,0,0];

/*if (WF_Debug) then {_addToListFee = [0,0,0,0,0,0,0,0,0];};*/

for '_i' from 0 to count(_addToList)-1 do {
	lbAdd [_listBox,_addToList select _i];
	lbSetValue [_listBox, _i, _i];
};

lbSort _listboxControl;

//--- Artillery Mode.
_mode = 'WFBE_V_ARTILLERYMINMAP' Call GetNamespace;
if (isNil '_mode') then {_mode = 2;['WFBE_V_ARTILLERYMINMAP',_mode,true] Call SetNamespace};
_trackingArray = [];
_trackingArrayID = [];
_lastArtyUpdate = -60;
_minRange = 100;
_maxRange = 200;
_requestMarkerTransition = false;
_requestRangedList = true;
_startLoad = true;

//--- Startup coloration.
with uinamespace do {
	currentBEDialog = _display;
	switch (_mode) do {
		case 0: {(currentBEDialog displayCtrl 17023) ctrlSetTextColor [1,1,1,1]};
		case 1: {(currentBEDialog displayCtrl 17023) ctrlSetTextColor [0,0.635294,0.909803,1]};
		case 2: {(currentBEDialog displayCtrl 17023) ctrlSetTextColor [0.6,0.850980,0.917647,1]};
	};
};

lbSetCurSel[_listbox, 0];

if (!paramArty) then {
	(_display displayCtrl 17016) ctrlSetStructuredText (parseText Format['<t align="right" color="#FF4747">%1</t>',localize 'STR_WF_Disabled']);
};

_textAnimHandler = [] spawn {};

while {alive player && dialog} do {
	if (side player != sideJoined) exitWith {deleteMarkerLocal _marker;deleteMarkerLocal _area;{deleteMarkerLocal _x} forEach _markers;closeDialog 0};
	if (!dialog) exitWith {deleteMarkerLocal _marker;deleteMarkerLocal _area;{deleteMarkerLocal _x} forEach _markers};
	
	_currentUpgrades = (sideJoinedText) Call GetSideUpgrades;
	
	if (_ft > 0) then {
		//--- TODO: Travel fee, mod parameter > FT free or pay, do a clt fct.
		_currentLevel = _currentUpgrades select 12;
		if (time - _lastUpdate > 15 && _currentLevel > 0) then {
			{deleteMarkerLocal _x} forEach _markers;
			_markers = [];
			_FTLocations = [];
			_canFT = false;
			_startPoint = objNull;
			_lastUpdate = time;
			_base = (sideJoinedText) Call GetSideHQ;
			_isDeployed = (sideJoinedText) Call GetSideHQDeployed;
			if (player distance _base < _ftr && alive _base && vehicle player != _base && _isDeployed) then {
				_canFT = true;
				_startPoint = _base;
			} else {
				_sorted = [player,towns] Call SortByDistance;
				_closest = _sorted select 0;
				_sideID = _closest getVariable "sideID";
				_camps = [_closest,sideJoined] Call GetFriendlyCamps;
				_allCamps = _closest getVariable "camps";
				if (_sideID == sideID && player distance _closest < _ftr && (count _camps == count _allCamps)) then {_canFT = true;_startPoint = _closest} else {
					_buildings = (sideJoinedText) Call GetSideStructures;
					_checks = [sideJoined,Format ["WFBE_%1COMMANDCENTERTYPE",sideJoinedText] Call GetNamespace,_buildings] Call GetFactories;
					if (count _checks > 0) then {
						_sorted = [player,_checks] Call SortByDistance;
						_closest = _sorted select 0;
						if (player distance _closest < _ftr) then {
							_canFT = true;
							_closest = _sorted select 0;
							_startPoint = _closest;			
						};
					};
				};
			};
			if (!canMove (vehicle player)) then {_canFT = false};
			if (_canFT) then {
				_buildings = (sideJoinedText) Call GetSideStructures;
				_checks = [sideJoined,Format ["WFBE_%1COMMANDCENTERTYPE",sideJoinedText] Call GetNamespace,_buildings] Call GetFactories;
				_locations = towns + _checks;
				if (alive _base && _isDeployed) then {_locations = _locations + [_base]};
				_i = 0;
				_fee = 0;
				_funds = if (_ft == 2) then {Call GetPlayerFunds} else {0};
				{
					if (_x distance player <= ('WFBE_FASTTRAVELMAXRANGE' Call GetNamespace) && _x distance player > _ftr) then {
						_skip = false;
						if (_x in towns) then {
							_sideID = _x getVariable "sideID";
							_camps = [_x,sideJoined] Call GetFriendlyCamps;
							_allCamps = _x getVariable "camps";
							if (_sideID != sideID || (count _camps != count _allCamps)) then {_skip = true};
							if (_ft == 2) then {
								_fee = round(((_x distance player)/1000) * ('WFBE_FASTTRAVELPRICEKM' Call GetNamespace));
								if (_funds < _fee) then {_skip = true};
							};
						};
						if !(_skip) then {
							_FTLocations = _FTLocations + [_x];
							_markerName = Format ["FTMarker%1",_i];
							_markers = _markers + [_markerName];
							createMarkerLocal [_markerName,getPos _x];
							_markerName setMarkerTypeLocal "mil_circle";
							_markerName setMarkerColorLocal "ColorYellow";
							_markerName setMarkerSizeLocal [1,1];
							//--- Fee, Cheap marker stuff, TBD: Add prompt or something.
							if (_ft == 2) then {
								_markerName = Format ["FTMarker%1%1",_i];
								_markers = _markers + [_markerName];
								createMarkerLocal [_markerName,[(getPos _x select 0)-5,(getPos _x select 1)+75]];
								_markerName setMarkerTypeLocal "mil_circle";
								_markerName setMarkerColorLocal "ColorYellow";
								_markerName setMarkerSizeLocal [0,0];
								_markerName setMarkerTextLocal Format ["$%1",_fee];
							};
							_i = _i + 1;
						};
					};
				} forEach _locations;
			};
		};
	};
	
	_currentSel = lbCurSel(_listBox);
	
	//--- Special changed or a reload is requested.
	if (_currentSel != _lastSel || _forceReload) then {
		_currentValue = lbValue[_listBox, _currentSel];
		
		_currentSpecial = _addToListID select _currentValue;
		_currentFee = _addToListFee select _currentValue;
		_currentInterval = _addToListInterval select _currentValue;

		_forceReload = false;
		_controlEnable = false;
		
		_funds = Call GetPlayerFunds;
		
		//ctrlSetText[17021,Format ["%1: $%2",localize 'STR_WF_Price',_currentFee]]; //---old
		ctrlSetText[17021,Format ["$%1",_currentFee]]; //---added-MrNiceGuy
		
		//--- Enabled or disabled?
		switch (_currentSpecial) do {
			case "Fast_Travel": {
				if (_ft > 0) then {
					_currentLevel = _currentUpgrades select 12;
					_controlEnable = if (count _FTLocations > 0 && _currentLevel > 0) then {true} else {false};
				};
			};
			case "ICBM": {
				if (paramICBM) then {
					_commander = false;
					if (!isNull(commanderTeam)) then {
						if (commanderTeam == group player) then {_commander = true};
					};
					_currentLevel = _currentUpgrades select 11;
					_controlEnable = if (_currentLevel > 0 && _commander && _funds >= _currentFee) then {true} else {false};
				};
			};
			case "Paratroopers": {
				_currentLevel = _currentUpgrades select 0;
				_controlEnable = if (_funds >= _currentFee && _currentLevel > 1 && time - lastParaCall > _currentInterval) then {true} else {false};
			};
			case "Paradrop_Ammo": {
				_currentLevel = _currentUpgrades select 0;
				_controlEnable = if (_funds >= _currentFee && _currentLevel > 2 && time - lastSupplyCall > _currentInterval) then {true} else {false};
			};
			case "Paradrop_Vehicle": {
				_currentLevel = _currentUpgrades select 16;
				_controlEnable = if (_funds >= _currentFee && _currentLevel > 0 && time - lastSupplyCall > _currentInterval) then {true} else {false};
			};
			case "UAV": {
				_currentLevel = _currentUpgrades select 3;
				_controlEnable = if (_funds >= _currentFee && _currentLevel > 0 && !(alive playerUAV) && (_restriction == 0)) then {true} else {false};
			};
			case "UAV_Destroy": {
				_controlEnable = if (alive playerUAV) then {true} else {false};
			};
/*
			case "UAV_Remote_Control": {
				_controlEnable = if (alive playerUAV) then {true} else {false};
			};
*/
			case "Units_Camera": {
				_controlEnable = commandInRange;
			};
		};
		
		ctrlEnable[17020, _controlEnable];
	};
	
	//--- Action triggered.
	if (Warfare_MenuAction == 20) then {
		Warfare_MenuAction = -1;
		
		//--- Output.
		switch (_currentSpecial) do {
			case "Fast_Travel": {
				Warfare_MenuAction = 7;
				if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
				_textAnimHandler = [17022,localize 'STR_WF_TACTICAL_ClickOnMap',10,"ff9900"] spawn SetControlFadeAnim;
			};
			case "ICBM": {
				Warfare_MenuAction = 8;
				if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
				_textAnimHandler = [17022,localize 'STR_WF_TACTICAL_ClickOnMap',10,"ff9900"] spawn SetControlFadeAnim;
			};
			case "Paratroopers": {
				Warfare_MenuAction = 3;
				if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
				_textAnimHandler = [17022,localize 'STR_WF_TACTICAL_ClickOnMap',10,"ff9900"] spawn SetControlFadeAnim;
			};
			case "Paradrop_Ammo": {
				Warfare_MenuAction = 10;
				if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
				_textAnimHandler = [17022,localize 'STR_WF_TACTICAL_ClickOnMap',10,"ff9900"] spawn SetControlFadeAnim;
			};
			case "Paradrop_Vehicle": {
				Warfare_MenuAction = 9;
				
				if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
				_textAnimHandler = [17022,localize 'STR_WF_TACTICAL_ClickOnMap',10,"ff9900"] spawn SetControlFadeAnim;
			};
			case "UAV": {
				closeDialog 0;
				playsound "bitmenu";
				//null = [1]ExecVM "Hint\uav.sqf";
				//RUBHUD = false;
				//RUBGPS = 0;
				null = [] ExecVM "Client\Module\UAV\uav.sqf";
			};
			case "UAV_Destroy": {
				if !(isNull playerUAV) then {
					{_x setDammage 1} forEach (crew playerUAV);
					//playerUAV setDammage 1;
					deleteVehicle playerUAV;
					playerUAV = objNull;
					hint "UAV \n (( Self Destroyed ))";
				};
			};
/*
			case "UAV_Remote_Control": {
				closeDialog 0;
				playsound "bitmenu";
				null = [1]ExecVM "Hint\uav.sqf";
				RUBHUD = false;
				RUBGPS = 0;
				null = [2]ExecVM "Client\Module\UAV\uav.sqf";
			};
*/
			case "Units_Camera": {
				closeDialog 0;
				createDialog "RscMenu_UnitCamera";
			};
		};
		
		_forceReload = true;
	};
	
	artyRange = floor (sliderPosition 17005);
	if (_lastRange != artyRange) then {_area setMarkerSizeLocal [artyRange,artyRange];};
	
	if (mouseButtonUp == 0) then {
		mouseButtonUp = -1;
		//--- Set Artillery Marker on map.
		if (Warfare_MenuAction == 1) then {
			Warfare_MenuAction = -1;
			artyPos = _map posScreenToWorld[mouseX,mouseY];
			_marker setMarkerPosLocal artyPos;
			_area setMarkerPosLocal artyPos;
			_requestRangedList = true;
		};
		//--- Paratroops.
		if (Warfare_MenuAction == 3) then {
			Warfare_MenuAction = -1;
			_forceReload = true;
			if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
			[17022] Call SetControlFadeAnimStop;
			_callPos = _map posScreenToWorld[mouseX,mouseY];
			if (!surfaceIsWater _callPos) then {
				lastParaCall = time;
				-(_currentFee) Call ChangePlayerFunds;
				WFBE_RequestSpecial = ['SRVFNCREQUESTSPECIAL',["Paratroops",sideJoined,_callPos,clientTeam]];
				publicVariable 'WFBE_RequestSpecial';
				if (isHostedServer) then {['SRVFNCREQUESTSPECIAL',["Paratroops",sideJoined,_callPos,clientTeam]] Spawn HandleSPVF};
				hint (localize "STR_WF_INFO_Paratroop_Info");
			};
		};
		//--- Fast Travel.
		if (Warfare_MenuAction == 7) then {
			Warfare_MenuAction = -1;
			_forceReload = true;
			if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
			[17022] Call SetControlFadeAnimStop;
			_callPos = _map PosScreenToWorld[mouseX,mouseY];
			_sorted = [_callPos,_FTLocations] Call SortByDistance;
			if (_callPos distance (_sorted select 0) < 500) then {
				closeDialog 0;
				deleteMarkerLocal _marker;
				deleteMarkerLocal _area;
				
				_destination = _sorted select 0;
				
				if (_ft == 2) then {
					_fee = round(((player distance _destination)/1000) * ('WFBE_FASTTRAVELPRICEKM' Call GetNamespace));
					-(_fee) Call ChangePlayerFunds;
				};
				
				_travelingWith = [];
				{if (_x distance _startPoint < _ftr && !(_x in _travelingWith) && canMove _x && !(vehicle _x isKindOf "StaticWeapon") && !stopped _x && !((currentCommand _x) in ["WAIT","STOP"])) then {_travelingWith = _travelingWith + [vehicle _x]}} forEach units (group player);
				
				ForceMap true;
				_compass = shownCompass;
				_GPS = shownGPS;
				_pad = shownPad;
				_radio = shownRadio;
				_watch = shownWatch;

				showCompass false;
				showGPS false;
				showPad false;
				showRadio false;
				showWatch false;

				mapAnimClear;
				mapAnimCommit;

				_locationPosition = getPos _destination;
				_camera = "camera" camCreate _locationPosition;
				_camera SetDir 0; //camsetdir
				_camera camSetFov 1;
				_camera cameraEffect["Internal","TOP"];

				_camera camSetTarget _locationPosition;
				_camera camSetPos [_locationPosition select 0,(_locationPosition select 1) + 2,100];
				_camera camCommit 0;
				
				mapAnimAdd [0,0.05,GetPos _startPoint];
				mapAnimCommit;
				
				_delay = ((_startPoint distance _destination) / 50) * ('WFBE_FASTTRAVELTIMECOEF' Call GetNamespace);
				mapAnimAdd [_delay,.18,getPos _destination];
				mapAnimCommit;
				
				waitUntil {mapAnimDone || !alive player};
				_skip = false;
				if (!alive player) then {_skip = true};
				if (!_skip) then {
					{[_x,_locationPosition,120] Call PlaceSafe} forEach _travelingWith;
				};
				sleep 1;
				
				ForceMap false;
				showCompass _compass;
				showGPS _GPS;
				showPad _pad;
				showRadio _radio;
				showWatch _watch;
				
				_camera cameraEffect["TERMINATE","BACK"];
				camDestroy _camera;
			};
		};
		//--- ICBM Strike.
		if (Warfare_MenuAction == 8) then {
			_forceReload = true;
			if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
			[17022] Call SetControlFadeAnimStop;
			Warfare_MenuAction = -1;
			-_currentFee Call ChangePlayerFunds;
			_callPos = _map PosScreenToWorld[mouseX,mouseY];
			
			_obj = "Land_HelipadEmpty_F" createVehicle _callPos;
			_nukeMarker = createMarkerLocal ["icbmstrike", _callPos];
			_nukeMarker setMarkerTypeLocal "mil_warning";
			_nukeMarker setMarkerTextLocal "Nuclear Strike";
			_nukeMarker setMarkerColorLocal "ColorRed";
			
			_nukeMarker2 = createMarker ["icbmstrike2", _callPos];
			_nukeMarker2 setMarkerShape "ELLIPSE";
			_nukeMarker2 setMarkerSize [2000,2000];
			[_obj,_nukeMarker,_nukeMarker2] Spawn NukeIncomming;
		};
		//--- Vehicle Paradrop.
		if (Warfare_MenuAction == 9) then {
			_forceReload = true;
			if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
			[17022] Call SetControlFadeAnimStop;
			Warfare_MenuAction = -1;
			lastSupplyCall = time;
			-_currentFee Call ChangePlayerFunds;
			_callPos = _map PosScreenToWorld[mouseX,mouseY];
			WFBE_RequestSpecial = ['SRVFNCREQUESTSPECIAL',["ParaVehi",sideJoined,_callPos,clientTeam]];
			publicVariable 'WFBE_RequestSpecial';
			if (isHostedServer) then {['SRVFNCREQUESTSPECIAL',["ParaVehi",sideJoined,_callPos,clientTeam]] Spawn HandleSPVF};
		};
		//--- Ammo Paradrop.
		if (Warfare_MenuAction == 10) then {
			_forceReload = true;
			if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
			[17022] Call SetControlFadeAnimStop;
			Warfare_MenuAction = -1;
			lastSupplyCall = time;
			-_currentFee Call ChangePlayerFunds;
			_callPos = _map PosScreenToWorld[mouseX,mouseY];
			WFBE_RequestSpecial = ['SRVFNCREQUESTSPECIAL',["ParaAmmo",sideJoined,_callPos,clientTeam]];
			publicVariable 'WFBE_RequestSpecial';
			if (isHostedServer) then {['SRVFNCREQUESTSPECIAL',["ParaAmmo",sideJoined,_callPos,clientTeam]] Spawn HandleSPVF};
		};
	};
	
	//--- Update the Artillery Status.
	if (paramArty) then {
		_fireTime = (Format["WFBE_FIREMISSIONTIMEOUT%1",(_currentUpgrades select 10)] Call GetNamespace);
		_status = round(_fireTime - (time - fireMissionTime));
		_txt = if (time - fireMissionTime > _fireTime) then {Format['<t align="left" color="#73FF47">%1</t>',localize 'STR_WF_TACTICAL_Available']} else {Format ['<t align="left" color="#4782FF">%1 %2</t>',_status,localize 'STR_WF_Seconds']};
		(_display displayCtrl 17016) ctrlSetStructuredText (parseText _txt);
		_enable = if (_status > 0) then {false} else {true};
		if (WF_Debug) then {_enable = true};
		ctrlEnable [17007,_enable];
	};

	_artygroup = Group player;

	if (leader commanderTeam == player) then {
	_artyarray = format ['WFBE_%1_ARTILLERY_NAMES',side player] call GetNamespace;
	_artynames = [];
	{_artynames = _artynames + _x} forEach _artyarray select 1;
		{
		if ((leader _x != player) AND (side leader _x == side leader commanderTeam)) then {
			{if (typeOf vehicle (vehicle _x) in _artynames) then {_artygroup = _x}} forEach units _x;
		};
		} forEach allGroups;

		{if (typeOf vehicle (vehicle _x) in _artynames) then {_artygroup = Group player}} forEach units group player;
	};
	
	//--- Request Fire Mission.
	if (Warfare_MenuAction == 2) then {
		Warfare_MenuAction = -1;
		_units = [_artygroup,false,lbCurSel(17008),sideJoinedText] Call GetTeamArtillery;
		if (Count _units > 0) then {
			fireMissionTime = time;
			[GetMarkerPos "artilleryMarker",lbCurSel(17008),_artygroup] Spawn RequestFireMission;
		} else {
			hint (localize "STR_WF_INFO_NoArty");
		};			
	};
	
	//--- Arty Combo Change or Script init.
	if (Warfare_MenuAction == 200 || _startLoad) then {
		Warfare_MenuAction = -1;
		
		_index = lbCurSel(17008);
		_minRange = (Format ["WFBE_%1_ARTILLERY_MINRANGES",sideJoined] Call GetNamespace) select _index;
		_maxRange = (Format ["WFBE_%1_ARTILLERY_MAXRANGES",sideJoined] Call GetNamespace) select _index;

		_trackingArray = [_artygroup,true,lbCurSel(17008),sideJoined] Call GetTeamArtillery;
		
		_requestMarkerTransition = true;
		_requestRangedList = true;
		_startLoad = false;
	};
	
	//--- Focus on an artillery cannon.
	if (Warfare_MenuAction == 60) then {
		Warfare_MenuAction = -1;
		
		ctrlMapAnimClear _map;
		_map ctrlMapAnimAdd [1,.475,getPos(_trackingArray select (lnbCurSelRow 17024))];
		ctrlMapAnimCommit _map;
	};
	
	//--- Flush on change.
	if (_requestMarkerTransition) then {
		_requestMarkerTransition = false;
		
		{
			_track = (_x select 0);
			_vehicle = (_x select 1);

			_vehicle setVariable ['WFBE_A_Tracked', nil];
			deleteMarkerLocal Format ["WFBE_A_Large%1",_track];
			deleteMarkerLocal Format ["WFBE_A_Small%1",_track];
		} forEach _trackingArrayID;
		_trackingArrayID = [];
	};
	
	//--- Artillery List.
	if (paramArty && (_requestRangedList || time - _lastArtyUpdate > 3)) then {
		_requestRangedList = false;
		
		//--- No need to update the list all the time.
		if (time - _lastArtyUpdate > 5) then {
			_lastArtyUpdate = time;
			_trackingArray = [_artygroup,true,lbCurSel(17008),sideJoined] Call GetTeamArtillery;
		};
		
		//--- Clear & Fill;
		lnbClear 17024;
		_i = 0;
		{
			_distance = _x distance (getMarkerPos _marker);
			_color = [0, 0.875, 0, 0.8];
			_text = localize 'STR_WF_TACTICAL_ArtilleryInRange'; 																		//---changed-MrNiceGuy //"In Range";
			if (_distance > _maxRange) then {_color = [0.875, 0, 0, 0.8];_text = localize 'STR_WF_TACTICAL_ArtilleryOutOfRange'}; 		 //---changed-MrNiceGuy //"Out of Range"};
			if (_distance <= _minRange) then {_color = [0.875, 0.5, 0, 0.8];_text = localize 'STR_WF_TACTICAL_ArtilleryRangeTooClose'}; //---changed-MrNiceGuy //"Too close"};
			lnbAddRow [17024,[[typeOf _x, 'displayName'] Call GetConfigInfo,_text]];
			lnbSetPicture [17024,[_i,0],[typeOf _x, 'picture'] Call GetConfigInfo];
			
			lnbSetColor [17024,[_i,0],_color];
			lnbSetColor [17024,[_i,1],_color];
			
			_i = _i + 1;
		} forEach _trackingArray;
	};
	
	//--- Artillery map toggle.
	if (Warfare_MenuAction == 40) then {
		Warfare_MenuAction = -1;
		if (_mode == -1) then {_mode = 0};
		_mode = if (_mode == 2) then {0} else {_mode + 1};
		with uinamespace do {
			switch (_mode) do {
				case 0: {(currentBEDialog displayCtrl 17023) ctrlSetTextColor [1,1,1,1]};
				case 1: {(currentBEDialog displayCtrl 17023) ctrlSetTextColor [0,0.635294,0.909803,1]};
				case 2: {(currentBEDialog displayCtrl 17023) ctrlSetTextColor [0.6,0.850980,0.917647,1]};
			};
		};
		
		if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};
		_textAnimHandler = [17022,localize 'STR_WF_TACTICAL_ArtilleryMinimapInfo',7,"ff9900"] spawn SetControlFadeAnim;
		
		['WFBE_V_ARTILLERYMINMAP',_mode,true] Call SetNamespace;
		
		_requestMarkerTransition = true;
	};
	
	//--- Update artillery display.
	if (_mode != -1) then {
	
		//--- Nothing.
		if (_mode == 0) then {
			_requestMarkerTransition = true;
			_mode = -1;
		};
			
		//--- Filled Content.
		if (_mode == 1 || _mode == 2) then {
			//--- Remove if dead or null or sel changed.
			{
				_track = (_x select 0);
				_vehicle = (_x select 1);
				
				if !(alive _vehicle) then {
					deleteMarkerLocal Format ["WFBE_A_Large%1",_track];
					deleteMarkerLocal Format ["WFBE_A_Small%1",_track];
				};
			} forEach _trackingArrayID;
			
			//--- No need to update the marker all the time.
			if (time - _lastArtyUpdate > 5) then {
				_lastArtyUpdate = time;
				_trackingArray = [_artygroup,true,lbCurSel(17008),sideJoined] Call GetTeamArtillery;
			};
			
			//--- Live Feed.
			_trackingArrayID = [];
			{
				_track = _x getVariable 'WFBE_A_Tracked';
				if (isNil '_track') then {
					_track = buildingMarker;
					buildingMarker = buildingMarker + 1;
					_x setVariable ['WFBE_A_Tracked', _track];
					_dmarker = Format ["WFBE_A_Large%1",_track];
					createMarkerLocal [_dmarker, getPos _x];
					_dmarker setMarkerColorLocal "ColorBlue";
					_dmarker setMarkerShapeLocal "ELLIPSE";
					_brush = "SOLID";
					if (_mode == 1) then {_brush = "SOLID"};
					if (_mode == 2) then {_brush = "BORDER"};
					_dmarker setMarkerBrushLocal _brush;
					_dmarker setMarkerAlphaLocal 0.4;
					_dmarker setMarkerSizeLocal [_maxRange,_maxRange];
					_dmarker = Format ["WFBE_A_Small%1",_track];
					createMarkerLocal [_dmarker, getPos _x];
					_dmarker setMarkerColorLocal "ColorBlack";
					_dmarker setMarkerShapeLocal "ELLIPSE";
					_dmarker setMarkerBrushLocal "SOLID";
					_dmarker setMarkerAlphaLocal 0.4;
					_dmarker setMarkerSizeLocal [_minRange,_minRange];
				} else {
					_dmarker = Format ["WFBE_A_Large%1",_track];
					_dmarker setMarkerPosLocal (getPos _x);
					_dmarker = Format ["WFBE_A_Small%1",_track];
					_dmarker setMarkerPosLocal (getPos _x);
				};
				_trackingArrayID = _trackingArrayID + [[_track,_x]];
			} forEach _trackingArray;
		};
	};
	
	_lastRange = artyRange;
	_lastSel = lbCurSel(_listbox);
	sleep 0.1;
	
	//--- Back Button.
	if (Warfare_MenuAction == 30) exitWith { //---added-MrNiceGuy
		Warfare_MenuAction = -1;
		closeDialog 0;
		createDialog "WF_Menu";
	};
};

deleteMarkerLocal _marker;
deleteMarkerLocal _area;
{deleteMarkerLocal _x} forEach _markers;

if !(scriptDone _textAnimHandler) then {terminate _textAnimHandler};

//--- Remove Markers.
{
	_track = (_x select 0);
	_vehicle = (_x select 1);
	
	_vehicle setVariable ['WFBE_A_Tracked', nil];

	deleteMarkerLocal Format ["WFBE_A_Large%1",_track];
	deleteMarkerLocal Format ["WFBE_A_Small%1",_track];
} forEach _trackingArrayID;
if (isNil "markPos") then {markPos = true;} else {markPos = !markPos};
if(markPos) then {titleText ["Markierungen wurden auf der Karte hinzugefügt...","PLAIN DOWN"]; titleFadeOut 10;};
if(isNil "markers") then { markers = []};
while {markPos} do
{ 
if(!markPos) then
titleText ["Markierung wurden wieder von der Karte entfernt...","PLAIN DOWN"]; titleFadeOut 10;
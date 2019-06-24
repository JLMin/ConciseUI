-- ===========================================================================
-- Cui In Game Note Button
-- eudaimonia, 2/10/2019
-- ===========================================================================

local isAttached = false;

-- ===========================================================================
function OnToggleNoteScreen()
  LuaEvents.Cui_ToggleNoteScreen();
end

-- ===========================================================================
function AttachToTopPanel()
  if not isAttached then
    local infoStack = ContextPtr:LookUpControl( "/InGame/TopPanel/InfoStack" );
    Controls.CuiNoteContainer:ChangeParent(infoStack);
    infoStack:CalculateSize();
    infoStack:ReprocessAnchoring();    
    isAttached = true;
  end
end

-- ===========================================================================
function Initialize()
  ContextPtr:SetHide( true );
  Events.LoadGameViewStateDone.Add(AttachToTopPanel);
  Controls.CuiViewNotes:RegisterCallback( Mouse.eLClick, OnToggleNoteScreen );
  Controls.CuiViewNotes:RegisterCallback( Mouse.eMouseEnter,function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
end
Initialize();
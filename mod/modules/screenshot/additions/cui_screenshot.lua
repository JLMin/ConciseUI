-- ===========================================================================
-- Cui Screenshot
-- eudaimonia, 2/10/2019
-- ===========================================================================
local isAttached = false

local isEnterMode = false
local isAltDown = false
local isMouseDown = false
local startX = 0
local startY = 0
local deltaX = 0
local deltaY = 0
local currentX = 0
local currentY = 0

local UIStatus = {}
local ScreenshotMode = {
    FULLY_HIDE = {
        "/InGame/WorldViewControls", --
        "/InGame/HUD", "/InGame/PartialScreens", "/InGame/Screens",
        "/InGame/TopLevelHUD", "/InGame/WorldPopups", "/InGame/Civilopedia"
    },
    KEEP_CITY = {
        "/InGame/WorldViewIconsManager", "/InGame/DistrictPlotIconManager",
        "/InGame/PlotInfo", "/InGame/UnitFlagManager",
        "/InGame/TourismBannerManager", "/InGame/MapPinManager",
        "/InGame/SelectedUnit", "/InGame/SelectedMapPinContainer",
        "/InGame/SelectedUnitContainer", "/InGame/WorldViewPlotMessages", --
        "/InGame/HUD", "/InGame/PartialScreens", "/InGame/Screens",
        "/InGame/TopLevelHUD", "/InGame/WorldPopups", "/InGame/Civilopedia"
    }
}

local ScreenshotInputHandler = {}

-- ===========================================================================
ScreenshotInputHandler[KeyEvents.KeyDown] =
    function(uiKey)
        if uiKey == Keys.VK_ALT then
            isAltDown = true
            return true
        end
        return false
    end

-- ===========================================================================
ScreenshotInputHandler[KeyEvents.KeyUp] =
    function(uiKey)
        if uiKey == Keys.VK_ALT then
            isAltDown = false
            currentX = currentX + deltaX
            currentY = currentY + deltaY
            deltaX, deltaY = 0, 0
            return true
        end
        if uiKey == Keys.VK_ESCAPE then
            ExitScreenshotMode()
            return true
        end
        return false
    end

-- ===========================================================================
ScreenshotInputHandler[MouseEvents.LButtonDown] =
    function(uiKey)
        isMouseDown = true
        if isAltDown then
            startX, startY = UIManager:GetNormalizedMousePos()
        end
        return true
    end

-- ===========================================================================
ScreenshotInputHandler[MouseEvents.LButtonUp] =
    function(uiKey)
        isMouseDown = false
        currentX = currentX + deltaX
        currentY = currentY + deltaY
        deltaX, deltaY = 0, 0
        return true
    end

-- ===========================================================================
ScreenshotInputHandler[MouseEvents.RButtonDown] =
    function(uiKey) return true end

-- ===========================================================================
ScreenshotInputHandler[MouseEvents.RButtonUp] = function(uiKey) return true end

-- ===========================================================================
ScreenshotInputHandler[MouseEvents.MouseMove] =
    function(uiKey)
        if isAltDown and isMouseDown then
            local newX, newY = UIManager:GetNormalizedMousePos()
            deltaX = startX - newX
            deltaY = startY - newY
            UI.SpinMap(currentX + deltaX, currentY + deltaY)
            return true
        end
        return false
    end

-- ===========================================================================
function EnterScreenshotMode(mode)
    UIStatus = {}
    for i, sName in ipairs(mode) do
        UIStatus[sName] = ContextPtr:LookUpControl(sName):IsHidden()
        ContextPtr:LookUpControl(sName):SetHide(true)
    end
    isEnterMode = true
    UI.DeselectAllUnits()
end

-- ===========================================================================
function ExitScreenshotMode()
    for sName, bHidden in pairs(UIStatus) do
        ContextPtr:LookUpControl(sName):SetHide(bHidden)
    end
    UIStatus = {}
    if isEnterMode then
        isEnterMode = false
        isAltDown = false
        isMouseDown = false
        startX = 0
        startY = 0
        deltaX = 0
        deltaY = 0
        currentX = 0
        currentY = 0
        UI.SpinMap(0, 0)
    end
end

-- ===========================================================================
function OnInputHandler(pInputStruct)
    local uiMsg = pInputStruct:GetMessageType()
    if isEnterMode and ScreenshotInputHandler[uiMsg] then
        local uiKey = pInputStruct:GetKey()
        return ScreenshotInputHandler[uiMsg](uiKey)
    end
    return false
end

-- ===========================================================================
function AttachToMinimap()
    if not isAttached then
        local topPanelRight = ContextPtr:LookUpControl(
                                  "/InGame/TopPanel/RightContents")
        Controls.ScreenshotButton:ChangeParent(topPanelRight)
        topPanelRight:AddChildAtIndex(Controls.ScreenshotButton, 2)
        topPanelRight:CalculateSize()
        topPanelRight:ReprocessAnchoring()
        isAttached = true
    end
end

-- ===========================================================================
function Initialize()
    ContextPtr:SetHide(false)
    ContextPtr:SetInputHandler(OnInputHandler, true)
    Events.LoadGameViewStateDone.Add(AttachToMinimap)
    Controls.ScreenshotButton:RegisterCallback(Mouse.eLClick, function()
        EnterScreenshotMode(ScreenshotMode.FULLY_HIDE)
    end)
    Controls.ScreenshotButton:RegisterCallback(Mouse.eRClick, function()
        EnterScreenshotMode(ScreenshotMode.KEEP_CITY)
        UI.PlaySound("Play_UI_Click")
    end)
end
Initialize()

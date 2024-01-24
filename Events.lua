local _, Private = ...
local LRS = Private.Addon

function LRS:ShowRolls(_, rollID)
    self:GetRollFrame(rollID)
end

function LRS:SentRoll(rollID)
    local frame = self.IDtoFrame[rollID]
    if frame and frame.rollID ~= 0 then
        frame:Hide()
        frame.used = false
    end
end
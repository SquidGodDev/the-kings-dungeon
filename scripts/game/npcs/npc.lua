local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Npc').extends(gfx.sprite)

function Npc:init(x, y, entity)
    local fields = entity.fields
    local npcName = fields.name
    local npcImage = gfx.image.new("images/npcs/"..npcName)
    self.dialogue = fields.dialogue
    self.playerStart = fields.playerStart
    local flip = gfx.kImageUnflipped
    if not fields.facingRight then
        flip = gfx.kImageFlippedX
    end
    self:setImage(npcImage, flip)
    if fields.facingRight then
        self:setCollideRect(16, 0, 32, 32)
    else
        self:setCollideRect(-16, 0, 32, 32)
    end
    self:setTag(TAGS.Interactable)
    self:setZIndex(Z_INDEXES.NPC)
    self:setCenter(0, 0)
    local yOffset = -4
    if npcName == "King" then
        yOffset = -16
    end
    self:moveTo(x, y + yOffset)
    self:add()
    self.interactable = true
end

function Npc:interact(player)
    DialogueManager(self.dialogue, self.playerStart, player, self)
end
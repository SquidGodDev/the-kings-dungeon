local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Npc').extends(gfx.sprite)

function Npc:init(x, y, entity)
    local fields = entity.fields
    local npcName = fields.name
    local npcImage = gfx.image.new("images/npcs/"..npcName)
    self.dialogue = fields.dialogue
    local flip = gfx.kImageUnflipped
    if not fields.facingRight then
        flip = gfx.kImageFlippedX
    end
    self:setImage(npcImage, flip)
    if fields.facingRight then
        self:setCollideRect(32, 0, 32, 32)
    else
        self:setCollideRect(-32, 0, 32, 32)
    end
    self:setTag(TAGS.Interactable)
    self:setZIndex(Z_INDEXES.NPC)
    self:setCenter(0, 0)
    self:moveTo(x, y - 4)
    self:add()
    self.interactable = true
end

function Npc:interact(player)
    DialogueManager(self.dialogue, player, self)
    -- self.interactable = false
end
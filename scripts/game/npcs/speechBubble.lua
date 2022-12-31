local pd <const> = playdate
local gfx <const> = playdate.graphics

local speechFont <const> = gfx.font.new("images/fonts/m5x7-24")

class('SpeechBubble').extends(gfx.sprite)

function SpeechBubble:init(text, x, y)
    self.maxLineWidth = 16
    self.fontWidth = 14
    self.maxWidth = self.maxLineWidth * self.fontWidth
    -- local halfWidth = self.maxWidth / 2
    -- local screenEdgeBuffer = 10
    -- if x <= (halfWidth + screenEdgeBuffer) then
    --     x = halfWidth + screenEdgeBuffer
    -- elseif x >= (400 - halfWidth - screenEdgeBuffer) then
    --     x = 400 - halfWidth - screenEdgeBuffer
    -- end

    self.border = 3
    self.edgeBuffer = 10

    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.UI)
    self:add()

    self.active = true
    self.speechTime = 30
    self.pauseSpeechTime = 300

    self.lineArray = {}
    local curLineWidth = 0
    local curString = ""
    for w in text:gmatch("%S+ *") do
        curLineWidth += #w
        if curLineWidth > self.maxLineWidth then
            table.insert(self.lineArray, curString:sub(1,curLineWidth))
            curLineWidth = #w
            curString = w
        else
            curString = curString .. w
        end
    end
    table.insert(self.lineArray, curString:sub(1,curLineWidth))

    self.lineIndex = 1
    self.numOfLines = #self.lineArray
    self.lineHeight = speechFont:getHeight()

    self.downArrowImage = gfx.image.new("images/ui/downArrow")
    self.downArrowWidth, self.downArrowHeight = self.downArrowImage:getSize()

    self:createSpeechTimer()
end

function SpeechBubble:advance()
    if self.speechTimer then
        self.speechTimer:remove()
        self:drawText(self.curLine, self.lineWidth, self.lineHeight)
        self.speechTimer = nil
        return true
    else
        self.lineIndex += 1
        if self.lineIndex > self.numOfLines then
            self:remove()
            return false
        else
            self:createSpeechTimer()
            return true
        end
    end
end

function SpeechBubble:createSpeechTimer()
    self.curLine = self.lineArray[self.lineIndex]
    self.lineWidth = speechFont:getTextWidth(self.curLine)
    self.textIndex = 0
    self.maxTextIndex = #self.curLine
    self.speechTimer = pd.timer.new(self.speechTime, function(timer)
        self.speechTimer.delay = self.speechTime
        local nextChar = string.sub(self.curLine, self.textIndex + 1, self.textIndex + 1)
        if nextChar and nextChar == "." then
            self.speechTimer.delay = self.pauseSpeechTime
        end
        self.textIndex += 1
        self:drawText(string.sub(self.curLine, 1, self.textIndex), self.lineWidth, self.lineHeight)
        if self.textIndex == self.maxTextIndex then
            timer:remove()
            self.speechTimer = nil
        end
    end)
    self.speechTimer.repeats = true
end

function SpeechBubble:drawText(text, width, height)
    local speechBubbleWidth = width + self.edgeBuffer * 2
    local speechBubbleHeight = height + self.edgeBuffer * 2
    local speechBubble = gfx.image.new(speechBubbleWidth, speechBubbleHeight + self.downArrowHeight)
    gfx.pushContext(speechBubble)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, speechBubbleWidth, speechBubbleHeight)
        self.downArrowImage:draw(speechBubbleWidth/2 - self.downArrowWidth/2, speechBubbleHeight)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        speechFont:drawText(text, self.edgeBuffer, self.edgeBuffer)
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(self.border)
        gfx.setStrokeLocation(gfx.kStrokeInside)
        gfx.drawRect(0, 0, speechBubbleWidth, speechBubbleHeight)
    gfx.popContext()
    self:setImage(speechBubble)
end
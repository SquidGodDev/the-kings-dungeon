local pd <const> = playdate
local gfx <const> = playdate.graphics

local m5x7FontOutline <const> = gfx.font.new("images/fonts/m5x7-24-outline-tight")

class('SpeechBubble').extends(gfx.sprite)

function SpeechBubble:init(text, x, y)
    self.maxLineWidth = 20
    self.fontWidth = 14
    self.maxWidth = self.maxLineWidth * self.fontWidth
    local halfWidth = self.maxWidth / 2
    local screenEdgeBuffer = 10
    if x <= (halfWidth + screenEdgeBuffer) then
        x = halfWidth + screenEdgeBuffer
    elseif x >= (400 - halfWidth - screenEdgeBuffer) then
        x = 400 - halfWidth - screenEdgeBuffer
    end

    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.UI)
    self:add()

    self.active = true
    self.speechTime = 50
    self.pauseSpeechTime = 300

    self.lineArray = {}
    local curLineWidth = 0
    local curString = ""
    for w in text:gmatch("%S+ *") do
        curLineWidth += #w
        if curLineWidth > self.maxLineWidth then
            table.insert(self.lineArray, curString)
            curLineWidth = #w
            curString = w
        else
            curString = curString .. w
        end
    end
    table.insert(self.lineArray, curString)

    self.lineIndex = 1
    self.numOfLines = #self.lineArray
    self.lineHeight = m5x7FontOutline:getHeight()

    self:createSpeechTimer()
end

function SpeechBubble:update()
    if pd.buttonJustPressed(playdate.kButtonA) then
        if self.speechTimer then
            self.speechTimer:remove()
            self:drawText(self.curLine, self.lineWidth, self.lineHeight)
            self.speechTimer = nil
        else
            self.lineIndex += 1
            if self.lineIndex > self.numOfLines then
                self.active = false
                self:remove()
            else
                self:createSpeechTimer()
            end
        end
    end
end

function SpeechBubble:createSpeechTimer()
    self.curLine = self.lineArray[self.lineIndex]
    self.lineWidth = m5x7FontOutline:getTextWidth(self.curLine)
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
    local speechBubble = gfx.image.new(width, height)
    gfx.pushContext(speechBubble)
        m5x7FontOutline:drawText(text, 0, 0)
    gfx.popContext()
    self:setImage(speechBubble)
end
local trimWhitespace = playdate.string.trimWhitespace
local trimTrailingWhitespace = playdate.string.trimTrailingWhitespace

local function _styleCharacterForNewline(line)
	local _, boldCount = string.gsub(line, "*", "*")
	if ( boldCount % 2 ~= 0 ) then
		return "*"
	end
	
	local _, italicCount = string.gsub(line, "_", "_")
	if ( italicCount % 2 ~= 0 ) then
		return "_"
	end

	return ""
end

local function _addStyleToLine(style, line)
	if #style == 0 then
		return line
	elseif line:sub(1,1) == style then
		return line:sub(2,-1)
	else
		return style .. line
	end
end

function drawTextInRect(str, index, x, ...)
	if str == nil then return 0, 0 end
	
	local y, width, height, lineHeightAdjustment, truncator, textAlignment, singleFont
	if (type(x) == "userdata") then		-- check if x is a playdate.geometry.rect object
		x, y, width, height = x.x, x.y, x.width, x.height
		lineHeightAdjustment, truncator, textAlignment = select(1, ...)
	else
		y, width, height, lineHeightAdjustment, truncator, textAlignment, singleFont = select(1, ...)
	end
	
	if width < 0 or height < 0 then
		return 0, 0, false
	end
	
	local font = nil
	if singleFont == nil then 
		font = g.getFont()
		if font == nil then print('error: no font set!') return 0, 0, false end
	end
	
	y = math.floor(y)
	x = math.floor(x)
	lineHeightAdjustment = math.floor(lineHeightAdjustment or 0)
	if truncator == nil then truncator = "" end
	
	local top = y
	local bottom = y + height
	local currentLine = ""
	local lineWidth = 0
	local firstWord = true

	local lineHeight
	local fontLeading
	local fontHeight
	if singleFont == nil then 
		fontLeading = font:getLeading()
		fontHeight = font:getHeight()
		lineHeight = fontHeight + fontLeading
	else
		fontLeading = singleFont:getLeading()
		fontHeight = singleFont:getHeight()
		lineHeight = fontHeight + fontLeading
	end
	-- local unmodifiedLineHeight = lineHeight
	
	local maxLineWidth = 0
	
	if height < fontHeight then
		return 0, 0, false	-- if the rect is shorter than the text, don't draw anything
	else
		lineHeight += lineHeightAdjustment
	end
	
	local function getLineWidth(text)
		if singleFont == nil then
			return g.getTextSize(text)		
		else
			return singleFont:getTextWidth(text)
		end
	end
	
	local function drawAlignedText(t, twidth, colorSwitchIndex)
		
		if twidth > maxLineWidth then
			maxLineWidth = twidth
		end
		
		local alignedX = x
		if textAlignment == kTextAlignment.right then
			alignedX = x + width - twidth
		elseif textAlignment == kTextAlignment.center then
			alignedX = x + ((width - twidth) / 2)
		end

        if colorSwitchIndex then
            local drawTextWidth = (colorSwitchIndex / #t) * twidth
            local drawText = string.sub(t, 1, colorSwitchIndex)
            local hiddenText = string.sub(t, colorSwitchIndex + 1)
            if singleFont == nil then
                g.drawText(drawText, alignedX, y)
                playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
                g.drawText(hiddenText, alignedX + drawTextWidth, y)
            else
                singleFont:drawText(drawText, alignedX, y)
                playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
                singleFont:drawText(hiddenText, alignedX + drawTextWidth, y)
            end
        else
            if singleFont == nil then
                g.drawText(t, alignedX, y)
            else
                singleFont:drawText(t, alignedX, y)
            end
        end
	end
	
	
	local function drawTruncatedWord(wordLine)
		lineWidth = getLineWidth(wordLine)
		local truncatedWord = wordLine
		local stylePrefix = _styleCharacterForNewline(truncatedWord)
		
		while lineWidth > width and #truncatedWord > 1 do	-- shorten word until truncator fits
			truncatedWord = truncatedWord:sub(1, -2)		-- remove last character, and try again
			lineWidth = getLineWidth(truncatedWord)
		end

		drawAlignedText(truncatedWord, lineWidth)
	
		local remainingWord = _addStyleToLine(stylePrefix, wordLine:sub(#truncatedWord+1, -1))
		lineWidth = getLineWidth(remainingWord)
		firstWord = true
		return remainingWord
	end
	
	
	local function drawTruncatedLine()
		currentLine = trimTrailingWhitespace(currentLine)	-- trim whitespace at the end of the line
		lineWidth = getLineWidth(currentLine .. truncator)
		
		while lineWidth > width and getLineWidth(currentLine) > 0 do	-- shorten line until truncator fits
			currentLine = currentLine:sub(1, -2)	-- remove last character, and try again
			lineWidth = getLineWidth(currentLine .. truncator)
		end
		
		currentLine = currentLine .. truncator
		lineWidth = getLineWidth(currentLine)
		firstWord = true

		drawAlignedText(currentLine, lineWidth)
		
		local textBlockHeight = y - top + fontHeight
		return maxLineWidth, textBlockHeight, true
	end
	
	
	local function drawLineAndMoveToNext(firstWordOfNextLine, colorSwitchIndex)
		firstWordOfNextLine = _addStyleToLine(_styleCharacterForNewline(currentLine), firstWordOfNextLine)
		drawAlignedText(currentLine, lineWidth, colorSwitchIndex)
		y += lineHeight
		currentLine = firstWordOfNextLine
		lineWidth = getLineWidth(firstWordOfNextLine)
		firstWord = true
	end
	
	
	local lines = {}
	local i = 1
	for line in str:gmatch("[^\r\n]*") do		-- split into hard-coded lines
		lines[i] = line
		i += 1
	end
	
	local line
	
	for i = 1, #lines do
		line  = lines[i]
		
		local firstWordInLine = true
		local leadingWhiteSpace = ""
		
        local curIndex = 0
        local colorSwitched = false
		for word in line:gmatch("%S+ *") do	-- split into words
            -- print("Word: " .. word)
            -- print("Cur Index: " .. curIndex)
            -- print("Index: " .. index)
			-- preserve leading space on lines
			if firstWordInLine == true then
				local leadingSpace = line:match("^%s+")
				if leadingSpace ~= nil then
					leadingWhiteSpace = leadingSpace
				end
				firstWordInLine = false
			else
				leadingWhiteSpace = ""
			end

			-- split individual words into pieces if they're too wide
			if firstWord then
				if #currentLine > 0 then
					while getLineWidth(leadingWhiteSpace..currentLine) > width do
						currentLine = drawTruncatedWord(leadingWhiteSpace..currentLine)
						y += lineHeight
					end
				else
					word = leadingWhiteSpace .. word
					while getLineWidth(word) > width do
						if y + fontHeight <= bottom then
							if y + lineHeight + fontHeight <= bottom then
								word = drawTruncatedWord(leadingWhiteSpace .. word)
							else 	-- a line after this one will not fit
								currentLine = word
								return drawTruncatedLine() -- no room for another line
							end
							leadingWhiteSpace = ""
						end
						y += lineHeight
					end
				end
				firstWord = false
			end
			
			if getLineWidth(currentLine .. leadingWhiteSpace .. trimWhitespace(word)) <= width then
				currentLine = currentLine .. leadingWhiteSpace .. word
			else
				if y + lineHeight + fontHeight <= bottom then
					currentLine = leadingWhiteSpace .. trimTrailingWhitespace(currentLine)	-- trim whitespace at the end of the line
					lineWidth = getLineWidth(currentLine)
                    local drawLine = leadingWhiteSpace .. word
                    local colorSwitchIndex = nil
                    print(drawLine)
                    if not colorSwitched then
                        curIndex += #drawLine
                        -- print("Cur Line: " .. drawLine)
                        -- print("Cur Index: " .. curIndex)
                        -- print("Cur Index - index" .. curIndex - index)
                        if curIndex > index then
                            colorSwitched = true
                            colorSwitchIndex = math.abs(index-curIndex)
                        end
                    end
					drawLineAndMoveToNext(leadingWhiteSpace .. word, colorSwitchIndex)
				else
					-- the next line is lower than the boundary, so we need to truncate and stop drawing
					currentLine = leadingWhiteSpace ..currentLine .. word
					if y + fontHeight <= bottom then
						return drawTruncatedLine()
					end
					local textBlockHeight = y - top + fontHeight
					return maxLineWidth, textBlockHeight, true
				end
			end
			
		end
		
		if (lines[i+1] == nil) or (y + lineHeight + fontHeight <= bottom) then
			
			if #currentLine > 0 then
				while getLineWidth(currentLine) > width do
					currentLine = drawTruncatedWord(currentLine)
					y += lineHeight
				end
			end
			
			lineWidth = getLineWidth(currentLine)
			drawLineAndMoveToNext('')
		else
			return drawTruncatedLine()
		end
	end
	
	local textBlockHeight = y - top - lineHeight + fontHeight
	return maxLineWidth, textBlockHeight, false
end

local pd <const> = playdate
local gfx <const>  = playdate.graphics

class('Menu').extends(gfx.sprite)

function Menu:init(menuX, menuY)
    if ACTIVE_SAVE then
        self.elements = {"Continue", "New Game (World 1)", "New Game (World 2)"}
    else
        self.elements = {"New Game (World 1)", "New Game (World 2)"}
    end

    self.menuItemWidth = 120
    self.menuItemHeight = 40
    self.menuItemSpacing = 5
    self.menuFont = gfx.font.new("images/fonts/m5x7-12")

    local gridview <const> = pd.ui.gridview.new(self.menuItemWidth, self.menuItemHeight)
    gridview:setNumberOfColumns(#self.elements)
    gridview:setNumberOfRows(1)
    gridview:setCellPadding(self.menuItemSpacing, self.menuItemSpacing, 0, 0)
    local gridviewMetatable <const> = getmetatable(gridview)
    gridviewMetatable.elements = self.elements
    gridviewMetatable.menuFont = self.menuFont

    function gridview:drawCell(section, row, column, selected, x, y, width, height)
        gfx.pushContext()
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(x, y, width, height)
            if selected then
                gfx.setColor(gfx.kColorWhite)
                gfx.setStrokeLocation(gfx.kStrokeInside)
                gfx.setLineWidth(4)
            end
            gfx.drawRect(x, y, width, height)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            local fontHeight = self.menuFont:getHeight()
            self.menuFont:drawTextAligned(self.elements[column], x + width / 2, (height - fontHeight)/2, kTextAlignment.center)
        gfx.popContext()
    end

    self.gridview = gridview

    self:moveTo(menuX, menuY)
    self:add()

    self.active = false
end

function Menu:update()
    if self.active then
        if pd.buttonJustPressed(pd.kButtonLeft) then
            self.gridview:selectPreviousColumn(true)
        elseif pd.buttonJustPressed(pd.kButtonRight) then
            self.gridview:selectNextColumn(true)
        end

        if pd.buttonJustPressed(pd.kButtonA) then
            local _, _, selectedColumn = self.gridview:getSelection()
            if #self.elements == 3 then
                if selectedColumn == 1 then
                    SCENE_MANAGER:switchScene(GameScene, nil, CUR_LEVEL, CUR_X, CUR_Y, ABILITIES, LEVELS)
                elseif selectedColumn == 2 then
                    SCENE_MANAGER:switchScene(GameScene, 1)
                else
                    SCENE_MANAGER:switchScene(GameScene, 2)
                end
            else
                SCENE_MANAGER:switchScene(GameScene, selectedColumn)
            end
        end
    end

    if self.gridview.needsDisplay then
        local gridWidth = #self.elements * (self.menuItemWidth + 2 * self.menuItemSpacing)
        local gridHeight = self.menuItemHeight
        local gridviewImage = gfx.image.new(gridWidth, gridHeight)
        gfx.pushContext(gridviewImage)
            self.gridview:drawInRect(0, 0, gridWidth, gridHeight)
        gfx.popContext()
        self:setImage(gridviewImage)
    end
end
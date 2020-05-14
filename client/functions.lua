function SpriteAtWorldCoord(x, y, z, f, s, size)
    local w, h = GetScreenResolution()
    local wScale = h / w * 0.75
    local os, sx, sy = GetScreenCoordFromWorldCoord(x, y ,z)
    if (sx > 0 and sx < 1) or (sy > 0 and sy < 1) then
        local onScreen,_x,_y = GetHudScreenPositionFromWorldPosition(x, y, z)
        DrawSprite(f, s, _x, _y + 0.0125, size * wScale, size, 0.0, 255, 255, 255, 190, 0)
    end
end


-- task_animal_interaction
-- Horse
--  -224471938 -- Feed
--  1968415774 -- Brush / Clean
--   554992710 -- Brush / Clean Loop ?
--   391681984 -- Pat ?
--  2042508059 -- Pat ?
-- -1897367196 -- Pat Loop ?
-- -1355254781 -- Stim Shot
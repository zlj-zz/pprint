local color = {}

color.FG = 1
color.BG = 2

---@param hex string
---@return integer,integer,integer
function color:generate_rgb(hex)
    local hex_len = #hex

    if hex_len == 3 then
        local c = tonumber(string.sub(hex, 2), 16)

        return c, c, c
    elseif hex_len == 7 then
        local r = tonumber(string.sub(hex, 2, 3), 16)
        local g = tonumber(string.sub(hex, 4, 5), 16)
        local b = tonumber(string.sub(hex, 6, 7), 16)

        return r, g, b
    else
        error('Not right hex.')
    end
end

---@param r integer
---@param g integer
---@param b integer
---@param depth? integer
---@return string
function color:escape_by_rgb(r, g, b, depth)
    -- print(r, g, b)

    local d = depth or self.FG
    local dint = 38
    if d == self.BG then
        dint = 48
    end

    return string.format("\\033[%s;2;%s;%s;%sm", dint, r, g, b)
end

---@param hex string
---@param depth? integer
---@return string
function color:escape_by_hex(hex, depth)
    local r, g, b = self:generate_rgb(hex)
    return self:escape_by_rgb(r, g, b, depth)

end

-----------------------run--------------------------
print(color:escape_by_hex('#2ecc71')) -- string color
print(color:escape_by_hex('#3498db')) -- number color
print(color:escape_by_hex('#ff7f50')) -- func color
print(color:escape_by_hex('#e74c3c')) -- nil color

print('\x1b[38;2;46;204;113m hello world \x1b[m')

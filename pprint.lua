---
--- pprint.lua
---
local pprint = {
    _version = '0.1.0'
}

local _insert = table.insert

--- Determine whether an element is in the table.
---@param t table
---@param ele any
---@return boolean
local function is_in_table(t, ele)
    for _, v in ipairs(t) do
        if v == ele then
            return true
        end
    end

    return false
end

--- Adjust a table whether is a list.
---@param t table
---@return boolean
local function is_list(t)
    local i = 1
    for k in pairs(t) do
        if t[i] == nil then
            return false
        end

        if k ~= i then
            return false
        end
        i = i + 1
    end

    return true
end

--- Split string by delimiter, and default: '\n'.
---@param input string
---@param delimiter? string
---@return table
local function split_string(input, delimiter)
    delimiter = delimiter or '\n'

    local result = {}
    local pattern = string.format('([^%s]+)', delimiter)

    for match in string.gmatch(input, pattern) do
        table.insert(result, match)
    end

    return result
end

--- Help to create a class.
---@param baseClass any
---@return table
local function class(baseClass)
    local newClass = {}
    newClass.__index = newClass
    newClass.__call = function(cls, ...)
        local instance = setmetatable({}, cls)
        if instance.new then
            instance:new(...)
        end
        return instance
    end
    if baseClass then
        setmetatable(newClass, baseClass)
    else
        setmetatable(newClass, {
            __call = newClass.__call
        })
    end
    return newClass
end

-------------------------------------------------------------------------------
-- PrettyPrinter Class
-------------------------------------------------------------------------------
local _normal_type = {
    'number', 'string', 'boolean', 'nil'
}

---@class PrettyPrinter
---@field pprint fun(self, obj):nil
---@field pformat fun(self, obj):nil
local PrettyPrinter = class()

---New function will be auto called when create `PrettyPrinter` instance.
---@param args? table
---       args.indent integer
---       args.width integer
---       args.depth integer
---       args.scientific_notation boolean
function PrettyPrinter:new(args)
    args = args or {}

    local _indent = args.indent or 2
    local _width = args.width or 80

    if _indent < 0 then
        error('indent must be >= 0')
    end
    if _width < 0 then
        error('width must be >= 0')
    end

    self._per_level_sp = _indent
    self._width = _width
    self._depth = args.depth
    self._compact = args.compact
    self._sort_tables = args.sort_tables
    self._scientific_notation = args.scientific_notation
end

--- Print the formatted representation of object to stream with a 
--- trailing newline.
---@param obj any
function PrettyPrinter:pprint(obj)
    local content = {}
    self:_format(obj, 0, 0, content, 0)
    print(table.concat(content))
end

--- Return the formatted representation of object as a string.
---@param obj any
---@return string
function PrettyPrinter:pformat(obj)
    local content = {}
    self:_format(obj, 0, 0, content, 0)
    return table.concat(content)
end

---comment
---@param obj any
---@param indent integer
---@param allowance integer
---@param content table
---@param level integer
function PrettyPrinter:_format(obj, indent, allowance, content, level)
    local o_typ = self:_match_type(obj)
    local p_fn = self._dispatch[o_typ]

    if p_fn ~= nil then
        p_fn(self, obj, indent, allowance, content, level + 1)
    else
        _insert(content, tostring(obj))
    end
end

---Check a type of object.
---Would return: nil, boolean, number, string, function, table, list
---@param obj any
---@return string
function PrettyPrinter:_match_type(obj)
    local o_typ = type(obj)
    if o_typ == 'table' then
        if is_list(obj) then
            return '_list'
        end
    end

    return '_' .. o_typ
end

function PrettyPrinter:_p_table(tb, indent, allowance, content, level)
    if self._depth ~= nil and level > self._depth then
        _insert(content, '{...}')
        return
    end

    _insert(content, '{\n')

    local next_indent = indent + self._per_level_sp
    for k, v in pairs(tb) do
        _insert(content, string.rep(' ', next_indent))

        local repr_len = self:_p_table_key(k, content)
        self:_format(v, next_indent + repr_len, allowance, content, level + 1)

        _insert(content, ',\n')
    end

    _insert(content, string.rep(' ', indent) .. '}')
    if level <= 1 then
        _insert(content, '\n')
    end

end

---@return integer :len of the key need used
function PrettyPrinter:_p_table_key(key, content)
    local k_typ = self:_match_type(key)
    local _format = function (pattern_str)
        return string.format(pattern_str, tostring(key))
    end

    local key_repr
    if k_typ == '_number' then
        key_repr = _format('[%s] = ')
    elseif k_typ == '_string' then
        key_repr = _format('["%s"] = ')
    else
        key_repr = _format('%s = ')
    end

    _insert(content, key_repr)

    return #key_repr
end

function PrettyPrinter:_p_list(lis, indent, allowance, content, level)
    if self._depth ~= nil and level > self._depth then
        _insert(content, '{...}')
        return
    end

    _insert(content, '{\n')

    local next_indent = indent + self._per_level_sp
    for _, v in ipairs(lis) do
        _insert(content, string.rep(' ', next_indent))
        self:_format(v, next_indent, allowance, content, level + 1)
        _insert(content, ',\n')
    end

    _insert(content, string.rep(' ', indent) .. '}')
    if level <= 1 then
        _insert(content, '\n')
    end

end

function PrettyPrinter:_p_function(fn, indent, allowance, content, level)
    local fn_info = debug.getinfo(fn)
    local params = {}

    -- IMPROVE: cannot get function name
    if fn_info.what == 'Lua' then
        local idx = 1

        while true do
            local param_name = debug.getlocal(fn, idx)
            if param_name then
                _insert(params, param_name)
                idx = 1 + idx
            else
                break
            end
        end

        local params_str
        if #params > 0 then
            params_str = table.concat(params, ', ')
        else
            params_str = ''
        end

        _insert(content, string.format('function (%s) end', params_str))
    else
        -- cannot parse the fn
        _insert(content, tostring(fn))
    end
end

function PrettyPrinter:_p_string(str, indent, allowance, content, level)
    local str_list = split_string(str, '\n')
    _insert(content, string.format('"%s"', str_list[1]))

    for i = 2, #str_list do
        local line = '\n' .. string.rep(' ', indent) ..
                         string.format('.."%s"', str_list[i])
        _insert(content, line)
    end

end

function PrettyPrinter:_p_number(num, indent, allowance, content, level)
    local num_limit = 10^6

    if self._scientific_notation == true then
        if num > num_limit or num < -num_limit then
            _insert(content, string.format('%e', num))
            return
        end
    end

    _insert(content, num)
end

--- Used to obtain the formatting methods corresponding to different data types.
--- The type of (nil, number) not needed.
PrettyPrinter._dispatch = {
    _table = PrettyPrinter._p_table,
    _list = PrettyPrinter._p_list,
    _function = PrettyPrinter._p_function,
    _string = PrettyPrinter._p_string,
    _number = PrettyPrinter._p_number,

}

--- Determines whether object requires recursive representation.
---@param obj any
---@return boolean
function PrettyPrinter:isrecursive(obj)
    if is_in_table(_normal_type, type(obj)) then
        return true
    end

    return false
end


-------------------------------------------------------------------------------
-- pprint
-------------------------------------------------------------------------------
pprint.PrettyPrinter = PrettyPrinter

--- Print the formatted representation of object to stream with a 
--- trailing newline.
--- The `args` should be a table, allowed to set some param in it.
--- The supported settings are the same as `pprint.pprint`, the difference
--- is that it is used as a whole.
---@param obj any
---@param args? table
pprint.pp = function (obj, args)
    PrettyPrinter(args):pprint(obj)
end

--- Print the formatted representation of object to stream with a 
--- trailing newline.
---@param obj any
---@param indent? integer
---@param width? integer
---@param depth? integer
pprint.pprint = function (obj, indent, width, depth)
    local args = {
        indent = indent,
        width = width,
        depth = depth,
    }
    PrettyPrinter(args):pprint(obj)
end

--- Return the formatted representation of object as a string.
---@param obj any
---@param indent? integer
---@param width? integer
---@param depth? integer
pprint.pformat = function (obj, indent, width, depth)
    local args = {
        indent = indent,
        width = width,
        depth = depth,
    }
    return PrettyPrinter(args):pformat(obj)
end

--- Determines whether object requires recursive representation.
---@param obj any
---@return boolean
pprint.isrecursive = function (obj)
    return PrettyPrinter():isrecursive(obj)
end

return pprint

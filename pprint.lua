---
--- pprint.lua
---
--- Copyright (c) 2023 Zachary Zhang
---
--- The purpose of this package is to provide a nice formatter that targets
--- arbitrary types. Friendly data types that support nesting, and can be
--- formatted recursively. It can support fast printing and get the formatted
--- string, and also provides a series of parameters to adjust the formatting
--- style. And it maintains a good performance as much as possible.
---
local pprint = {
    _version = '0.1.0'
}

-- localization lib
local string = string
local _concat = table.concat
-- preferred over table.insert due to better performance on PUC Lua.
local _insert = function(tb, val)
    tb[#tb + 1] = val
end

--- Adjust a table whether is a list.
---@param t table
---@return boolean
local function is_table_list(t)
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

--- Adjust a table whether empty.
---@param t table
---@return boolean
local function is_table_empty(t)
    return next(t) == nil
end

local split_string_pattern = '([^%s]*)%s'
--- Split string by delimiter, and default: '\n'.
--- Cases:
---     '123' -> {"123"}
---     '123\n' -> {"123",""}
---     '123\n\n' -> {"123","","",}
---     '123\n123\n123' -> {"123","123","123"}
---@param input string
---@param delimiter? string
---@return table
local function split_string(input, delimiter)
    local result = {}
    if input == nil then
        return result
    end

    -- has default delimiter
    delimiter = delimiter or '\n'

    for match in string.gmatch(input .. delimiter, split_string_pattern:format(
        delimiter, delimiter)) do
        _insert(result, match)
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

---@type table<string, boolean>
local _no_isrecursive_type = {
    ['number'] = true,
    ['string'] = true,
    ['boolean'] = true,
    ['nil'] = true
}

---@class PrettyPrinter
---@field pprint fun(self, obj):nil
---@field pformat fun(self, obj):nil
local PrettyPrinter = class()

---New function will be auto called when create `PrettyPrinter` instance.
---@param args? table
---       args.indent integer @Number of spaces to indent for each level of nesting.
---       args.width integer @Attempted maximum number of columns in the output.
---       args.depth integer @Depth limit, exceeding the limit will be folded.
---       args.compact boolean @If true, several items will be combined in one line.
---       args.scientific_notation boolean @If true, will display number with
---                                         scientific notation.
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
    self._number_limit = 10 ^ 6
end

--- Determines whether object requires recursive representation.
---@param obj any
---@return boolean
function PrettyPrinter:isrecursive(obj)
    return not _no_isrecursive_type[type(obj)] == true
end

--- Determines whether the formatted representation of object is "readable" that
--- can be used to reconstruct the object's value via `load()`.
---@param obj any
---@return boolean
function PrettyPrinter:isreadable(obj)
    return self:_format(obj, 0, {}, 0)
end

--- Print the formatted representation of object to stream with a
--- trailing newline.
---@param obj any
function PrettyPrinter:pprint(obj)
    local context = {}
    self:_format(obj, 0, context, 0)

    print(self:_to_assemble(context))
end

--- Return the formatted representation of object as a string.
---@param obj any
---@return string
function PrettyPrinter:pformat(obj)
    local context = {}
    self:_format(obj, 0, context, 0)

    return self:_to_assemble(context)
end

--- Help to assemble the context.
---@param context table @A table context with formated.
---@return string
function PrettyPrinter:_to_assemble(context)
    return _concat(context)
end

---
---@param obj any
---@param indent integer
---@param context table
---@param level integer
---@return boolean @isreadable
function PrettyPrinter:_format(obj, indent, context, level)
    local o_typ = self:_match_type(obj)

    ---@type fun(...):boolean @Corresponding type of processing function
    local p_fn = self._dispatch[o_typ]

    if p_fn ~= nil then
        -- onlu plus level here, if recursively will recall `_format`
        return p_fn(self, obj, indent, context, level + 1)
    else
        _insert(context, tostring(obj))
        return false
    end
end

---Check a type of object.
---Would return: (nil, boolean, number, string, function, table, list) and startwith '_'.
---@param obj any
---@return string
function PrettyPrinter:_match_type(obj)
    local o_typ = type(obj)
    return '_' .. o_typ
end

---@return boolean @isreadable
function PrettyPrinter:_p_table(tb, indent, context, level)
    -- whether empty table
    if is_table_empty(tb) then
        _insert(context, '{ }')
        return true
    end

    -- whether depth than max level
    if self._depth ~= nil and level >= self._depth then
        _insert(context, '{...}')
        return false
    end

    local start_symbol, indent_space = '{\n', string.rep(' ', indent)
    if self._compact == true then
        start_symbol, indent_space = '{', ' '
    end

    _insert(context, start_symbol)

    local next_indent = indent + self._per_level_sp
    local _isreadable

    local _is_list = is_table_list(tb)
    if _is_list then
        _isreadable = self:_p_t_list(tb, next_indent, context, level)
    else
        _isreadable = self:_p_t_map(tb, next_indent, context, level)
    end

    _insert(context, indent_space)
    _insert(context, '}')
    if level <= 1 and self._compact ~= true then
        _insert(context, '\n')
    end

    return _isreadable
end

---@return boolean @isreadable
function PrettyPrinter:_p_t_map(map, indent, context, level)
    local k_isreadable = true
    local v_isreadable = true

    local item_end_symbol, indent_space = ',\n', string.rep(' ', indent)
    if self._compact == true then
        item_end_symbol, indent_space = ',', ' '
    end

    local keys = map -- default
    if self._sort_tables == true then
        keys = {}
        for k, _ in pairs(map) do
            _insert(keys, k)
            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)
        end

    end

    local k, idx = self:_map_next_k(keys, nil)
    local v

    while k ~= nil do
        -- for k, v in pairs(map) do
        v = map[k]

        _insert(context, indent_space)

        local repr_len, _k_isreadable = self:_p_table_key(k, context)
        k_isreadable = _k_isreadable and k_isreadable

        v_isreadable = self:_format(v, indent + repr_len, context, level) and
                           v_isreadable

        _insert(context, item_end_symbol)

        k, idx = self:_map_next_k(keys, idx)
    end

    return k_isreadable and v_isreadable
end

--- Get the key and next index of table.
---@param tb table
---@param index any
---@return any, any
function PrettyPrinter:_map_next_k(tb, index)
    local k, v = next(tb, index)

    if self._sort_tables == true then
        return v, k
    else
        return k, k
    end
end

--- Format the key of map.
---@return integer @Len of the key need used
---@return boolean @isreadable
function PrettyPrinter:_p_table_key(key, context)
    local k_typ = self:_match_type(key)
    local _format = function(pattern_str)
        return string.format(pattern_str, tostring(key))
    end

    local key_repr
    local isreadable = true

    if k_typ == '_number' or k_typ == '_boolean' or k_typ == '_nil' then
        key_repr = _format('[%s] = ')
    elseif k_typ == '_string' then
        key_repr = _format('["%s"] = ')
    else
        key_repr = _format('%s = ')
        isreadable = false
    end

    _insert(context, key_repr)

    return #key_repr, isreadable
end

---@return boolean @isreadable
function PrettyPrinter:_p_t_list(lis, indent, context, level)
    local _isreadable = true

    local item_end_symbol, indent_space = ',\n', string.rep(' ', indent)
    if self._compact == true then
        item_end_symbol, indent_space = ',', ' '
    end

    for i = 1, #lis - 1 do
        _insert(context, indent_space)
        _isreadable = self:_format(lis[i], indent, context, level) and
                          _isreadable
        _insert(context, item_end_symbol)
    end

    _insert(context, indent_space)
    _isreadable = self:_format(lis[#lis], indent, context, level) and
                      _isreadable
    if self._compact ~= true then
        _insert(context, '\n')
    end

    return _isreadable
end

---@return boolean @isreadable
function PrettyPrinter:_p_function(fn, indent, context, level)
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
            params_str = _concat(params, ', ')
        else
            params_str = ''
        end

        _insert(context, string.format('function (%s) end', params_str))
    else
        -- cannot parse the fn
        _insert(context, tostring(fn))
    end

    return false
end

---@return boolean @isreadable
function PrettyPrinter:_p_string(str, indent, context, level)
    -- compact not need process
    if self._compact == true then
        local partten = '"%s"'
        _insert(context, partten:format(str):gsub('\n', '\\n'))
        return true
    end

    local str_list = split_string(str, '\n')
    if #str_list == 1 then
        _insert(context, string.format('"%s"', str_list[1]))
        return true
    end

    local _part_str
    _insert(context, string.format('"%s\\n"', str_list[1]))

    -- TODO: Performance Testing
    for i = 2, #str_list - 1 do
        -- _part_str = '..\n' .. string.rep(' ', indent) ..
        -- string.format('"%s\\n"', str_list[i])
        -- _insert(context, _part_str)

        _insert(context, '..\n')
        _insert(context, string.rep(' ', indent))
        _insert(context, string.format('"%s\\n"', str_list[i]))
    end
    -- _part_str = '..\n' .. string.rep(' ', indent) ..
    -- string.format('"%s"', str_list[#str_list])
    -- _insert(context, _part_str)

    _insert(context, '..\n')
    _insert(context, string.rep(' ', indent))
    _insert(context, string.format('"%sn"', str_list[#str_list]))

    return true
end

---@return boolean @isreadable
function PrettyPrinter:_p_number(num, indent, context, level)
    local num_limit = self._number_limit

    if self._scientific_notation == true and
        (num > num_limit or num < -num_limit) then

        _insert(context, string.format('%e', num))
        return true
    end

    _insert(context, num)
    return true
end

---@return boolean @isreadable
function PrettyPrinter:_p_nil(n, indent, context, level)
    _insert(context, tostring(n))
    return true
end

--- Used to obtain the formatting methods corresponding to different data types.
--- The type of (nil, number) not needed.
PrettyPrinter._dispatch = {
    _table = PrettyPrinter._p_table,
    _function = PrettyPrinter._p_function,
    _string = PrettyPrinter._p_string,
    _number = PrettyPrinter._p_number,
    _nil = PrettyPrinter._p_nil

}

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
pprint.pp = function(obj, args)
    PrettyPrinter(args):pprint(obj)
end

--- Print the formatted representation of object to stream with a
--- trailing newline.
---@param obj any
---@param indent? integer
---@param width? integer
---@param depth? integer
pprint.pprint = function(obj, indent, width, depth)
    local args = {
        indent = indent,
        width = width,
        depth = depth
    }
    PrettyPrinter(args):pprint(obj)
end

--- Return the formatted representation of object as a string.
---@param obj any
---@param indent? integer
---@param width? integer
---@param depth? integer
pprint.pformat = function(obj, indent, width, depth)
    local args = {
        indent = indent,
        width = width,
        depth = depth
    }
    return PrettyPrinter(args):pformat(obj)
end

--- Determines whether object requires recursive representation.
---@param obj any
---@return boolean
pprint.isrecursive = function(obj)
    return PrettyPrinter():isrecursive(obj)
end

--- Determines whether the formatted representation of object is "readable" that
--- can be used to reconstruct the object's value via `load()`.
---@param obj any
---@return boolean
pprint.isreadable = function(obj)
    return PrettyPrinter:isreadable(obj)
end

return pprint

local fmt = string.format

local captured = {
    o_print = print,
    c_name = 'nil',
    c_output = {}
}

function captured:pour()
    for _, v in ipairs(self.c_output) do
        self.o_print(string.rep('-', 50))
        self.o_print(v.caller)
        self.o_print(string.rep('-', 50))
        self.o_print(v.content, '\n')
    end

    -- clear
    self.c_output = {}
end

function captured:hijack_print(name)
    if name ~= nil then
        self.c_name = name
    end

    -- redefine global print
    function print(...)
        -- local level = 2
        -- local info = debug.getinfo(level, "n")
        -- local caller = info.name or "unknown"

        local output = {...}
        table.insert(self.c_output, {
            caller = self.c_name,
            content = table.concat(output, "\t")
        })
    end
end

function captured:unhijack_print()
    self.c_name = 'nil'
    print = self.o_print
end

function captured:test(name, func)
    self:hijack_print(name)
    xpcall(function()
        func()
        self.o_print(fmt("[pass] %s", name))
    end, function(err)
        self.o_print(fmt("[fail] %s : %s", name, err))
    end)
    self:unhijack_print()
end

------- ready -----------------------------------

local a_list = {'1', '2', '3\n4'}

local say = function(msg)
    print('say: ' .. msg)
end
local person = {
    'This is a person',
    ['name'] = 'Tom',
    age = 18,
    parent = nil,
    hobbys = {
        'game',
        ['ball'] = {'football', 'basketball'}
    },
    actions = {'sit', 'walk', 'run', say},
    2 ^ 26, -- a big number
    str_list = a_list,
    num_list = {1, 2, 3, 100}
}

function person.intro()
    print('My name is Tom.')
end

------- test case -------------------------------
local pprint = loadfile('../pprint.lua')()

captured:test('PrettyPrinter:isrecursive', function()
    assert(pprint.PrettyPrinter:isrecursive('string') == false)
    assert(pprint.PrettyPrinter:isrecursive(123) == false)
    assert(pprint.PrettyPrinter:isrecursive(false) == false)
    assert(pprint.PrettyPrinter:isrecursive({'a', 'b'}) == true)
end)

captured:test('PrettyPrinter:isreadable', function()
    assert(pprint.PrettyPrinter({
        depth = 3,
        scientific_notation = true
    }):isreadable(person) == false)

    assert(pprint.PrettyPrinter():isreadable(1) == true)
    assert(pprint.PrettyPrinter():isreadable('a') == true)
    assert(pprint.PrettyPrinter():isreadable(nil) == true)

    assert(pprint.PrettyPrinter():isreadable({1, 2, 3}) == true)

    assert(pprint.PrettyPrinter():isreadable({
        abc = function(...)
            -- no content
        end
    }) == false)
    assert(pprint.PrettyPrinter():isreadable({
        [function()
        end] = 'abc'
    }) == false)
end)

captured:test('PrettyPrinter.pprint:compact', function()
    local printer = pprint.PrettyPrinter({
        compact = true
    })

    printer:pprint(person)
end)

captured:test('PrettyPrinter.pprint:depth', function()
    local printer = pprint.PrettyPrinter({
        depth = 3,
        sort_tables = true,
        scientific_notation = true,
        color = true
    })

    printer:pprint(person)
end)

captured:test('PrettyPrinter.pprint:color', function()
    local printer = pprint.PrettyPrinter({
        color = true
    })

    printer:pprint(nil)
    local t = {1, 2, 3}
    printer:pprint({
        [t] = 1
    })
end)

captured:test('PrettyPrinter.pprint', function()
    local tb = {}
    local tmp = tb
    for i = 1, 10 do
        tmp['key'] = {}
        tmp = tmp.key
    end

    pprint.PrettyPrinter({
        depth = 6
    }):pprint(tb)
end)

------- last ------------------------------------
captured:pour()

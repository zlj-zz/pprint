local pprint = loadfile('../pprint.lua')()

local fmt = string.format

local function test(name, func)
  xpcall(function()
    func()
    print( fmt("[pass] %s", name) )
  end, function(err)
    print( fmt("[fail] %s : %s", name, err) )
  end)
end


------- test case -----------------------------

local a_list = {
    '1', '2', '3\n4'
}

local test_struct = {
    'a',
    100, nil,
    list = a_list,
    ['name'] = 'Tom',
    age = 18,
    hobbys = {
        'game',
        ['ball'] = {
            'football',
            'basketball'
        }
    },
    say_hello = function ()
       print('hello')
    end,
}

function test_struct.jump(one, two, three)
    -- content
end

test('PerttyPrinter.pprint', function ()
    local printer = pprint.PrettyPrinter({depth=3})
    printer:pprint(test_struct)

    --local fn = test_struct.jump
    --printer:pprint(debug.getinfo(fn, 'Snu'))
    --printer:pprint(debug.getlocal(fn, 1))
end)


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


--test('PerttyPrinter.pprint', function ()
    --local PerttyPrinter = pprint.PerttyPrinter
    --assert(PerttyPrinter, table)

    --local printer = PerttyPrinter()
    --print(type(printer))
    --printer.pprint(test_struct)
--end)

function test()
    local a_list = {
        '1', '2', '3\n4'
    }

    local test_struct = {
        'a',
        100, nil,
        list = a_list,
        ['name'] = 'Tom',
        age = 18,
    }

    local printer = pprint.PrettyPrinter()
    printer:pprint(test_struct)
end
test()

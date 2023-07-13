local pprint = loadfile('../pprint.lua')()

local test_struct = {
    ['name'] = 'Tom',
    age = 18,
    hobbys = {
        'game',
        ['ball'] = {'football', 'basketball'}
    },
    eat = function(food)
        print('I eat: ' .. food)
    end
}
pprint.pprint(test_struct)

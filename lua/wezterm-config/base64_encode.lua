-- using relevant pieces of Ilya Kolbin's https://github.com/iskolbin/lbase64 under public domain
-- using Lua 5.1

local base64 = {}

local function extract(v, from, width)
    local w = 0
    local flag = 2 ^ from
    for i = 0, width - 1 do
        local flag2 = flag + flag
        if v % flag2 >= flag then
            w = w + 2 ^ i
        end
        flag = flag2
    end
    return w
end

function base64.makeencoder(s62, s63, spad)
    local encoder = {}
    for b64code, char in pairs({
        [0] = 'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        'w',
        'x',
        'y',
        'z',
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        s62 or '+',
        s63 or '/',
        spad or '=',
    }) do
        encoder[b64code] = char:byte()
    end
    return encoder
end

local DEFAULT_ENCODER = base64.makeencoder()
local char, concat = string.char, table.concat

function base64.encode(str, encoder, usecaching)
    encoder = encoder or DEFAULT_ENCODER
    local t, k, n = {}, 1, #str
    local lastn = n % 3
    local cache = {}
    for i = 1, n - lastn, 3 do
        local a, b, c = str:byte(i, i + 2)
        local v = a * 0x10000 + b * 0x100 + c
        local s
        if usecaching then
            s = cache[v]
            if not s then
                s = char(
                    encoder[extract(v, 18, 6)],
                    encoder[extract(v, 12, 6)],
                    encoder[extract(v, 6, 6)],
                    encoder[extract(v, 0, 6)]
                )
                cache[v] = s
            end
        else
            s = char(
                encoder[extract(v, 18, 6)],
                encoder[extract(v, 12, 6)],
                encoder[extract(v, 6, 6)],
                encoder[extract(v, 0, 6)]
            )
        end
        t[k] = s
        k = k + 1
    end
    if lastn == 2 then
        local a, b = str:byte(n - 1, n)
        local v = a * 0x10000 + b * 0x100
        t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)], encoder[64])
    elseif lastn == 1 then
        local v = str:byte(n) * 0x10000
        t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[64], encoder[64])
    end
    return concat(t)
end

return base64

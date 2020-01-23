class "Push"
-- representation of the physical Push device, and methods to initialise the device and tool

function Push:__init ()
    self.device_name = Push.device_name
    self.output = {}
    self.input = {}
    self.encoderStream = {}
    self.midi = Midi(self)
    self.state = State(self)
    self.modes = Modes(self)
end

Push.device_name = "Ableton Push (User Port)"

-- CC value for the various lighting modes of the button LEDs. Blink value can be added to a button or note_val light to make it blink. Pad light can be set to various animated modes by changing the channel of the note sent to Push.
Push.light = {
    button = {
        low = 1,
        high = 4,
        off = 0
    },
    note_val = {
        dim_red = 1,
        red = 4,
        dim_orange = 7,
        orange = 10,
        dim_yellow = 13,
        yellow = 16,
        dark_green = 19,
        light_green = 22,
        off = 0
    },
    blink = {
        slow = 1,
        fast = 2
    },
    pad = {
        dark_grey = 1,
        light_grey = 2,
        white = 3,
        pink = 4,
        strong_red = 5,
        mid_red = 6,
        dim_red = 7,
        beige = 8,
        strong_orange = 9,
        mid_orange = 10,
        dim_orange = 11,
        pale_yellow = 12,
        strong_yellow = 13,
        mid_yellow = 14,
        dim_yellow = 15,
        pale_pea = 16,
        pea_green = 17,
        mid_pea = 18,
        dim_pea = 19,
        pale_green = 20,
        strong_green = 21,
        mid_green = 22,
        dim_green = 23,
        pale_green_2 = 24,
        neon_green = 25,
        dim_neon_green = 26,
        dim_green_2 = 27,
        pale_green_3 = 28,
        sea_green = 29,
        mid_sea = 30,
        dim_sea = 31,
        pale_teal = 32,
        strong_teal = 33,
        mid_teal = 34,
        dim_teal = 35,
        pale_sky_blue = 36,
        strong_sky_blue = 37,
        mid_sky_blue = 38,
        dim_sky_blue = 39,
        pale_mint_blue = 40,
        strong_mint_blue = 41,
        mid_mint_blue = 42,
        dim_mint_blue = 43,
        pale_blue = 44,
        super_blue = 45,
        mid_super_blue = 46,
        dim_super_blue = 47,
        pale_purple = 48,
        strong_purple = 49,
        mid_purple = 50,
        dim_purple = 51,
        pale_cerise = 52,
        strong_cerise = 53,
        mid_cerise = 54,
        dim_cerise = 55,
        pale_neon_pink = 56,
        neon_pink = 57,
        mid_neon_pink = 58,
        dim_neon_pink = 59,

        off = 0
    },
    -- MIDI channel sets the pad lighting mode. fade goes from white to colour value. Saw oscillates in a saw wave. Square oscillates in
    -- a square wave surprisingly. They are in order from fastest to slowest for each option respectively.
    channel = {
        on = 0,
        fade_1 = 1,
        fade_2 = 2,
        fade_3 = 3,
        fade_4 = 4,
        fade_5 = 5,
        saw_1 = 6,
        saw_2 = 7,
        saw_3 = 8,
        saw_4 = 9,
        saw_5 = 10,
        square_1 = 11,
        square_2 = 12,
        square_3 = 13,
        square_4 = 14,
        square_5 = 15
    }
}

Push.control = {
    [71]  = { name="dial1",        cc=71,  note=0,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [72]  = { name="dial2",        cc=72,  note=1,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [73]  = { name="dial3",        cc=73,  note=2,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [74]  = { name="dial4",        cc=74,  note=3,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [75]  = { name="dial5",        cc=75,  note=4,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [76]  = { name="dial6",        cc=76,  note=5,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [77]  = { name="dial7",        cc=77,  note=6,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [78]  = { name="dial8",        cc=78,  note=7,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [79]  = { name="volume",       cc=79,  note=8,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [14]  = { name="tempo",        cc=14,  note=9,   value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [15]  = { name="swing",        cc=15,  note=10,  value=nil,                   hasCC=true,  hasNote=true,  hasLED=false },
    [3]   = { name="tap_tempo",    cc=3,   note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [9]   = { name="metronome",    cc=9,   note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [119] = { name="undo",         cc=119, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [118] = { name="delete",       cc=118, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [117] = { name="double",       cc=117, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [116] = { name="quantize",     cc=116, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [90]  = { name="fixed_length", cc=90,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [89]  = { name="automation",   cc=89,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [88]  = { name="duplicate",    cc=88,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [87]  = { name="new",          cc=87,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [86]  = { name="record",       cc=86,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [85]  = { name="play",         cc=85,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [28]  = { name="master",       cc=28,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [29]  = { name="stop",         cc=29,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [43]  = { name="x32t",         cc=43,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [42]  = { name="x32",          cc=42,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [41]  = { name="x16t",         cc=41,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [40]  = { name="x16",          cc=40,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [39]  = { name="x8t",          cc=39,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [38]  = { name="x8",           cc=38,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [37]  = { name="x4t",          cc=37,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [36]  = { name="x4",           cc=36,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [114] = { name="volume",       cc=114, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [115] = { name="pan_send",     cc=115, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [112] = { name="track",        cc=112, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [113] = { name="clip",         cc=113, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [110] = { name="device",       cc=110, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [111] = { name="browse",       cc=111, note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [62]  = { name="level_down",   cc=62,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [63]  = { name="level_up",     cc=63,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [60]  = { name="mute",         cc=60,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [61]  = { name="solo",         cc=61,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [58]  = { name="scales",       cc=58,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [59]  = { name="user",         cc=59,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [56]  = { name="repeat",       cc=56,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [57]  = { name="accent",       cc=57,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [54]  = { name="oct_down",     cc=54,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [55]  = { name="oct_up",       cc=55,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [52]  = { name="add_effect",   cc=52,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [53]  = { name="add_track",    cc=53,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [50]  = { name="note",         cc=50,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [51]  = { name="session",      cc=51,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [48]  = { name="select",       cc=48,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [49]  = { name="shift",        cc=49,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [46]  = { name="csr_up",       cc=46,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [47]  = { name="csr_down",     cc=47,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [44]  = { name="csr_left",     cc=44,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [45]  = { name="csr_right",    cc=45,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [20]  = { name="softkey1A",    cc=20,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [21]  = { name="softkey2A",    cc=21,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [22]  = { name="softkey3A",    cc=22,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [23]  = { name="softkey4A",    cc=23,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [24]  = { name="softkey5A",    cc=24,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [25]  = { name="softkey6A",    cc=25,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [26]  = { name="softkey7A",    cc=26,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [27]  = { name="softkey8A",    cc=27,  note=nil, value=Push.light.button.low, hasCC=true,  hasNote=false, hasLED=true  },
    [102] = { name="softkey1B",    cc=102, note=nil, value=Push.light.pad.pink,   hasCC=true,  hasNote=false, hasLED=true  },
    [103] = { name="softkey2B",    cc=103, note=nil, value=Push.light.pad.pink,   hasCC=true,  hasNote=false, hasLED=true  },
    [104] = { name="softkey3B",    cc=104, note=nil, value=Push.light.pad.pink,   hasCC=true,  hasNote=false, hasLED=true  },
    [105] = { name="softkey4B",    cc=105, note=nil, value=Push.light.pad.pink,   hasCC=true,  hasNote=false, hasLED=true  },
    [106] = { name="softkey5B",    cc=106, note=nil, value=Push.light.pad.pink,   hasCC=true,  hasNote=false, hasLED=true  },
    [107] = { name="softkey6B",    cc=107, note=nil, value=Push.light.pad.pink,   hasCC=true,  hasNote=false, hasLED=true  },
    [108] = { name="softkey7B",    cc=108, note=nil, value=Push.light.pad.pink,   hasCC=true,  hasNote=false, hasLED=true  },
    [109] = { name="softkey8B",    cc=109, note=nil, value=Push.light.pad.pink,   hasCC=true,  hasNote=false, hasLED=true  },

    [164] = { name="pad01",        cc=0,   note=36,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [165] = { name="pad02",        cc=0,   note=37,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [166] = { name="pad03",        cc=0,   note=38,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [167] = { name="pad04",        cc=0,   note=39,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [168] = { name="pad05",        cc=0,   note=40,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [169] = { name="pad06",        cc=0,   note=41,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [170] = { name="pad07",        cc=0,   note=42,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [171] = { name="pad08",        cc=0,   note=43,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [172] = { name="pad09",        cc=0,   note=44,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [173] = { name="pad10",        cc=0,   note=45,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [174] = { name="pad11",        cc=0,   note=46,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [175] = { name="pad12",        cc=0,   note=47,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [176] = { name="pad13",        cc=0,   note=48,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [177] = { name="pad14",        cc=0,   note=49,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [178] = { name="pad15",        cc=0,   note=50,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [179] = { name="pad16",        cc=0,   note=51,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [180] = { name="pad17",        cc=0,   note=52,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [181] = { name="pad18",        cc=0,   note=53,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [182] = { name="pad19",        cc=0,   note=54,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [183] = { name="pad20",        cc=0,   note=55,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [184] = { name="pad21",        cc=0,   note=56,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [185] = { name="pad22",        cc=0,   note=57,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [186] = { name="pad23",        cc=0,   note=58,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [187] = { name="pad24",        cc=0,   note=59,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [188] = { name="pad25",        cc=0,   note=60,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [189] = { name="pad26",        cc=0,   note=61,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [190] = { name="pad27",        cc=0,   note=62,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [191] = { name="pad28",        cc=0,   note=63,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [192] = { name="pad29",        cc=0,   note=64,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [193] = { name="pad30",        cc=0,   note=65,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [194] = { name="pad31",        cc=0,   note=66,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [195] = { name="pad32",        cc=0,   note=67,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [196] = { name="pad33",        cc=0,   note=68,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [197] = { name="pad34",        cc=0,   note=69,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [198] = { name="pad35",        cc=0,   note=70,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [199] = { name="pad36",        cc=0,   note=71,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [200] = { name="pad37",        cc=0,   note=72,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [201] = { name="pad38",        cc=0,   note=73,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [202] = { name="pad39",        cc=0,   note=74,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [203] = { name="pad40",        cc=0,   note=75,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [204] = { name="pad41",        cc=0,   note=76,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [205] = { name="pad42",        cc=0,   note=77,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [206] = { name="pad43",        cc=0,   note=78,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [207] = { name="pad44",        cc=0,   note=79,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [208] = { name="pad45",        cc=0,   note=80,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [209] = { name="pad46",        cc=0,   note=81,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [210] = { name="pad47",        cc=0,   note=82,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [211] = { name="pad48",        cc=0,   note=83,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [212] = { name="pad49",        cc=0,   note=84,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [213] = { name="pad50",        cc=0,   note=85,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [214] = { name="pad51",        cc=0,   note=86,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [215] = { name="pad52",        cc=0,   note=87,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [216] = { name="pad53",        cc=0,   note=88,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [217] = { name="pad54",        cc=0,   note=89,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [218] = { name="pad55",        cc=0,   note=90,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [219] = { name="pad56",        cc=0,   note=91,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [220] = { name="pad57",        cc=0,   note=92,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [221] = { name="pad58",        cc=0,   note=93,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [222] = { name="pad59",        cc=0,   note=94,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [223] = { name="pad60",        cc=0,   note=95,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [224] = { name="pad61",        cc=0,   note=96,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [225] = { name="pad62",        cc=0,   note=97,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [226] = { name="pad63",        cc=0,   note=98,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [227] = { name="pad64",        cc=0,   note=99,  value=Push.light.pad.off,    hasCC=false, hasNote=true,  hasLED=true  },
    [140] = { name="bender",       cc=0,   note=12,  value=nil,                   hasCC=false, hasNote=true,  hasLED=false }
}

function Push:open ()
    if not table.find(renoise.Midi.available_output_devices(), self.device_name) then
        return false
    end

    if self.output.is_open then
        self.output:close()
        print("closing output")
    end

    self.output = renoise.Midi.create_output_device(self.device_name)
    print("opening output")

    if self.input.is_open then
        self.input:close()
        print("closing input")
    end

    self.input = renoise.Midi.create_input_device(self.device_name, {self.midi, Midi.handleMidi})
    print("opening input")
    return true
end

function Push:close ()
    if self.output.is_open then
        self.output:close()
        print("closing output")
    end
    if self.input.is_open then
        self.input:close()
        print("closing input")
    end
end

function Push:start ()
    if not self:open() then
        print("[PushyPushPush]: Cannot find Ableton Push device")
        if tool:has_timer({self, Push.start}) then
            return
        else
            tool:add_timer({self, Push.start}, 5000)
        end
        return
    end
    if tool:has_timer({self, Push.start}) then tool:remove_timer({self, Push.start}) end
    self.midi:clearDisplay()
    -- self.midi:initOSC()
    -- if self.midi.server then
    --     self.midi:runServer()
    -- end
    -- self.state = State(self)
    self.state:getState()
    -- self.modes = Modes(self)
    self.state.dirty = true
    self.state.activeMode = Modes.sequencer
    self.state.activeMode.lights(self.modes)
    self.state.activeMode.display(self.modes)
    tool.app_idle_observable:add_notifier(self, self.update)
    song.transport.playing_observable:add_notifier(self.state, State.setPlaying)
    song.transport.edit_mode_observable:add_notifier(self.state, State.setEditing)
    song.selected_sequence_index_observable:add_notifier(self.state, State.setSequenceIndex)
    song.selected_pattern_index_observable:add_notifier(self.state, State.setActivePattern)
    song.selected_track_index_observable:add_notifier(self.state, State.setActiveTrack)
    song.selected_instrument_index_observable:add_notifier(self.state, State.setActiveInstrument)
    printSelf(self)
    printSelf(self.midi)
    printSelf(self.modes)
    printSelf(self.state)

end

function Push:stop ()
    self.midi:clearDisplay()
    local data, index
    for i = 0, 128 do
        data = {Midi.status.cc, i, Push.light.button.off}
        self.midi:sendMidi(data)
        data = {Midi.status.note_on, i, Push.light.pad.off}
        self.midi:sendMidi(data)
    end

    -- if self.midi.server then
    --     self.midi:closeServer()
    -- end

    self:close()

    if tool:has_timer({self, Push.start}) then
        tool:remove_timer({self, Push.start})
    end
    if tool.app_idle_observable:has_notifier(self, self.update) then
        tool.app_idle_observable:remove_notifier(self, self.update)
    end
    if song.transport.playing_observable:has_notifier(self.state, State.setPlaying) then
        song.transport.playing_observable:remove_notifier(self.state, State.setPlaying)
    end
    if song.transport.edit_mode_observable:has_notifier(self.state, State.setEditing) then
        song.transport.edit_mode_observable:remove_notifier(self.state, State.setEditing)
    end
    if song.selected_sequence_index_observable:has_notifier(self.state, State.setSequenceIndex) then
        song.selected_sequence_index_observable:remove_notifier(self.state, State.setSequenceIndex)
    end
    if song.selected_pattern_index_observable:has_notifier(self.state, State.setActivePattern) then
        song.selected_pattern_index_observable:remove_notifier(self.state, State.setActivePattern)
    end
    if song.selected_track_index_observable:has_notifier(self.state, State.setActiveTrack) then
        song.selected_track_index_observable:remove_notifier(self.state, State.setActiveTrack)
    end
    if song.selected_instrument_index_observable:has_notifier(self.state, State.setActiveInstrument) then
        song.selected_instrument_index_observable:remove_notifier(self.state, State.setActiveInstrument)
    end
end

function Push:update ()
    if self.state.dirty then
        local data, dummy, index
        local string = table.copy(Midi.sysex.write_line)
        for i = 1, 120 do
            if self.state.current[i] and self.state.current[i].hasCC and self.state.current[i].hasLED then
                data = {Midi.status.cc, self.state.current[i].cc, self.state.current[i].value}
                self.midi:sendMidi(data)
            end
            index = i + 128
            if self.state.current[index] and self.state.current[index].hasNote and self.state.current[index].hasLED then
                data = {Midi.status.note_on, self.state.current[index].note, self.state.current[index].value}
                self.midi:sendMidi(data)
            end
        end
        for i = 1, 4 do
        dummy = string
            for j = 1, 8 do
                if self.state.display.line[i].zone[j] ~= "" then
                    string = self.midi:formatLine(string, self.state.display.line[i].zone[j], i, j)
                end
                if j == 8 and rawequal(string, dummy) then string = self.midi:formatLine(string, "", i)  end
            end
            self.midi:writeText(string, i)
            string = table.copy(Midi.sysex.write_line)
        end
        self.state.dirty = false
    end
end


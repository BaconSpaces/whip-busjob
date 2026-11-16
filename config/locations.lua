-- locations.lua by Tnoxious https://github.com/Tnoxious -- WhipFX edition
-- One list of stops per line in Config.Lines. Replace with your own vector4s if needed.
-- Stand on the spot in game, open /w -> Coords and press G to copy vector4(x, y, z, heading).

Config.Stops = {
    city = {
        vector4(303.92, -766.28, 29.31, 256.12),
        vector4(114.26, -781.23, 31.41, 157.4),
        vector4(-505.95, 23.29, 44.78, 185.54),
        vector4(-694.55, -4.33, 38.26, 198.11),
        vector4(-931.47, -123.26, 37.76, 208.75),
        vector4(-1528.4, -464.87, 35.41, 216.19),
        vector4(-1474.82, -633.75, 30.64, 33.81),
        vector4(-681.81, -378.59, 34.27, 338.15),
        vector4(-1169.42, -1474.56, 4.38, 303.66),
        vector4(-691.55, -670.43, 30.88, 0.05),
        vector4(-504.54, -670.74, 33.09, 359.55),
        vector4(-176.25, -819.69, 31.09, 249.15),
        vector4(356.8, -1067.24, 29.56, 358.5),
        vector4(788.07, -775.43, 26.42, 89.13),
    },

    dash = {
        vector4(114.39, -781.56, 31.41, 157.07),
        vector4(-110.73, -1686.69, 29.31, 232.34),
        vector4(-1026.65, -2736.74, 20.17, 331.14),
        vector4(-138.05, -1992.4, 22.81, 357.71),
        vector4(357.38, -1067.11, 29.56, 356.5),
        vector4(788.22, -775.09, 26.43, 88.7),
        vector4(956.88, 124.86, 80.99, 50.44),
        vector4(1279.02, 2693.0, 37.61, 180.19),
        vector4(1904.35, 3745.13, 32.37, 30.63),
        vector4(1681.28, 4828.05, 42.05, 93.05),
        vector4(1634.95, 6425.32, 27.92, 166.19),
        vector4(-216.92, 6175.77, 31.2, 226.68),
        vector4(-1533.09, 4994.2, 62.15, 228.94),
        vector4(-2241.53, 4311.27, 47.96, 240.63),
        vector4(-3125.69, 1125.79, 20.61, 264.6),
        vector4(-1730.9, -707.79, 10.09, 323.87),
        vector4(-1169.94, -1474.87, 4.38, 303.04),
        vector4(-557.27, -848.82, 27.67, 7.73),
        vector4(-249.28, -886.85, 30.6, 340.17),
        vector4(432.23, -641.2, 28.72, 92.29),
    },
}

-- Line keys the SecureEvents accept, built from the config so adding a line needs no code change.
Config.LineKeys = {}
for key in pairs(Config.Lines) do
    Config.LineKeys[#Config.LineKeys + 1] = key
end
table.sort(Config.LineKeys)

Lang.locale = Config.Locale or 'en'

Config = Config or {}
-- config.lua by Tnoxious https://github.com/Tnoxious -- WhipFX edition
-- Script changes are under GPLv3 License and not to be made for sale or locked in a paywall system
-- you are free to make any changes for your own server

Config.Locale = 'en'

---------- Main Settings -- the script ships with sensible defaults

Config.DebugZones = false        -- Draws the stop markers permanently while you lay out new stops

Config.BusHirePrice = 1          -- Cost of bus hire, covers both lines. Keep it under the bonus below.
Config.WorkClothing = false      -- true applies the worker clothing below while on shift, false leaves the outfit alone
Config.NpcPaysAllStops = true    -- true pays on pickup AND drop off, false pays on pickup only
Config.RandomStops = false       -- true picks the next stop at random from the line instead of running it in order

-- Payments. A new amount is rolled on the server for every payout, within these ranges.
Config.CityPay = { min = 60, max = 110 }    -- City Bus, per stop
Config.DashPay = { min = 80, max = 180 }    -- Dashound, per stop (longer runs)
Config.Bonus   = { min = 300, max = 600 }   -- Paid when the player brings the bus back to the depot

------- END MAIN ----------

-- Who may drive.
--   true  -- anyone walks up to a depot clerk and takes a bus out. No hiring, no clocking on.
--   false -- only drivers hired in /whip -> Economy -> Jobs may work, and they clock on at the clerk.
-- The job below is created either way, so flipping this is the only change needed.
Config.OpenToEveryone = true

-- The job WhipFX creates for this resource. Hire drivers in /whip -> Economy -> Jobs.
Config.JobKey = 'bus'
Config.JobName = 'Public Transport'
Config.JobRoles = {
    { name = 'Depot Manager', level = 100 },
    { name = 'Driver', level = 1 },
}

-- AntiGlitch/Bug fun
Config.TelePlayer = false  -- true sends a player who ditches the job bus somewhere far away. Just for a giggle.
Config.TelePlayerTo = vector4(3669.48, 5644.97, 12.43, 329.79) -- The island up north

-- Clothing is applied over the player's own components and put back exactly as it was when the shift ends.
-- Grab the codes from the character editor. Custom (non-freemode) peds are skipped.
local CityClothing = {
    male = {
        hat = 23,       -- -1 for none
        badge = 0,
        boots = 28,
        pants = 29,
        shirt = 6,
        vest = 0,
        torso = 40,     -- this is the jacket
        arms = 11,
    },
    female = {
        hat = 34,
        badge = 0,
        boots = 77,
        pants = 18,
        shirt = 25,
        vest = 0,
        torso = 20,
        arms = 5,
    },
}

local DashClothing = {
    male = {
        hat = 23,
        badge = 0,
        boots = 28,
        pants = 29,
        shirt = 6,
        vest = 0,
        torso = 40,
        arms = 11,
    },
    female = {
        hat = 34,
        badge = 0,
        boots = 77,
        pants = 18,
        shirt = 25,
        vest = 0,
        torso = 20,
        arms = 5,
    },
}

-- The two lines. Add another one here and it works with no code changes:
-- give it a stops list in config/locations.lua under the same key.
Config.Lines = {
    city = {
        label = 'City Bus Job',
        depotName = 'city.depot',          -- locale key for the blip
        platePrefix = 'city.plate',        -- locale key for the plate
        blip = { sprite = 513, colour = 47, scale = 0.6 },

        depot = vector4(445.59, -588.06, 28.51, 269.4),  -- where the bus spawns and is parked up again
        clerk = {
            model = 'a_m_m_tourist_01',                  -- see https://docs.fivem.net/docs/game-references/ped-models/
            scenario = 'WORLD_HUMAN_AA_SMOKE',           -- see https://wiki.rage.mp/index.php?title=Scenarios
            coords = vector4(446.03, -594.65, 28.49, 2.11),
        },

        vehicles = { 'bus', 'bsbuss' },                  -- one option on the clerk per model
        pay = 'CityPay',
        clothing = CityClothing,
    },

    dash = {
        label = 'Dashound Job',
        depotName = 'dash.depot',
        platePrefix = 'dash.plate',
        blip = { sprite = 513, colour = 47, scale = 0.6 },

        depot = vector4(473.52, -589.67, 28.5, 172.63),
        clerk = {
            model = 'a_m_y_business_02',
            scenario = 'WORLD_HUMAN_AA_COFFEE',
            coords = vector4(478.55, -580.49, 28.49, 76.59),
        },

        vehicles = { 'coach' },
        pay = 'DashPay',
        clothing = DashClothing,
    },
}

-- Preset peds for the bus stops. Leave as is for stable running.
Config.NpcSkins = {
    [1] = {
        'a_f_m_skidrow_01',
        'a_f_m_soucentmc_01',
        'a_f_m_soucent_01',
        'a_f_m_soucent_02',
        'a_f_m_tourist_01',
        'a_f_m_trampbeac_01',
        'a_f_m_tramp_01',
        'a_f_o_genstreet_01',
        'a_f_o_indian_01',
        'a_f_o_ktown_01',
        'a_f_o_salton_01',
        'a_f_o_soucent_01',
        'a_f_o_soucent_02',
        'a_f_y_beach_01',
        'a_f_y_bevhills_01',
        'a_f_y_bevhills_02',
        'a_f_y_bevhills_03',
        'a_f_y_bevhills_04',
        'a_f_y_business_01',
        'a_f_y_business_02',
        'a_f_y_business_03',
        'a_f_y_business_04',
        'a_f_y_eastsa_01',
        'a_f_y_eastsa_02',
        'a_f_y_eastsa_03',
        'a_f_y_epsilon_01',
        'a_f_y_fitness_01',
        'a_f_y_fitness_02',
        'a_f_y_genhot_01',
        'a_f_y_golfer_01',
        'a_f_y_hiker_01',
        'a_f_y_hipster_01',
        'a_f_y_hipster_02',
        'a_f_y_hipster_03',
        'a_f_y_hipster_04',
        'a_f_y_indian_01',
        'a_f_y_juggalo_01',
        'a_f_y_runner_01',
        'a_f_y_rurmeth_01',
        'a_f_y_scdressy_01',
        'a_f_y_skater_01',
        'a_f_y_soucent_01',
        'a_f_y_soucent_02',
        'a_f_y_soucent_03',
        'a_f_y_tennis_01',
        'a_f_y_tourist_01',
        'a_f_y_tourist_02',
        'a_f_y_vinewood_01',
        'a_f_y_vinewood_02',
        'a_f_y_vinewood_03',
        'a_f_y_vinewood_04',
        'a_f_y_yoga_01',
        'g_f_y_ballas_01',
    },
    [2] = {
        'ig_barry',
        'ig_bestmen',
        'ig_beverly',
        'ig_car3guy1',
        'ig_car3guy2',
        'ig_casey',
        'ig_chef',
        'ig_chengsr',
        'ig_chrisformage',
        'ig_clay',
        'ig_claypain',
        'ig_cletus',
        'ig_dale',
        'ig_dreyfuss',
        'ig_fbisuit_01',
        'ig_floyd',
        'ig_groom',
        'ig_hao',
        'ig_hunter',
        'csb_prolsec',
        'ig_joeminuteman',
        'ig_josef',
        'ig_josh',
        'ig_lamardavis',
        'ig_lazlow',
        'ig_lestercrest',
        'ig_lifeinvad_01',
        'ig_lifeinvad_02',
        'ig_manuel',
        'ig_milton',
        'ig_mrk',
        'ig_nervousron',
        'ig_nigel',
        'ig_old_man1a',
        'ig_old_man2',
        'ig_oneil',
        'ig_orleans',
        'ig_ortega',
        'ig_paper',
        'ig_priest',
        'ig_prolsec_02',
        'ig_ramp_gang',
        'ig_ramp_hic',
        'ig_ramp_hipster',
        'ig_ramp_mex',
        'ig_roccopelosi',
        'ig_russiandrunk',
        'ig_siemonyetarian',
        'ig_solomon',
        'ig_stevehains',
        'ig_stretch',
        'ig_talina',
        'ig_taocheng',
        'ig_taostranslator',
        'ig_tenniscoach',
        'ig_terry',
        'ig_tomepsilon',
        'ig_tylerdix',
        'ig_wade',
        'ig_zimbor',
        's_m_m_paramedic_01',
        'a_m_m_afriamer_01',
        'a_m_m_beach_01',
        'a_m_m_beach_02',
        'a_m_m_bevhills_01',
        'a_m_m_bevhills_02',
        'a_m_m_business_01',
        'a_m_m_eastsa_01',
        'a_m_m_eastsa_02',
        'a_m_m_farmer_01',
        'a_m_m_fatlatin_01',
        'a_m_m_genfat_01',
        'a_m_m_genfat_02',
        'a_m_m_golfer_01',
        'a_m_m_hasjew_01',
        'a_m_m_hillbilly_01',
        'a_m_m_hillbilly_02',
        'a_m_m_indian_01',
        'a_m_m_ktown_01',
        'a_m_m_malibu_01',
        'a_m_m_mexcntry_01',
        'a_m_m_mexlabor_01',
        'a_m_m_og_boss_01',
        'a_m_m_paparazzi_01',
        'a_m_m_polynesian_01',
        'a_m_m_prolhost_01',
        'a_m_m_rurmeth_01',
    }
}

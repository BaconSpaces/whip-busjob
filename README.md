![whip-busjob](https://github.com/Tnoxious/noxmz-busjobs/assets/167952403/4e61e2de-2cbf-4d97-8af0-b95a97979640)

# whip-busjob

Two bus jobs in one resource for **[WhipFX](https://whipfx.net/docs/)** — a City Bus line around
Los Santos and a Dashound coach line out through the towns. Pick up passengers, drop them at the
next stop, get paid per fare, bring the bus home for a bonus.

Open to every player by default. No hiring, no clocking on, no dependencies beyond `whip_core`.

> Originally a remake of qb-busjob by [Tnoxious](https://github.com/Tnoxious).
> Version 2 is a full port to WhipFX — every framework call now goes through `whip_core`.

---

## Features

- **Two lines in one script.** City Bus (`bus`, `bsbuss`) and Dashound coach (`coach`), each with
  its own depot, clerk, stops and pay.
- **Anyone can drive.** Walk up, take a bus, start earning. One config switch locks it to drivers
  you hire instead.
- **Work clothes**, optional, per line and per gender. Snapshotted and put back exactly as they were
  when the shift ends.
- **Random fares**, rolled on the server for every single payout.
- **Add a whole new line from config** — no code changes.
- **Streamed map props**: extra bus stops and depot scenery (`stream/`).
- **Server-authoritative.** Every message from the client is a `SecureEvent` with typed parameters,
  a rate limit and a distance check. Money moves with `ChargePlayer` / `PayPlayer`, so it all lands
  on WHIP's activity log.

## Requirements

| | |
| --- | --- |
| **WhipFX** | `whip_core` (plus `oxmysql`, which WHIP needs anyway) |
| Anything else | **No.** |

No target, menu, notification, text-UI, fuel, keys, zone or clothing resource is needed —
`whip_core` provides all of it.

## Install

1. Put the folder in your resources.
2. Add this to `server.cfg`, **below** WHIP's own `ensure` lines:

   ```cfg
   ensure whip-busjob
   ```

3. Start the server. The resource creates its job and both depot clerks by itself — there is no
   jobs file to edit. You should see:

   ```
   whip-busjob started successfully!
   ```

4. Open `config/config.lua` and change what you like.

Already running? `refresh` then `ensure whip-busjob`. After a config edit, `restart whip-busjob`.

## Playing it

Both depots sit just east of Mission Row, and show a blip once the resource is running.

| Line | Clerk | Bus spawns / parks |
| --- | --- | --- |
| CityBus | `445.56, -594.92` | `445.59, -588.06` |
| Dashound | `479.12, -580.47` | `473.52, -589.67` |

1. Walk up to a clerk and press `E` → **Take out a Bus**. The hire price comes off, a temporary bus
   spawns with the key already in the ignition, and you're put at the wheel.
2. A passenger appears at a stop with a GPS route. Pull up and press `E` → **fare paid**.
3. The next stop routes. Pull up and press `E` to drop them off → **fare paid again**
   (with `Config.NpcPaysAllStops`).
4. Drive back to the depot and press `E` → **bonus paid**, bus removed.

Abandon the bus for 20 seconds and you lose the shift and the bus — plus a trip to the middle of
nowhere if `Config.TelePlayer` is on.

## Configuring

| File | What's in it |
| --- | --- |
| `config/config.lua` | Who may drive, pay, hire price, work clothes, and the lines themselves |
| `config/locations.lua` | The bus stops of each line |
| `locales/en.lua` | Every piece of text, the plate prefixes and the depot names |

### The settings

| Setting | Default | What it does |
| --- | --- | --- |
| `Config.OpenToEveryone` | `true` | `true`: any player can take a bus out. `false`: hired drivers only, who clock on at the clerk |
| `Config.BusHirePrice` | `1` | Charged when a bus is signed out. Keep it under the bonus |
| `Config.WorkClothing` | `false` | `true` puts the line's uniform on for the shift |
| `Config.NpcPaysAllStops` | `true` | `true` pays on pickup **and** drop-off; `false` on pickup only |
| `Config.RandomStops` | `false` | `true` picks the next stop at random instead of running the line in order |
| `Config.CityPay` | `60–110` | City Bus fare range, per stop |
| `Config.DashPay` | `80–180` | Dashound fare range, per stop |
| `Config.Bonus` | `300–600` | Paid for bringing the bus back |
| `Config.TelePlayer` | `false` | `true` exiles a driver who ditches the bus |
| `Config.DebugZones` | `false` | Draws a marker on every nearby stop, for laying out new ones |
| `Config.Locale` | `'en'` | Which `Locales` table to read |

### Adding a line

Add an entry to `Config.Lines` and a stop list under the **same key** in `Config.Stops`:

```lua
-- config/config.lua
Config.Lines.airport = {
    label       = 'Airport Shuttle',
    depotName   = 'airport.depot',    -- a locale key
    platePrefix = 'airport.plate',    -- a locale key
    blip        = { sprite = 513, colour = 47, scale = 0.6 },

    depot = vector4(-1037.0, -2730.0, 20.2, 240.0),
    clerk = {
        model    = 'a_m_m_tourist_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        coords   = vector4(-1041.0, -2735.0, 20.2, 60.0),
    },

    vehicles = { 'airbus' },          -- one clerk option per model
    pay      = 'CityPay',             -- names a pay range above
    clothing = CityClothing,
}

-- config/locations.lua
Config.Stops.airport = { vector4(...), vector4(...) }
```

Both the client and the server read the config, so that is the whole job. Add the two locale keys to
`locales/en.lua` and restart.

### New coordinates

Stand on the spot in game, open `/w` → **Coords** and press `G` to copy
`vector4(x, y, z, heading)`.

### Hired drivers only

Set `Config.OpenToEveryone = false`. The clerk then offers **Clock On** and **Clock Off**, and only
hired drivers can work — the server re-checks duty on every fare, not just the prompt. Hire them in
`/whip` → **Economy** → **Jobs** → **Public Transport** → **Change**, or with `HirePlayer` from your
own code.

> **Caveat:** WHIP's `Config.JobOneCharacterPerAccount` is on by default, so it refuses hiring a
> character whose account already has one at the job — a player's alt can't also be a driver.

### Translating

Add a file to `locales/` with `Locales['de'] = { ... }`, mirroring `en.lua`, and point
`Config.Locale` at it. Missing keys fall back to English.

## Troubleshooting

| Symptom | Where to look |
| --- | --- |
| A prompt won't fire, or a fare won't pay | `/whip` → **System** → **Monitor** lists every `whip-busjob:*` call, accepted or refused, with the reason |
| Red lines on start instead of "started successfully" | The console text names what failed — usually a clerk ped that couldn't spawn |
| No clerk at a depot | Check the ped model in `Config.Lines[...].clerk.model` exists on your build |
| Payments missing | The player's activity log shows the hire, each fare and the bonus under this resource's name |

## How it fits together

```
fxmanifest.lua        whip_core dependency, satellite helper, this_is_a_map for stream/
shared/locale.lua     a 25-line Lang:t() with no framework behind it
locales/en.lua        all text
config/config.lua     settings and the lines
config/locations.lua  the stops, and the line keys the SecureEvents accept
client/busjob.lua     one controller driving every line: prompts, blips, passengers, clothing
server/main.lua       the job, the clerks, and four checked endpoints
stream/               extra bus stops and depot props (.ymap)
```

The server owns everything that matters:

| Endpoint | Checks |
| --- | --- |
| `whip-busjob:takeVehicle` | `SecureCallback` — near the depot, may work, no bus already out, model belongs to the line. Charges, spawns, refunds on any failure |
| `whip-busjob:stopPay` | `SecureEvent` — near that stop, may work, driving the bus they signed out |
| `whip-busjob:finishShift` | `SecureEvent` — near the depot, driving their own bus |
| `whip-busjob:cancelShift` | `SecureEvent` — ends a ditched shift and removes the bus |

A `.luarc.json` is included: open the folder in VS Code with the sumneko **Lua** extension and every
`whip_core` export shows its parameters and return values.

## Licence

GPLv3 — see `LICENSE`. Not to be sold or put behind a paywall. Change it all you like for your own
server.

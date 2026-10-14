# Feed or Flee

An ocean survival game for Roblox. You start as a shrimp and eat, survive, and evolve your way up the food chain to apex predator. Inspired by Deeeep.io and built in Roblox Studio with Luau.

> **Status: in development.** The creature system and world generation are built. Eating and evolution gameplay are next.

## What's built so far

- **15 creatures across 5 tiers**, from Shrimp, Minnow, and Krill up to Great White, Orca, and Giant Squid. Each one has its own health, speed, damage, XP needed to evolve, and home biomes.
- **Food chain and evolution rules.** Helper functions return which creatures you can evolve into next and whether one creature can eat another.
- **Creatures built in code.** Each creature's model is assembled from parts at runtime (body, tail, dorsal fin, eyes, and a glowing lure for the Anglerfish) and replaces the default Roblox character when you spawn.
- **Five biomes:** Ocean, Arctic, Swamp, Deep, and Sky. Swimming into a biome fades in its own fog color and visibility.
- **Procedural world generation.** Terrain is painted in layers (sky, surface biomes, mid-water, a rock ceiling, and the deep abyss) with noise-based seafloors, 8 islands, and 6 tunnels carved through the rock into the abyss.
- **Points of interest:** coral reef clusters, mangrove groves, shipwrecks with treasure chests, multi-room caves, and 930 glowing food orbs worth different amounts of XP. Hiding spots, treasure, caves, and food are tagged with CollectionService so gameplay code can find them.

## How the code is organized

```
src/
├── ReplicatedStorage/
│   ├── CreatureData.luau              # every creature's stats, tier, and biomes in one table
│   └── CreatureBuilder.luau           # builds a creature's model from its data
└── ServerScriptService/
    ├── CreatureSpawner.server.luau    # spawns players as creatures and respawns them
    ├── BiomeAtmosphere.server.luau    # fog changes between biomes
    ├── TerrainBuilder.server.luau     # current world generator (vertical layers)
    ├── WorldGridBuilder.server.luau   # first-version layout: five biome zones side by side
    ├── SeafloorBuilder.server.luau    # first-version seafloor
    ├── WorldDecorator.server.luau     # reefs, wrecks, caves, flora, and food orbs
    └── WorldCleanup.server.luau       # one-time tool that clears the old world (disabled)
```

## Design decisions

- **One source of truth for creatures.** All creature stats live in a single ModuleScript in ReplicatedStorage that server and client code can both read, so balancing the game means editing one table.
- **Chunked terrain work.** Roblox limits how many voxels one terrain call can fill, so large fills and clears are split into 500-stud chunks.
- **Run-once generators.** World-building scripts generate their part of the world and then switch themselves off.
- **Tags instead of hard-coded lists.** Hiding spots, treasure chests, caves, and food are found through CollectionService tags.

## Next up

- Eating: swim into food orbs and smaller creatures to earn XP
- Evolution: pick your next creature when you reach the XP threshold
- Habitat damage and breathing rules (already defined for each creature)
- Move biome fog to the client so each player sees their own biome's fog
- Finish moving the world to the new vertical layout

## Running it

This repo uses the [Rojo](https://rojo.space) project layout. With Rojo installed, run `rojo serve` in this folder and connect from the Rojo plugin in Roblox Studio.

## Built with

Luau, Roblox Studio, Roblox Terrain API, CollectionService, TweenService, Rojo

---

Built by Miles Pierce · [github.com/Milpierce](https://github.com/Milpierce)

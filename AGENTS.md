# Godot Game Development Rules

Target: **Godot 4.x**

Follow installed Godot skills for engine APIs, GDScript, shaders, C#, and GDExtension.

The project must remain **human-editable, inspectable, tunable, and maintainable in Godot**.

## Architecture

Prefer:
- composition over inheritance
- reusable scenes and components
- Resources for game data/configuration
- signals for decoupled communication
- explicit state machines for complex behavior
- Inspector-editable parameters
- `.tscn` files for persistent structure

Avoid:
- monolithic scripts
- god objects
- large hardcoded dictionaries
- excessive Autoload usage
- long-distance node paths
- procedural construction of persistent scene trees

Each scene/script should have one clear responsibility.

## Before Implementing

For non-trivial features, inspect existing scenes, scripts, Resources, Autoloads, signals, and ownership first.

Determine:
1. required scenes/components
2. configurable Resources
3. signals and state ownership
4. Inspector parameters
5. save/load impact
6. runtime and visual test needs

Do not immediately implement a large feature inside one script.

## Components

Do not let one player/enemy script own movement, combat, health, inventory, animation, audio, UI, and state logic.

Prefer reusable components such as:

```text
MovementComponent
HealthComponent
CombatComponent
HitboxComponent
InteractionComponent
StateMachine
```

A gameplay script approaching **300 lines** should trigger an architecture review.

Split by responsibility, not merely by line count.

## Scene-First

Persistent gameplay and UI structure should normally live in `.tscn` files.

Do not build permanent scene trees with large amounts of `Node.new()` code when they can be authored in Godot.

Runtime-created nodes are appropriate for dynamic objects such as projectiles, enemies, loot, temporary effects, pooling, or procedural content.

## Inspector and Resources

Values likely to require tuning should not be unnecessarily hardcoded.

Use `@export`, `@export_range`, `@export_group`, and custom Resources.

Typical tunable values include speed, acceleration, damage, health, cooldowns, ranges, spawn rates, camera settings, timing, and effect intensity.

Use custom Resources for reusable data such as:

```text
CharacterStats
WeaponData
EnemyData
AbilityData
ItemData
LevelConfig
```

Code defines behavior. Resources define tunable content.

## State and Communication

Simple behavior may use enums.

Complex behavior should use explicit state objects or child nodes.

Use direct calls inside tightly owned systems and signals for loosely coupled communication.

Avoid unnecessary cross-scene dependencies.

Autoloads should be limited to genuinely global systems such as GameManager, SaveManager, AudioManager, SceneManager, or EventBus.

Never use Autoloads as dumping grounds or store scene-specific node references in them.

## Runtime Verification

After meaningful gameplay, scene, UI, shader, input, physics, or Resource changes:

1. run the affected project or scene
2. check parser/runtime errors
3. check missing resources and invalid node paths
4. exercise the changed behavior
5. inspect the rendered result
6. fix regressions

Do not declare success merely because code parses.

Use Godot CLI validation when available:

```bash
godot --headless --path . --editor --quit
```

Prefer project-provided validation or smoke-test scripts when present.

## Visual QA

For UI, gameplay, animation, camera, shader, or visual changes, visually inspect runtime behavior whenever tools allow it.

Preferred loop:

```text
Implement → Run → Play → Observe → Fix → Repeat
```

Use computer interaction when available to launch scenes, press buttons, move characters, trigger mechanics, and inspect results.

Static code inspection alone is not sufficient for runtime-visible problems.

## Generated Assets

Place AI-generated assets in `assets/generated/` first.

Do not overwrite approved production assets unless explicitly required.

Generated assets must follow project art direction and be visually verified in Godot.

## Human Editability

Prefer visible scene hierarchies, editable `.tscn` files, reusable `.tres` Resources, exported properties, focused scripts, explicit ownership, and predictable signal flow.

Avoid clever but opaque architectures that are difficult to edit manually.

## Definition of Done

A feature is complete only when:
- responsibilities are reasonably separated
- tunable values are exposed appropriately
- reusable data uses Resources where appropriate
- persistent structure lives in scenes
- parser/runtime errors are absent
- affected behavior has been exercised
- visual output has been inspected when relevant
- the result remains easy for a human to edit in Godot

When fewer files conflict with maintainability, prefer maintainability.
# Forest v2 generated assets

Generated with the built-in image_gen tool. Original source artwork is preserved in assets/pictures. These files are for the current project.

- terrain.png: source terrain strip, cropped non-destructively via terrain_skin.tres. A is the left cap; only B repeats; C is the right cap. Deep soil is filled below the strip. Short or partial widths crop the source instead of stretching a whole island.
- tree_clean.png: selected complete tree with transparent alpha, used by editable Sprite2D nodes in scenes/props/forest_decor.tscn. tree.png is the initial generation retained for comparison.
- seija_sheet.png: 4 columns by 2 rows; idle 0–1, rise 2, fall 3, run 4–7. PlayerSprite owns animation only. Per-frame foot baselines compensate for the generated sheet padding. Nearest filtering is set on scene nodes.
- terrain_skin.tres: edit source rectangles, repeat width, grass offset, platform depth and soil color in the Inspector.

No save format changes. Character collisions, movement speeds and combat rules are unchanged.

## 在 Godot 中调整

- 地形：打开 `terrain_skin.tres`，调整 A/B/C 原图选区、重复宽度、草沿偏移和平台厚度。只重复 B；不足一个 B 的尾段裁切绘制。A/C 各绘制一次。
- 树木：打开 `scenes/props/forest_decor.tscn`，直接移动、缩放或调色各个 Sprite2D。每棵树使用整张透明图片。
- 角色：打开 `scenes/player/player.tscn` 的 Graphics，调整动画速率和 Foot Rows。脚底偏移在正常和倒置状态下均对齐碰撞面。

## 验证记录

Godot 4.7.2 项目导入与解析通过。现有 `tests/run_tests.tscn` 的 58 项检查全部通过。`tests/visual_gallery.tscn` 已实际渲染庭院、战斗、倒置、商店、Boss 和胜利画面。`tests/texture_gallery.tscn` 自动输入并截取待机、左右跑动、起跳、下落、落地和倒置跑动画面，已逐张检查。运行日志与截图位于 `.godot/qa-texture-*.log` 和 `.godot/qa/`（Godot 缓存，不纳入版本管理）。

## Generation prompts

### Terrain
Use case: stylized-concept. Asset type: production pixel-art terrain texture for a 2D side-scrolling moonlit Japanese forest action platformer. Generate a SINGLE continuous horizontal moss-covered soil platform, wide 3:1 canvas. True transparent background. The platform occupies the FULL canvas width edge to edge with no margins and its flat walkable grass top starts exactly at the top canvas edge. Front orthographic view, NOT isometric. Design for THREE-SLICE use: left one-third is left outer cliff cap A, middle one-third is seamless horizontally repeatable interior B, right one-third is right outer cliff cap C. At the internal one-third and two-third boundaries all layers align seamlessly. Grass is a shallow continuous strip across entire width, sage green and pale jade highlights, muted moss greens. Soil underneath is deep blue-charcoal with restrained slate rocks and thin ochre roots. NO vertical cliff edge, gap, shadow notch or island silhouette in the middle third. Interior left and right boundaries must match for B-B repetition. Bottom edge should be solid dark soil, no floating-island rounded bottom or transparent holes. Left and right exterior contours may be slightly rocky but restrained. Clear hand placed square pixel clusters, 16-bit game style, limited palette, no gradients, no blur, no antialias, no outline framing the central segment. No text, letters, grid, dividers, captions or extra tiles. Render as if drawn at 192x64 logical pixels enlarged with nearest-neighbor. Landscape 3:1.

### Tree
Use case: stylized-concept. Asset type: a complete tree sprite for a 2D side-scrolling moonlit Japanese forest pixel-art action game. One single elegant old forest tree, entire crown trunk branches and roots visible and connected naturally, upright front orthographic view. Full tree centered with 5% transparent padding on all sides, canvas portrait 2:3. Broad layered asymmetrical crown, spreading branches, slightly twisting trunk, roots rest on one horizontal ground baseline. Muted jade and teal foliage with sparse sage moonlit upper edges; blue charcoal shadow leaves; muted violet brown bark with cool gray highlights. Beautiful readable silhouette with a few transparent gaps between leaf masses. Pixel art 16-bit style with deliberate crisp square clusters, as if drawn on a 128 by 192 pixel canvas and nearest-neighbor enlarged. Limited palette, flat discrete shading, no gradients, no painted blur, no smooth outlines, no antialias. Real transparent background including holes among branches. No scenery, ground slab, grass patch, sky, moon, text, grid or sprite-sheet divisions. This is ONE complete ready-to-use tree image; do not split canopy from trunk.

### Tree cleanup
Use case: background-extraction. Edit target: attached tree sprite. Keep exactly the same tree silhouette, branches, roots, colors and pixel art details. Remove ALL the colored fuzzy glow and haze behind and around the tree. Tree interior must be fully opaque (alpha 255); everything outside the actual sharp pixel silhouette and all holes between the branches must be fully transparent (alpha 0). Binary alpha only. No semi-transparent pixels. No shadow, no lighting halo, no atmospheric aura. Keep complete tree in frame with margin, do not crop. The final result must be a clean game sprite cutout on actual transparent background, with hard pixel stepped edges. Do not change the tree design. No black backdrop or checkerboard painted into image.

### Character
Use case: stylized-concept. Asset type: production character animation sprite sheet for 2D side-scrolling pixel-art platformer. Reference image is existing game's Kijin Seija character, use for identity and costume reference. Generate a clean readable faithful pixel-art upgrade of this character: short black hair with a distinct red streak and white fringe, two short pale curved horns, red eyes, white short sleeved blouse with dark neck ribbon, black skirt with red triangular zigzag hem, red shoes. Side view facing RIGHT in all frames. Full body youthful adult heroine. No weapon. True transparent background. EXACTLY EIGHT equally sized SQUARE cells in a 4 column by 2 row grid, no gutters, no labels, no visible grid. Wide 2:1 canvas. Row 1 frames: idle neutral, idle breathing, jumping rising with bent knees, falling with feet downward. Row 2: four consecutive running cycle poses, legs and arms alternate, feet contact then passing then opposite contact then passing. Keep identical design proportions and size, central torso x position consistent per cell, aligned ground baseline at 88% of cell height for grounded poses; all sprites fit their cells with generous empty margin. Hard crisp pixel clusters drawn as 48x48 logical pixels PER CELL then nearest neighbor enlarged, limited 16-bit palette, clear face and silhouette at game size, no blur, no gradients, no lighting halo or glows, no shadows outside the sprite. Opaque character and fully transparent empty space. Do not add backgrounds, scenery, dividers, text, captions, weapons, additional characters, or extra frames.

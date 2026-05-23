Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$levels = @(
    @{
        Key = "factory"
        Scene = "World/Factory/factory_level_1.tscn"
        Far = "Color(0.09, 0.11, 0.10, 0.34)"
        Near = "Color(0.18, 0.19, 0.17, 0.42)"
        FloorA = "Color(0.20, 0.21, 0.19, 0.26)"
        FloorB = "Color(0.35, 0.31, 0.22, 0.22)"
        Accent = "Color(0.62, 0.31, 0.18, 0.40)"
    },
    @{
        Key = "stadium"
        Scene = "World/Stadium/stadium_level_2.tscn"
        Far = "Color(0.06, 0.08, 0.11, 0.34)"
        Near = "Color(0.18, 0.19, 0.18, 0.42)"
        FloorA = "Color(0.15, 0.23, 0.18, 0.24)"
        FloorB = "Color(0.40, 0.36, 0.22, 0.20)"
        Accent = "Color(0.62, 0.14, 0.10, 0.34)"
    },
    @{
        Key = "bridge"
        Scene = "World/Bridge/bridge_level_3.tscn"
        Far = "Color(0.05, 0.08, 0.11, 0.36)"
        Near = "Color(0.19, 0.20, 0.19, 0.42)"
        FloorA = "Color(0.18, 0.19, 0.20, 0.24)"
        FloorB = "Color(0.44, 0.38, 0.24, 0.20)"
        Accent = "Color(0.68, 0.55, 0.24, 0.34)"
    },
    @{
        Key = "metro"
        Scene = "World/Metro/metro_level_4.tscn"
        Far = "Color(0.04, 0.05, 0.07, 0.38)"
        Near = "Color(0.20, 0.19, 0.16, 0.40)"
        FloorA = "Color(0.18, 0.18, 0.18, 0.24)"
        FloorB = "Color(0.48, 0.42, 0.26, 0.18)"
        Accent = "Color(0.66, 0.56, 0.22, 0.32)"
    },
    @{
        Key = "forest_camp"
        Scene = "World/ForestCamp/forest_camp_level_5.tscn"
        Far = "Color(0.05, 0.08, 0.05, 0.38)"
        Near = "Color(0.14, 0.17, 0.12, 0.42)"
        FloorA = "Color(0.18, 0.20, 0.14, 0.24)"
        FloorB = "Color(0.42, 0.31, 0.20, 0.20)"
        Accent = "Color(0.68, 0.26, 0.14, 0.30)"
    }
)

function Get-StableHash([string]$text) {
    [int64]$hash = 17
    foreach ($ch in $text.ToCharArray()) {
        $hash = (($hash * 31) + [int][char]$ch) % 2147483647
    }
    return [int]$hash
}

function Get-Zones([string]$sceneText) {
    $matches = [regex]::Matches($sceneText, '\[node name="(Zone_\d+_[^"]+)" type="Node2D" parent="Setpieces"[^\]]*\]')
    $zones = @()
    for ($i = 0; $i -lt $matches.Count; $i++) {
        $name = $matches[$i].Groups[1].Value
        $start = $matches[$i].Index
        $end = if ($i -lt $matches.Count - 1) { $matches[$i + 1].Index } else {
            $route = $sceneText.IndexOf('[node name="RouteLabels"', $start)
            if ($route -gt 0) { $route } else { $sceneText.Length }
        }
        $block = $sceneText.Substring($start, $end - $start)
        $xs = @()
        foreach ($m in [regex]::Matches($block, 'offset_(?:left|right) = ([\d\.-]+)')) {
            $xs += [double]$m.Groups[1].Value
        }
        $min = if ($xs.Count -gt 0) { [Math]::Floor(($xs | Measure-Object -Minimum).Minimum) } else { 0 }
        $max = if ($xs.Count -gt 0) { [Math]::Ceiling(($xs | Measure-Object -Maximum).Maximum) } else { 512 }
        $drawX = [int]($min - 96)
        $width = [int]([Math]::Max(640, ($max - $min + 192)))
        $zones += [pscustomobject]@{
            Name = $name
            X = $drawX
            Right = $drawX + $width
            Width = $width
            Hash = Get-StableHash $name
        }
    }
    return $zones
}

function Rect-Node([string]$name, [string]$parent, [double]$left, [double]$top, [double]$right, [double]$bottom, [string]$color, [string]$nl) {
    return @(
        "",
        "[node name=`"$name`" type=`"ColorRect`" parent=`"$parent`"]",
        "offset_left = $left",
        "offset_top = $top",
        "offset_right = $right",
        "offset_bottom = $bottom",
        "color = $color"
    ) -join $nl
}

function Build-SeamlessSceneBlock([hashtable]$level, $zone, [string]$nl) {
    $parent = "Setpieces/$($zone.Name)"
    $layerParent = "$parent/SeamlessSceneLayers"
    $x = $zone.X
    $r = $zone.Right
    $w = $zone.Width
    $h = $zone.Hash
    $motifA = $x + 96 + ($h % 180)
    $motifB = $x + [Math]::Max(320, [int]($w * 0.48)) + ($h % 120)
    $motifC = $x + [Math]::Max(520, [int]($w * 0.78)) - ($h % 90)

    $lines = @(
        "",
        "[node name=`"SeamlessSceneLayers`" type=`"Node2D`" parent=`"$parent`"]",
        "z_index = -2",
        ""
    )

    $lines += Rect-Node "FarBackdropBand" $layerParent $x 24 $r 84 $level.Far $nl
    $lines += Rect-Node "FarSilhouetteA" $layerParent $motifA 48 ($motifA + 92) 128 $level.Far $nl
    $lines += Rect-Node "FarSilhouetteB" $layerParent $motifB 58 ($motifB + 140) 132 $level.Far $nl
    $lines += Rect-Node "NearSceneBand" $layerParent $x 86 $r 151 $level.Near $nl
    $lines += Rect-Node "NearLandmarkA" $layerParent ($motifA + 36) 104 ($motifA + 188) 148 $level.Near $nl
    $lines += Rect-Node "NearLandmarkB" $layerParent ($motifC - 180) 98 ($motifC + 24) 148 $level.Near $nl
    $lines += Rect-Node "FloorFarDepthWash" $layerParent $x 154 $r 181 $level.FloorA $nl
    $lines += Rect-Node "FloorCenterDepthWash" $layerParent $x 181 $r 214 $level.FloorA $nl
    $lines += Rect-Node "FloorNearDepthWash" $layerParent $x 214 $r 258 $level.FloorA $nl
    $lines += Rect-Node "DepthSeamA" $layerParent $x 180 $r 182 $level.FloorB $nl
    $lines += Rect-Node "DepthSeamB" $layerParent $x 213 $r 215 $level.FloorB $nl
    $lines += Rect-Node "SceneAccentA" $layerParent ($motifA + 12) 150 ($motifA + 116) 154 $level.Accent $nl
    $lines += Rect-Node "SceneAccentB" $layerParent ($motifB + 28) 216 ($motifB + 148) 220 $level.Accent $nl

    return ($lines -join $nl)
}

foreach ($level in $levels) {
    $scenePath = Join-Path $root $level.Scene
    $text = Get-Content $scenePath -Raw -Encoding UTF8
    $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }

    $text = [regex]::Replace($text, '(?ms)\r?\n\[node name="SetpieceTextureLayers" type="Node2D" parent="Setpieces/Zone_\d+_[^"]+"[^\]]*\].*?(?=\r?\n\[node name="(?!FarParallaxTexture|NearBackgroundTexture|FloorPlayfieldTexture))', '')
    $text = [regex]::Replace($text, '(?ms)\r?\n\[node name="SeamlessSceneLayers" type="Node2D" parent="Setpieces/Zone_\d+_[^"]+"[^\]]*\].*?(?=\r?\n\[node name="(?!FarBackdropBand|FarSilhouetteA|FarSilhouetteB|NearSceneBand|NearLandmarkA|NearLandmarkB|FloorFarDepthWash|FloorCenterDepthWash|FloorNearDepthWash|DepthSeamA|DepthSeamB|SceneAccentA|SceneAccentB))', '')
    $text = [regex]::Replace($text, '(?m)^\[ext_resource[^\]]*path="res://assets/incoming/[^"]+/textures/[^"]+_seamless_01\.png"[^\]]*id="(?:tex|stx)_[^"]+"[^\]]*\]\r?\n?', '')

    $zones = Get-Zones $text
    foreach ($zone in $zones) {
        $block = Build-SeamlessSceneBlock $level $zone $nl
        $zoneNamePattern = [regex]::Escape($zone.Name)
        $pattern = '(?m)^\[node name="' + $zoneNamePattern + '" type="Node2D" parent="Setpieces"[^\n]*\]'
        $match = [regex]::Match($text, $pattern)
        if (-not $match.Success) {
            throw "Could not find zone $($zone.Name) in $($level.Scene)"
        }
        $text = $text.Insert($match.Index + $match.Length, $nl + $block)
    }

    $resourceCount = [regex]::Matches($text, '(?m)^\[(?:ext_resource|sub_resource) ').Count
    $newSteps = $resourceCount + 1
    if ([regex]::IsMatch($text, '^\[gd_scene load_steps=\d+ format=3')) {
        $text = [regex]::Replace($text, '^\[gd_scene load_steps=\d+ format=3', "[gd_scene load_steps=$newSteps format=3", 1)
    } else {
        $text = [regex]::Replace($text, '^\[gd_scene format=3', "[gd_scene load_steps=$newSteps format=3", 1)
    }

    [System.IO.File]::WriteAllText($scenePath, $text, $utf8NoBom)
}

$manifest = @(
    "# Setpiece Seamless Scene Manifest",
    "",
    "Generated from ``tools/generate_setpiece_seamless_scenes.ps1``.",
    "",
    "This replaces the failed generated PNG texture pass with editable Godot scene primitives.",
    "",
    "Rules:",
    "- Each setpiece gets one ``SeamlessSceneLayers`` node.",
    "- Layers are ColorRect scene geometry, not external seamless PNG textures.",
    "- Nodes sit at ``z_index = -2`` under setpiece props, enemies, player, and UI.",
    "- Floor washes preserve broad pseudo-depth bands and avoid actor-foot clutter.",
    "- No assets are promoted to ``assets/final/``."
)
[System.IO.File]::WriteAllText((Join-Path $root "assets/requests/setpiece_seamless_scene_manifest.md"), ($manifest -join "`r`n"), $utf8NoBom)

Write-Host "Generated seamless scene layers and removed failed setpiece texture wiring."

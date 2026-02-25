Add-Type -AssemblyName System.Drawing

function Draw-SeedVestIcon([int]$size, [string]$outputPath) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $bg = [System.Drawing.ColorTranslator]::FromHtml('#20A86E')
    $deepBlue = [System.Drawing.ColorTranslator]::FromHtml('#0C2B45')
    $brandGreen = [System.Drawing.ColorTranslator]::FromHtml('#137A4D')
    $leafGreen = [System.Drawing.ColorTranslator]::FromHtml('#0D6B44')
    $gold = [System.Drawing.ColorTranslator]::FromHtml('#E0D46A')

    $g.Clear($bg)

    $w = [double]$size
    $h = [double]$size
    $baseline = $h * 0.78

    $barWidth = $w * 0.11
    $gap = $w * 0.022
    $startX = $w * 0.17

    $bars = @(
        @{ x = $startX; y = $baseline - $h * 0.05; w = $barWidth * 0.8; h = $h * 0.05; c = $deepBlue },
        @{ x = $startX + ($barWidth + $gap) * 1; y = $baseline - $h * 0.12; w = $barWidth; h = $h * 0.12; c = $deepBlue },
        @{ x = $startX + ($barWidth + $gap) * 2; y = $baseline - $h * 0.20; w = $barWidth; h = $h * 0.20; c = $gold },
        @{ x = $startX + ($barWidth + $gap) * 3; y = $baseline - $h * 0.30; w = $barWidth; h = $h * 0.30; c = $brandGreen },
        @{ x = $startX + ($barWidth + $gap) * 4; y = $baseline - $h * 0.42; w = $barWidth; h = $h * 0.42; c = $deepBlue }
    )

    foreach ($b in $bars) {
        $brush = New-Object System.Drawing.SolidBrush($b.c)
        $g.FillRectangle($brush, [float]$b.x, [float]$b.y, [float]$b.w, [float]$b.h)
        $brush.Dispose()
    }

    $penGold = New-Object System.Drawing.Pen($gold, [float]($w * 0.045))
    $penGold.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penGold.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine(
        $penGold,
        [float]($startX + $w * 0.05), [float]($baseline - $h * 0.23),
        [float]($startX + $w * 0.24), [float]($baseline - $h * 0.43)
    )

    $penLeaf = New-Object System.Drawing.Pen($leafGreen, [float]($w * 0.04))
    $penLeaf.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penLeaf.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine(
        $penLeaf,
        [float]($w * 0.52), [float]($baseline - $h * 0.10),
        [float]($w * 0.52), [float]($baseline - $h * 0.36)
    )

    $leafRect = New-Object System.Drawing.RectangleF([float]($w * 0.34), [float]($baseline - $h * 0.46), [float]($w * 0.24), [float]($h * 0.12))
    $leafBrush = New-Object System.Drawing.SolidBrush($leafGreen)
    $g.FillEllipse($leafBrush, $leafRect)
    $leafBrush.Dispose()

    $arcRect = New-Object System.Drawing.RectangleF([float]($w * 0.52), [float]($baseline - $h * 0.43), [float]($w * 0.24), [float]($h * 0.24))
    $g.DrawArc($penLeaf, $arcRect, 200, 120)

    $penArrow = New-Object System.Drawing.Pen($deepBlue, [float]($w * 0.042))
    $penArrow.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penArrow.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $x1 = [float]($w * 0.60)
    $y1 = [float]($baseline - $h * 0.21)
    $x2 = [float]($w * 0.84)
    $y2 = [float]($baseline - $h * 0.43)
    $g.DrawLine($penArrow, $x1, $y1, $x2, $y2)

    $arrowPts = @(
        (New-Object System.Drawing.PointF([float]($x2), [float]($y2))),
        (New-Object System.Drawing.PointF([float]($x2 - $w * 0.085), [float]($y2 - $h * 0.01))),
        (New-Object System.Drawing.PointF([float]($x2 - $w * 0.02), [float]($y2 + $h * 0.065)))
    )
    $arrowBrush = New-Object System.Drawing.SolidBrush($deepBlue)
    $g.FillPolygon($arrowBrush, $arrowPts)

    $iconDir = Split-Path -Path $outputPath -Parent
    if (-not (Test-Path $iconDir)) { New-Item -ItemType Directory -Path $iconDir -Force | Out-Null }

    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $arrowBrush.Dispose()
    $penGold.Dispose()
    $penLeaf.Dispose()
    $penArrow.Dispose()
    $g.Dispose()
    $bmp.Dispose()
}

$root = 'd:\projects\seedvest\seedvest_mobile\android\app\src\main\res'
$targets = @(
    @{ size = 48; dir = 'mipmap-mdpi' },
    @{ size = 72; dir = 'mipmap-hdpi' },
    @{ size = 96; dir = 'mipmap-xhdpi' },
    @{ size = 144; dir = 'mipmap-xxhdpi' },
    @{ size = 192; dir = 'mipmap-xxxhdpi' }
)

foreach ($t in $targets) {
    $out = Join-Path $root (Join-Path $t.dir 'ic_launcher.png')
    Draw-SeedVestIcon -size $t.size -outputPath $out
}

# Save a high-res source copy for future regeneration
Draw-SeedVestIcon -size 1024 -outputPath 'd:\projects\seedvest\seedvest_mobile\assets\icons\seedvest_app_icon.png'

Write-Output 'ICONS_GENERATED'

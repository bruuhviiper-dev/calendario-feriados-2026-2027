Add-Type -AssemblyName System.Drawing
# Identidade do app31 "Frases para Refletir": gradiente escuro azul-petroleo
# (mesmo do tema Reflexao) + uma flor de lotus branca (simbolo de reflexao/serenidade).
# Gera as 3 fontes do flutter_launcher_icons: icon.png, bg.png, icon_fg.png.
$dir = "C:\Users\Particular\Desktop\app31\assets\icon"
New-Item -ItemType Directory -Force $dir | Out-Null
$S = 1024

# paleta reflexao
$c1 = [System.Drawing.Color]::FromArgb(255,15,32,39)    # 0F2027
$c2 = [System.Drawing.Color]::FromArgb(255,44,83,100)   # 2C5364

function NewG($bmp){ $g=[System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode='AntiAlias'; $g.InterpolationMode='HighQualityBicubic'; return $g }

# desenha uma petala (elipse com a ponta no pivo), girada por 'ang' graus
function Petal($g,$cx,$cy,$ang,$pw,$ph,$brush){
  $st=$g.Save()
  $g.TranslateTransform([single]$cx,[single]$cy)
  $g.RotateTransform([single]$ang)
  $rect=New-Object System.Drawing.RectangleF([single](-$pw/2),[single](-$ph),[single]$pw,[single]$ph)
  $g.FillEllipse($brush,$rect)
  $g.Restore($st)
}

# desenha a flor de lotus centrada, ocupando ~'M' de largura
function Lotus($g,$S,$M){
  $cx=$S/2.0; $pivY=$S/2.0 + $M*0.34
  $pw=$M*0.30; $ph=$M*0.62
  # camada externa (mais transparente)
  $b1=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150,255,255,255))
  foreach($a in @(-78,-52,52,78)){ Petal $g $cx $pivY $a ($pw*1.02) ($ph*0.92) $b1 }
  # camada do meio
  $b2=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210,255,255,255))
  foreach($a in @(-30,30)){ Petal $g $cx $pivY $a $pw $ph $b2 }
  # petala central
  $b3=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245,255,255,255))
  Petal $g $cx $pivY 0 ($pw*0.96) ($ph*1.06) $b3
  # base/agua (linha suave sob a flor)
  $wb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70,255,255,255))
  $g.FillEllipse($wb,[single]($cx-$M*0.34),[single]($pivY-$M*0.02),[single]($M*0.68),[single]($M*0.09))
}

function RoundRect($x,$y,$w,$h,$r){ $p=New-Object System.Drawing.Drawing2D.GraphicsPath; $d=$r*2
  $p.AddArc($x,$y,$d,$d,180,90);$p.AddArc($x+$w-$d,$y,$d,$d,270,90);$p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90);$p.AddArc($x,$y+$h-$d,$d,$d,90,90);$p.CloseFigure();return $p }

# ---- icon.png (legado, full-bleed) ----
$bmp=New-Object System.Drawing.Bitmap($S,$S); $g=NewG $bmp
$rect=New-Object System.Drawing.Rectangle(0,0,$S,$S)
$grad=New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,$c1,$c2,120)
$g.FillPath($grad,(RoundRect 0 0 $S $S ($S*0.22)))
Lotus $g $S ([single]($S*0.60))
$bmp.Save("$dir\icon.png",[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

# ---- bg.png (adaptive background: gradiente cheio) ----
$bmp=New-Object System.Drawing.Bitmap($S,$S); $g=NewG $bmp
$grad=New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,$c1,$c2,120)
$g.FillRectangle($grad,$rect)
$bmp.Save("$dir\bg.png",[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

# ---- icon_fg.png (adaptive foreground: lotus na zona segura, transparente) ----
$bmp=New-Object System.Drawing.Bitmap($S,$S); $g=NewG $bmp
$g.Clear([System.Drawing.Color]::Transparent)
Lotus $g $S ([single]($S*0.50))
$bmp.Save("$dir\icon_fg.png",[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

"icones gerados em $dir"

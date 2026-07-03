# ============================================================
# fetch-og.ps1 — STUDIOページ全リンクのOG画像をダウンロード
# 使い方: このファイルを右クリック →「PowerShellで実行」
# 出力: ../assets/og/ に画像、../assets/og/og-map.js にマッピング
# ============================================================
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "assets\og"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"

# ---- STUDIOページの全リンク ----
$targets = @(
  @{ slug="eex";            url="https://eex.co.jp/" },
  @{ slug="rhizomatiks";    url="https://rhizomatiks.com/" },
  @{ slug="party";          url="https://prty.jp/" },
  @{ slug="1-10";           url="https://www.1-10.com/" },
  @{ slug="bascule";        url="https://bascule.co.jp/" },
  @{ slug="dentsulab";      url="https://dentsulab.tokyo/" },
  @{ slug="wow";            url="https://www.w0w.co.jp/" },
  @{ slug="qosmo";          url="https://qosmo.jp/" },
  @{ slug="bassdrum";       url="https://bassdrum.org/" },
  @{ slug="teamlab";        url="https://www.teamlab.art/" },
  @{ slug="naked";          url="https://naked.co.jp/" },
  @{ slug="hibino";         url="https://www.hibino.co.jp/" },
  @{ slug="redcliff";       url="https://redcliff-inc.co.jp/" },
  @{ slug="droneshow";      url="https://droneshow.co.jp/" },
  @{ slug="tanseisha";      url="https://www.tanseisha.co.jp/" },
  @{ slug="nomurakougei";   url="https://www.nomurakougei.co.jp/" },
  @{ slug="sonypcl";        url="https://www.sonypcl.jp/" },
  @{ slug="unit9";          url="https://www.unit9.com/" },
  @{ slug="hovercraft";     url="https://www.hovercraftstudio.com/about" },
  @{ slug="phygitech";      url="https://phygi.tech/" },
  @{ slug="momentfactory";  url="https://momentfactory.com/ja" },
  @{ slug="refikanadol";    url="https://refikanadol.com/" },
  @{ slug="meowwolf";       url="https://meowwolf.com/" },
  @{ slug="artechouse";     url="https://www.artechouse.com/" },
  @{ slug="cosm";           url="https://www.cosm.com/" },
  @{ slug="spherestudios";  url="https://spherestudios.com/" },
  @{ slug="disguise";       url="https://www.disguise.one/" },
  @{ slug="roevisual";      url="https://www.roevisual.com/" },
  @{ slug="christie";       url="https://www.christiedigital.com/" },
  @{ slug="prg";            url="https://www.prg.com/ja-jp/" },
  @{ slug="skyelements";    url="https://skyelementsdrones.com/" },
  @{ slug="4dviews";        url="https://www.4dviews.com/" },
  @{ slug="lookingglass";   url="https://lookingglassfactory.com/" },
  @{ slug="3dphantom";      url="https://phantom-3d.net/" },
  @{ slug="mplusplus";      url="https://mplpl.com/" },
  @{ slug="lucent";         url="https://www.lucent-design.co.jp/" },
  @{ slug="symunity";       url="https://www.symunity.co.jp/deeplyimmersive/" },
  @{ slug="inty";           url="https://inty.pro/" },
  @{ slug="nowhere";        url="https://studionowhere.com/" },
  @{ slug="soso";           url="https://www.sosolimited.com/" },
  @{ slug="txd";            url="https://txd.jp/" },
  @{ slug="takenaka";       url="https://www.takenaka-co.co.jp/" },
  @{ slug="ledtokyo";       url="https://led-tokyo.jp/" },
  @{ slug="fujitaka";       url="https://www.fujitaka-jp.com/" },
  @{ slug="fengyi";         url="https://www.fyilight.com/ja/" }
)

$map = @{}

foreach ($t in $targets) {
  $slug = $t.slug; $url = $t.url
  Write-Host "==> $slug  $url"
  try {
    $html = (Invoke-WebRequest -Uri $url -UserAgent $UA -TimeoutSec 25 -UseBasicParsing).Content
  } catch {
    Write-Host "    ページ取得失敗: $($_.Exception.Message)" -ForegroundColor Yellow
    continue
  }

  # og:image / twitter:image を抽出(属性順の違いに両対応)
  $img = $null
  $patterns = @(
    '<meta[^>]+(?:property|name)=["'']og:image(?::secure_url)?["''][^>]*content=["'']([^"'']+)["'']',
    '<meta[^>]+content=["'']([^"'']+)["''][^>]*(?:property|name)=["'']og:image',
    '<meta[^>]+(?:property|name)=["'']twitter:image(?::src)?["''][^>]*content=["'']([^"'']+)["'']'
  )
  foreach ($p in $patterns) {
    $m = [regex]::Match($html, $p, "IgnoreCase")
    if ($m.Success) { $img = $m.Groups[1].Value; break }
  }
  if (-not $img) { Write-Host "    og:imageが見つかりません" -ForegroundColor Yellow; continue }

  $img = $img.Replace("&amp;", "&")
  if ($img -notmatch "^https?://") { # 相対URLを絶対化
    $base = [Uri]$url
    $img = (New-Object Uri($base, $img)).AbsoluteUri
  }

  # 拡張子判定
  $ext = "jpg"
  if ($img -match "\.(png|webp|gif|jpeg|jpg)(\?|#|$)") {
    $ext = $Matches[1]; if ($ext -eq "jpeg") { $ext = "jpg" }
  }
  $file = Join-Path $outDir "$slug.$ext"

  try {
    Invoke-WebRequest -Uri $img -UserAgent $UA -TimeoutSec 25 -Headers @{ Referer = $url } -OutFile $file -UseBasicParsing
    # Content-Typeで拡張子を補正できないケースがあるため、極小ファイルは失敗扱い
    if ((Get-Item $file).Length -lt 1000) { Remove-Item $file; throw "画像が小さすぎます" }
    $map[$url] = "assets/og/$slug.$ext"
    Write-Host "    OK -> assets/og/$slug.$ext" -ForegroundColor Green
  } catch {
    Write-Host "    画像取得失敗: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

# ---- og-map.js を出力 ----
$lines = @("// 自動生成: fetch-og.ps1 " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
$lines += "window.LOCAL_OG = {"
foreach ($k in $map.Keys) { $lines += ('  "' + $k + '": "' + $map[$k] + '",') }
$lines += "};"
Set-Content -Path (Join-Path $outDir "og-map.js") -Value ($lines -join "`n") -Encoding UTF8

Write-Host ""
Write-Host ("完了: {0}/{1} 件を assets/og/ に保存しました" -f $map.Count, $targets.Count) -ForegroundColor Cyan
Write-Host "GitHub Desktopで assets フォルダごとコミットしてください"
Pause

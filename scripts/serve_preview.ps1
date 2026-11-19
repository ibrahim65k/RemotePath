param([int]$Port = 8765)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rootPrefix = $root.TrimEnd('\') + '\'
$listener = [System.Net.HttpListener]::new()
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Output "RemotePath local preview: $prefix"
$mime = @{
  '.html'='text/html; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.js'='text/javascript; charset=utf-8'
  '.json'='application/json; charset=utf-8'; '.svg'='image/svg+xml'; '.xml'='application/xml; charset=utf-8'
  '.txt'='text/plain; charset=utf-8'; '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.webp'='image/webp'
}
try {
  while($listener.IsListening){
    $context=$listener.GetContext()
    try {
      $relative=[Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
      if(!$relative){$relative='index.html'}
      $file=[IO.Path]::GetFullPath((Join-Path $root $relative))
      if(!$file.StartsWith($rootPrefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath $file -PathType Leaf)){
        $context.Response.StatusCode=404
        $bytes=[Text.Encoding]::UTF8.GetBytes('Not found')
      }else{
        $context.Response.StatusCode=200
        $ext=[IO.Path]::GetExtension($file).ToLowerInvariant()
        if($mime.ContainsKey($ext)){$context.Response.ContentType=$mime[$ext]}else{$context.Response.ContentType='application/octet-stream'}
        $bytes=[IO.File]::ReadAllBytes($file)
      }
      $context.Response.ContentLength64=$bytes.Length
      $context.Response.OutputStream.Write($bytes,0,$bytes.Length)
    }catch{
      $context.Response.StatusCode=500
      $bytes=[Text.Encoding]::UTF8.GetBytes('Preview server error')
      $context.Response.OutputStream.Write($bytes,0,$bytes.Length)
    }finally{$context.Response.Close()}
  }
}finally{$listener.Stop();$listener.Close()}

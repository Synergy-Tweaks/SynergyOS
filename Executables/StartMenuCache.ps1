# Clear live-session taskbar pin cache so Explorer rebuilds from LayoutModification.
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband' -Name 'Favorites' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband' -Name 'FavoritesResolve' -ErrorAction SilentlyContinue
Start-Process explorer

Rename-Item -Path "$($args).mp4" -NewName "$($args).merging.mp4"
Rename-Item -Path "$($args).m4a" -NewName "$($args).merging.m4a"

ffmpeg `
    -i "$($args).merging.mp4" `
    -i "$($args).merging.m4a" `
    -c copy "$($args).mp4"

Remove-Item -Path "$($args).merging.mp4"
Remove-Item -Path "$($args).merging.m4a"
yt-dlp `
    --embed-metadata `
    --embed-chapters `
    --embed-subs `
    --sub-lang=all,-live_chat `
    --merge-output-format webm/mp4 `
    -o "%(title)s.%(ext)s" `
    $args
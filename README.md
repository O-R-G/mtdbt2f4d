# Meta-the-difference-between-the-2-font-4-d

Meta-the-difference-between-the-two-font-4-d is a Processing sketch for animated typography. It cycles through generated font variants while displaying live typing or playing text from scripts with timing and font-range cues.

## Run

Open `mtdbt2f4d_v7/mtdbt2f4d_v7.pde` in Processing (Java mode) and run the sketch. With `processing-java` installed and on your PATH, you can also run:

```sh
cd mtdbt2f4d_v7
sh mtdbt2f4d.sh
```

The default configuration uses live typing in a 1920 × 1080 window. Playback and export are disabled. Adjust the modes, options, and settings near the top of the main sketch to select a font sequence, enable scripted playback, or configure output.

## Files

- `mtdbt2f4d_v7/mtdbt2f4d_v7.pde` — main sketch, keyboard controls, playback, and export.
- `mtdbt2f4d_v7/videoexport.pde` — bundled video exporter; video output requires FFmpeg.
- `mtdbt2f4d_v7/data/` — generated TTF sequences and audio.
- `mtdbt2f4d_v7/data/resources/` — versioned `Script.txt`, `Cues.txt`, and `Fonts.txt` files for text, timing, and font ranges.
- `mtdbt2f4d_v7/out/` — output location for exported frames and video.
- `src.zip` — archived font assets.

The sketch includes PNG, PDF, and video output modes. PDF export requires enabling the Processing PDF library import in the main sketch. Font-generation tools are maintained separately in the `mtdbt2f` repository.

# Sample Library Notes

Current bundled audition packs are sourced from Freesound pages that expose:

- a Creative Commons license on the sound page
- a downloadable high-quality preview MP3

For this first pass, the downloader only accepts sounds whose page license resolves to `CC0` or `CC-BY`, and the current curated set ended up being entirely `CC0`.

Why previews instead of original uploads:

- Freesound's public sound metadata exposes preview URLs directly.
- Original-quality downloads are gated behind authenticated download access.
- For fast internal auditioning in TestFlight, preview MP3s are sufficient.

Generated files:

- `SuperSimple/Resources/Samples/sample-library.json`
- `Docs/sample-library-manifest.json`

The JSON manifest records, for every bundled sample:

- the Freesound source page
- the preview URL used
- the detected license and license URL
- credit text
- the bundled resource path

If we later replace any preview with a higher-quality original or with another library, keep the manifest structure and update the source metadata at the same time.

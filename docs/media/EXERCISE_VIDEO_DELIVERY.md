# Exercise video delivery and release contract

Status: engineering intake prepared; **no final video is delivered or approved**.
Last local audit: 2026-09-06. This document does not authorize publishing, purchase,
production database writes, or any medical claims.

## Inventory and identifiers

`exercise_video_manifest.v1.json` inventories all **22 exercises modeled locally**:
7 Moro, 4 Spinal Galant, 5 TLR, and 6 preparation (`vorrunde`). Other packages have
artwork but no local exercise model; commissioning those requires their own
approved exercise inventory first. Inventory presence does not enable a package.
Moro is the versioned released training contract. Preparation has explicit `TBD`
instructions: do not commission a demonstration from those placeholders.

Each record contains the stable exercise ID, stable video ID, package, ordering,
DE/EN titles and source instructions, content version, existing poster, target
clip duration, delivery profile, status, ownership and approval records. Labels
such as “Moro 5” are not IDs: released `moro_ex1` is titled “Moro 5”. Never reorder
or rename IDs based on visible titles. `revision` increments for every delivery
replacement. Never overwrite an object at an already published revision.

All records start `awaiting_production`; states progress through `filming`,
`editing`, `in_review`, `approved`, then `published`. `approval_refs` must name
private review records for `content`, `rights`, `accessibility_de`,
`accessibility_en`, and `device_qa`. Use opaque record references, not contracts,
performer names, signatures or personal information in the repository. The
professional owns correctness of the filmed movement; the founder commissions
and clears publication; the editor delivers; engineering performs technical QA.

Source fields are checked against the Dart exercise catalog by:

```sh
flutter test test/features/training/domain/content/exercise_video_inventory_test.dart
```

After a separately approved exercise-content change, regenerate source fields:

```sh
UPDATE_EXERCISE_VIDEO_INVENTORY=1 flutter test test/features/training/domain/content/exercise_video_inventory_test.dart
```

This preserves delivery records and approvals. A changed content version requires
human re-review and resetting status/approvals; regeneration does not grant it.
Approved records must set `approved_content_version` to the exact reviewed
`content_version`. The delivery gate rejects stale approvals after a content change.

## Filming brief (provisional production format, not exercise guidance)

Use the exact bilingual position, movement and orientation instructions from the
inventory and the current content version. The professional must approve the
shot list and timing before filming. Do not infer a movement, replace a missing
instruction, add intensity advice or make benefit/healing claims. Clip lengths
are editing targets, **not a prescribed exercise duration or repetition count**.

Capture a stable, landscape 16:9 master with full body, hands, feet and contact
with the floor visible throughout the movement. Use a plain contrasting
background, consistent lighting, uncluttered clothing and a fixed camera. Leave
space around the body; avoid crops, mirror effects or cuts that reverse sides.
Show the initial position, a complete controlled movement and return, including
both sides when the supplied instructions require them. Use a second close-up
only when needed to show a contact/position clearly and approved by the
professional. Preserve actual timing; no speed ramps. No flashing cuts or
unnecessary camera movement. Target 15–90 seconds; exceptions need a revised,
reviewed delivery profile rather than silent validator bypasses.

The existing client supports **one video URL per exercise**, shared by both
languages and solo/duo presentation. V1 delivery is therefore silent and language
neutral, with no speech, music, hardcoded language overlays or essential audible
cues. All essential guidance must already be available in the localized app
instructions. Do not film a duo variation as a replacement for the solo video:
separate duo playback and per-locale tracks require a separately implemented
client/schema contract first. Preparation solo and duo instructions are blocked
pending the professional's full content delivery.

Provide reviewed German and English plain UTF-8 transcripts describing all
meaningful visual actions, plus WebVTT cues for the same description. These are
required handoff/accessibility artifacts; **the current player does not load
sidecar captions or transcripts**. Because the release profile is silent, the
localized in-app text remains the accessible equivalent. Accessibility review
must confirm that no extra essential guidance exists only in the video. If that
cannot be true, publication is blocked until a text/caption presentation is
implemented. Never claim selectable subtitles in store or product copy.

## Editor handoff and validation

Required files per video record:

| Role in `files` | Delivery |
|---|---|
| `video` | `.mp4`, H.264/AVC, yuv420p, 1280×720 or 1920×1080, 24–30 fps, no audio stream, fast-start (`moov` before `mdat`), ≤4.5 Mbps, 15–90 seconds, ≤50 MiB |
| `poster` | JPEG or PNG, same framing, no invented text/claims; ≤5 MiB; choose a clear initial position |
| `captions_de`, `captions_en` | UTF-8 WebVTT with reviewed, synchronized descriptive cues |
| `transcript_de`, `transcript_en` | Nonempty UTF-8 text, professional and language review |

Each `files` record is `{ "path": "relative/path", "sha256": "64 lowercase hex digits" }`.
Keep source/master recordings and editing projects in private storage; only
approved delivery files belong in the public media bucket. Strip identifying
metadata. Keep permissions, performer releases, rights scope, and music/image
licenses (if any) in the private commissioning records. Do not assume they exist.

The validator uses Python 3.9+ and `ffprobe` when checking approved deliveries:

```sh
python3 scripts/validate_exercise_videos.py
python3 -m unittest discover -s scripts -p test_validate_exercise_videos.py
python3 scripts/validate_exercise_videos.py --delivery-root /absolute/private/delivery --release-package moro
```

Default mode checks the inventory and any approved records; it does not certify
pending footage. The release command fails until **every** video for that package
has approvals and valid delivery files. It intentionally fails today. Run the
Dart inventory test alongside it to prove the manifest covers the source catalog.
The tool is local-only and never fetches URLs, uploads objects, or writes SQL.
It checks checksums, bounded sizes, MP4 stream metadata/fast-start, safe paths,
poster signatures, and presence of captions/transcripts. It does not certify
movement correctness, rights, full image decoding, caption timing/translation or
real-device behavior; those remain explicit human acceptance records. Synthetic
unit fixtures exercise validation logic and are never production assets.

## Storage, administration, publication and rollback

Existing migration `20260530_exercise_media_urls.sql` defines a **public read**
Supabase `exercise-media` bucket, with no client upload policy and a broad legacy
500 MiB limit. This stricter delivery contract caps clips at 50 MiB. There is no
in-repository transcoding worker or video CMS; processing is an offline editor
step, and ingest is an administrator operation. Never give the mobile client a
service-role key. Do not upload unapproved media into a public bucket to stage it.
Private delivery storage and administrator access are external dependencies.

Prepare release as follows; all actual public uploads/production changes require
founder authorization after the exact batch and rollback are reviewable:

1. Complete professional, rights, language/accessibility and device review in a
   private delivery location. Run the inventory and delivery gates. Preserve the
   checksum report and approval references.
2. Read only the affected public exercise-content rows (no user data). Preserve
   existing `video_url` and `image_url` values as the explicit rollback mapping.
   Check that each ID exists exactly once and matches the intended content
   version and instructions. Reject partial/mismatched batches.
3. Prepare upload object names `exercises/{exercise_id}/v{revision}/video.mp4`
   and `poster.jpg` or `poster.png`, MIME types `video/mp4` and image type. Review
   the exact new public URLs and UPDATE statements plus the old-value rollback
   statements. Update **only** media URL columns; never instructions, timings,
   user rows, exercise IDs or the bundled image/video path fields.
4. After authorization, upload immutable approved video/poster files with long
   object cache lifetime (one year). Verify returned MIME/length/checksum and
   byte-range support, and actual playback. Redirect chains, auth-expiring URLs
   and signed query tokens are unsuitable for this public delivery contract.
5. After the separately authorized database update, mark entries `published`
   and set `public_url` to the exact versioned public video URL. Run the gate
   again. Preserve the previous objects for installed clients using older URLs.
6. Verify both a new install and an existing cached install after cold restart,
   in DE/EN on real iOS and Android devices, plus offline and poor-network cases.
   Do not claim CDN reachability or device acceptance from local unit tests.

Cold start calls `forceSync()` in `lib/app.dart`; successful validated sync
atomically refreshes Drift content. A valid cache passed only to `syncIfNeeded()`
is retained. The old remote-media plan's one-time-cache description is obsolete.
Moro content validation retains the offline snapshot and accepts only valid
remote media overlays; an invalid response must not replace the good cache.
Images use network caching plus bundled fallback. Videos are streamed, not
persistently downloaded, so offline video playback is **not guaranteed**.
Changing the versioned URL avoids stale poster/CDN objects; do not overwrite old
URLs. A new media revision cannot silently change the exercise contract.

Rollback is the saved old-URL update batch, followed by a successful cold-start
refresh. If no prior approved video exists, rollback sets `video_url = NULL`.
Keep previous objects; do not delete them as part of rollback. An offline client
with an older valid cached URL cannot receive an immediate recall. If a clip is
unsafe, disabling access to that specific object may also be necessary, and
requires owner authorization; the client then falls back to bundled instructions.
This is a real limitation, not an instantaneous remote kill switch.

## Runtime acceptance and monitoring

The existing player uses an eight-second remote initialization timeout, retries,
image fallback, an always-available next button, reduced-motion no-autoplay,
controller disposal and source-change protection. Bundled Moro videos are
explicitly absent; do not resurrect legacy unbundled paths. The app currently
uses a localized failure message when no video is present. It never labels a
placeholder as production footage. Widget tests exercise remote timeout/failure,
retry, local image fallback and reduced-motion behavior. Late native player
errors now produce fallback/retry; asset initialization has the same timeout.
Interruption/backgrounding, buffering stalls without native errors and actual
codec behavior still require the
real-device checklist before accepting `device_qa`.

No exercise-specific playback analytics stream is enabled. Existing content sync
logging reports count/failure; do not put raw URLs, file query strings, profile IDs,
exercise selections, health answers or child information in new telemetry. After
Sentry's existing privacy rollout is authorized, a useful bounded media error
category would be `initialize_timeout`, `initialize_failed`, `playback_failed` or
`retry_failed`, platform and app build only. Aggregate CDN HTTP errors and bytes
from the operator dashboard; establish alerts on sustained failures and abnormal
bandwidth. Dashboard credentials, an approved reporting configuration and real
traffic are needed before measured media SLOs can be asserted.

## External dependencies — deliberately still open

- Founder commission/budget and chosen producer/editor; nobody has been contacted.
- Professional-approved shot list and final footage for all 22 entries; the first
  release batch is the 7 Moro videos. Six preparation instructions are missing.
- Professional judgment and approval of exercise-specific framing, movement,
  timing and any suitability/safety copy; engineering provides no clinical signoff.
- Editing masters and encoded video/poster files, DE/EN transcripts and captions.
- Performer/location/image rights, licenses and written publication permissions.
- German/English review and accessible-equivalence signoff.
- Private delivery storage, editor/tool access, administrator credentials and
  verified bucket/CDN configuration. None were assumed or changed.
- Real iOS/Android playback, interruption, offline and poor-network QA using final
  files, plus authorized upload, database mapping and rollback rehearsal.
- Approval for public publication and any production operations; integration code
  and a passing inventory check do not constitute those approvals.

## Prepare the exact review batch locally

`scripts/prepare_exercise_video_release.py` generates the concrete upload list,
new/old URL mapping and reversible SQL after the delivery gate passes. Supply a
JSON array containing **only** `{ "id": "moro_ex1", "video_url": null,
"image_url": null }`-shaped current exercise-content rows, exactly one per selected
package exercise. Obtain real current values through a read-only content query;
never substitute null for a value that exists. Do not include user data. Previous
URLs must be public HTTPS without tokens/query parameters.

```sh
python3 scripts/prepare_exercise_video_release.py \
  --delivery-root /absolute/private/delivery \
  --current-mapping /absolute/private/current-media-urls.json \
  --package moro \
  --project-url https://sxvpiggednbftfqeokyd.supabase.co \
  --output /absolute/private/release-review-v1
python3 -m unittest discover -s scripts -p 'test_*exercise_video*.py'
```

The output folder must not already exist. `uploads.json` records checksums,
sizes, exact object keys, MIME, cache lifetime and `upsert: false`; a missing
object is uploaded once, never overwritten. `apply.sql` compares each saved old
URL before changing it and rolls back the entire transaction if any row is
missing or changed concurrently. `rollback.sql` similarly compares the newly
published values before restoring the originals. `mapping.json` makes the blast
radius reviewable. This tool executes no SQL and performs no upload, network
request or manifest status change. It refuses currently reused revisions; the
administrator must additionally verify these object keys have never been used
historically before upload. Review approval remains the last step. SQL text is
covered by unit tests; actual final-media apply/rollback awaits delivered assets
and administrator authorization.

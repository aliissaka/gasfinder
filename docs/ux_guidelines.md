# UX guidelines (illiterate-friendly)

End users may not be able to read. Every screen must work for someone who recognises icons, photos, and colors but does not read French text.

## Rules

1. **Icons + photos before text.** Every action has a recognisable symbol. Text is a secondary cue, not the primary one.
2. **Brand logos as buttons.** Never list brands by name only — always logo first, name (small) underneath.
3. **Color coding is consistent**: green = available, red = unavailable, yellow = low. Always pair color with an icon (color-blindness + cultural variance).
4. **Voice prompts (TTS) in French** on every screen, with optional local-language audio (Wolof, Bambara, Dioula, Mooré). Pre-recorded MP3 fallback when TTS is unavailable offline.
5. **No typing in the end-user flow.** Selection only. Phone-number entry on a number pad with audio feedback per digit.
6. **Tap targets ≥ 56 dp.** Maximum 3 actions per screen.
7. **Onboarding** is a short animated tutorial (GIF or Lottie-lite). Text-free where possible.
8. **Loading and offline states** use animated icons, not text spinners.

## Anti-patterns

- ❌ "Click here to continue" text-only links
- ❌ Form fields requiring typed input
- ❌ Brand names as text-only chips
- ❌ Red text on red background (still text-dependent)
- ❌ Modal dialogs with text-only confirm/cancel buttons

## Testing

Recruit 5+ illiterate users for each pilot round. Sit beside them, do not assist, observe where they hesitate. Iterate.

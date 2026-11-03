---
version: 1
slug: "bulkup-views-userprofileview-swift"
primary_target: "bulkup/Views/UserProfileView.swift"
related_targets: ["bulkup/Views/Components/Friends/FriendProfileView.swift","bulkup/Views/Components/Profile/EditProfileView.swift","bulkup/Views/Components/Friends/AddFriendView.swift","bulkup/Views/Components/Friends/MyFriendCodeView.swift"]
---

# Surface: Perfil (UserProfileView tab, FriendProfileView, EditProfileView, AddFriendView, MyFriendCodeView)

Mode: Operate. Audience: the lifter checking their own numbers, managing the account, and looking up what a friend has been doing. Task: see your streak, open edit/measurements/subscription/export, open a friend's card (streak, last workouts, best records), add a friend by code, share your code, change photo/name/birth date, sign out or delete the account. States: PRO vs free (locked rows), no friends, friend card loading/failed/empty sections, photo uploading, nothing to save. Constraints: friend data comes from `GET /friends/{id}/profile` (training data only; no measurements, no diet); StoreKit tier; Dynamic Type; dark and light; 44pt targets.

## Direction contract

THESIS: the profile is numbers and rows, and a friend's card is the same page about them. Refuses the stat-card carousel, the glowing avatar ring and the "UPGRADE" capsule.
OWN-WORLD: a 64pt avatar on the raised fill (photo or initial in secondary) beside the name in the title voice, the email in caption, the tier as a solid PRO tag with "Suscripción activa" or a lime-text "Plan básico · Pasar a PRO"; a 46pt lifted gear square. A `StatsStrip` (días seguidos with "Mejor N", entrenos, días en la app). "Cuenta" as a slab of `PlanActionRow`s (glyph, title, PRO tag when locked, chevron). "Amigos" as a slab of rows (28pt avatar, name, streak in tabular SF, chevron) that open the friend card, with "Mi código" / "Añadir amigo" footer links. Quick toggles as a slab (haptics, notifications, lime tint). "Cerrar sesión" raised, "Eliminar cuenta" caption tertiary, version in tabular caption2. Friend card: 56pt avatar, name in title voice, "En BulkUp desde oct 2025", the strip (días seguidos / entrenos / esta semana with "N en 30 días"), "Últimos entrenos" rows (name, date, "20 series · 8.420 kg"), "Récords" rows (name, "120 kg × 3" in mono 17, "1RM 132 kg"), "Eliminar amigo" caption. Code sheets on the import-by-code grammar (mono 28/32 on raised, lime CTA, sky check on success). No red, no colour on levels, no capsule badges except the PRO tag.
STORY: "¿Cómo va Marta?" → Perfil → her row → her card: 18 días seguidos, pierna ayer, sentadilla 120 × 3 → close.
FIRST VIEWPORT: avatar, name, tier, gear; the strip; the Cuenta slab; the top of Amigos.
FORM: slabs of rows with a strip of numbers (first of: slabs, stat-card carousel, grouped List, hero avatar page); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict and DESIGN.md.

# Soho — public website

Static site carrying the landing page and the five legal policies that Apple
and Google require before the Soho apps can be submitted. No build step, no
JavaScript, no external fonts or CDNs — seven HTML files and one stylesheet
served by nginx.

It exists to unblock three things at once:

1. **App Store / Play Store submission** — a Privacy Policy URL and a Support
   URL that are public and load without a login are hard requirements.
2. **Apple Developer Program enrollment (Organization)** — Apple verifies that
   the company has a live website on a domain it owns, matching the registered
   entity.
3. **In-app policy links** — the app links out to these pages from signup,
   checkout, Help & Support and the Legal & Policies screen.

---

## 1. Placeholders: what's left

Unconfirmed values are marked `[[LIKE THIS]]` and rendered with a yellow
highlight, so they are impossible to miss when reading the pages. To list
what's left:

```bash
grep -oh '\[\[[^]]*\]\]' *.html | sort -u
```

Everything that could be established from the app and backend has been filled
in (see the next section). **Five values remain, and all five need the client's
own records** — nothing in the codebase can supply them:

| Placeholder | Notes |
|---|---|
| `[[REGISTERED LEGAL ENTITY NAME]]` | Exactly as government-registered. Must match the Apple Developer Program enrollment and the app's `EXPO_PUBLIC_LEGAL_ENTITY_NAME`. |
| `[[REGISTERED BUSINESS ADDRESS]]` | Goes in the footer, the policies and App Review contact info. |
| `[[REGISTRATION / TRADE LICENCE NO.]]` | On the About section. The Digital Commerce Operation Guidelines, 2021 expect a digital-commerce business to publish its trade licence details. |
| `[[SUPPORT PHONE]]` `[[SUPPORT WHATSAPP NUMBER]]` | Blank in the app's `.env` too (`EXPO_PUBLIC_SUPPORT_PHONE`, `EXPO_PUBLIC_SUPPORT_WHATSAPP`). The app's "Request a Return" button does not work until the WhatsApp number is set, so this one blocks returns, not just the website. |

### Values taken from the app and backend

These were not business decisions — they are what the code already does. If any
of them changes, the code and this site have to change together.

| Value | Now says | Source |
|---|---|---|
| Return window | 10 days | `ShippingTabContent.tsx` — "Hassle free 10 days Return & Exchange" |
| Support hours | 10 AM – 8 PM | `SohoApplication/config/support.ts` |
| Support email | support@soho-bd.com | The company domain. **`EXPO_PUBLIC_SUPPORT_EMAIL` still says `support@soho.com`** — see below |
| Delivery charge | ৳150 flat, nationwide, no COD surcharge | `payment.tsx` (`shippingCharge = 150`) and `wardrobe/index.tsx` |
| Delivery times | Next day inside Dhaka, within 3 days outside | Confirmed by the client, 7 August 2026. Both sit inside the Digital Commerce Operation Guidelines, 2021 limits of 5 days in-city / 10 days elsewhere. **The app still estimates 7 days** — `DELIVERY_ESTIMATE_DAYS` in `ShippingTabContent.tsx` |
| Payment methods | Cash on delivery only | `checkout.tsx` — card, wallet and net banking are `enabled: false` |
| Courier | RoadRush, and the networks it routes through including Pathao | `ROADRUSH_BASE_URL`, `location.service.ts` (`pathao_id`) |
| Hosting | Microsoft Azure, Singapore region | `20.197.91.221` is a Microsoft-allocated address geolocating to Singapore |
| File storage | Self-hosted on the same server, not a third-party service | `STORAGE=minio`, MinIO runs beside the backend in Coolify |
| Email delivery | Google's mail servers | `SMTP_HOST=smtp.gmail.com` in the repo's `.env`. Production values are masked in Coolify — **confirm before relying on it** |
| Order record retention | Five years | VAT and Supplementary Duty Act, 2012 record-keeping requirement |
| Server log retention | Not archived; discarded on restart | `logger.service.ts` has a Console transport only — no file, no rotation |

### Two mismatches this surfaced

1. **The ৳150 delivery charge never reaches the order.** The app adds it to the
   displayed total, but `orders.service.ts` computes
   `totalAmount = subtotal - discountAmount` and sends that to RoadRush as
   `item_value`. The customer is shown one number and the courier is told to
   collect a smaller one, so Soho absorbs the delivery cost. The shipping policy
   states the ৳150 charge on the assumption the backend gets fixed. If the
   decision is free delivery instead, change the Delivery charges table in
   `shipping.html` and the note in `cancellation.html`.
2. **`EXPO_PUBLIC_SUPPORT_EMAIL` is `support@soho.com`**, a domain the company
   does not own. The site publishes `support@soho-bd.com`. The mailbox has to
   exist and the app's `.env` has to match before submission — App Review emails
   a support address that bounces at its peril.

### Business defaults chosen, worth a client sign-off

Reasonable defaults, consistent with Bangladeshi practice and the Digital
Commerce Operation Guidelines, 2021. None of them are in the code, so changing
one is a text edit here only:

| Value | Now says |
|---|---|
| Faulty-item reporting window | 48 hours from delivery |
| Return inspection | 3 working days |
| Refund method and time | bKash, Nagad or bank transfer, within 7 working days |
| Return delivery on change of mind | Customer pays |
| Exchanges | Customer pays to send back, Soho pays re-delivery |
| Email reply time | 1 working day |
| Review-report response | 24 hours (App Store guideline 1.2 expects a fast route for user content) |
| Complaints | Acknowledged in 2 working days, resolved in 15 |

### Bangladeshi law the pages cite

Written for a Bangladeshi seller shipping only within Bangladesh, so the
references are Bangladeshi rather than GDPR-shaped. A local lawyer should still
read these pages before submission — this is a developer's reading of the law,
not advice.

| Instrument | Used for |
|---|---|
| Personal Data Protection Act, 2026 (Law 63 of 2026) | The privacy policy's legal basis (s.5), breach notification to the National Data Management Authority (s.20), data subject rights, and the cross-border disclosure. Succeeded the Personal Data Protection Ordinance, 2025; the compliance window runs to roughly May 2027, so enforcement is still being stood up |
| Consumer Rights Protection Act, 2009 | Consumer rights that the terms cannot cut down, and the DNCRP complaint route — s.60 gives consumers 30 days to complain |
| Digital Commerce Operation Guidelines, 2021 | Delivery timelines (5 days in-city, 10 days elsewhere), the obligation to publish purchase and return conditions, and trade licence disclosure |
| Sale of Goods Act, 1930 and Contract Act, 1872 | Goods matching description, and formation of the sale contract |
| Information and Communication Technology Act, 2006 | An order placed in the app forms a valid contract electronically |
| Cyber Security Ordinance, 2025 | Unauthorised access to our systems or another customer's account. Replaced the Cyber Security Act, 2023 in May 2025 |
| Value Added Tax and Supplementary Duty Act, 2012 | The five-year retention of order and accounting records, which is why deleting an account cannot erase past orders |

---

## 2. Deploying on Coolify

DNS for `soho-bd.com` already points at the Coolify host. The apex currently
returns 503 because no resource claims it — deploying this fixes that and gets
a real certificate.

1. In Coolify, create a new **Application** on the target server, source
   **Dockerfile** (or a Git repo containing this directory).
2. Build pack: **Dockerfile**. Base directory: this folder. Port: **80**.
3. Under **Domains**, set `https://www.soho-bd.com`. Coolify requests a Let's
   Encrypt certificate automatically once DNS resolves to the server — which it
   already does.
4. Decide apex vs `www` and redirect the other. Whichever you choose becomes
   the canonical URL everywhere else, so pick before anything is published.
5. Deploy, then verify:

```bash
for p in / /support /legal/privacy /legal/terms /legal/returns \
         /legal/shipping /legal/cancellation /legal/data-deletion; do
  curl -s -o /dev/null -w "$p -> %{http_code}\n" "https://www.soho-bd.com$p"
done
```

All eight must return `200` over **valid** HTTPS. A self-signed or expired
certificate fails both App Review and iOS ATS.

### Search engines are blocked until the placeholders are filled

The site went live before section 1 was finished, so it ships `robots.txt`
(`Disallow: /`) and an `X-Robots-Tag: noindex, nofollow` header from
`nginx.conf`. App Review and the in-app links still work — those fetch pages
directly and ignore both — but the unfinished copy stays out of search results
and crawler caches.

**Both must be removed once the `[[PLACEHOLDER]]` values are real**, otherwise
the finished site is invisible to search. To confirm the block is gone:

```bash
curl -sI https://www.soho-bd.com/legal/privacy | grep -i x-robots-tag
```

### Local check

```bash
docker build -t soho-web . && docker run --rm -p 8099:80 soho-web
```

---

## 3. URL stability — do not skip this

`EXPO_PUBLIC_LEGAL_BASE_URL` is compiled into the app bundle at build time.
Once a build is on the App Store, these paths are frozen in every installed
copy:

```
/legal/privacy   /legal/terms   /legal/returns
/legal/shipping  /legal/cancellation
```

`/legal/data-deletion` is frozen for a different reason: it is registered with
Meta as the Facebook Login data deletion instructions URL (see
`CREDENTIALS_HANDOVER.md` §7.4). It is not compiled into the app bundle, but a
404 there blocks the Meta app from going Live.

They sit under `/legal/` deliberately. The e-commerce site that takes over
`www.soho-bd.com` will want `/shipping`, `/returns` and the rest of the
top-level namespace for its own pages, and a store route quietly shadowing a
policy URL that is frozen inside shipped app binaries is not a problem you want
to discover after review. `/legal/` is a prefix no storefront needs.

That site must keep these six paths working or 301 them. Otherwise the legal
links inside already-shipped apps break, and fixing that means a new build and
another review cycle.

Two `nginx.conf` rules are load-bearing here: extensionless URLs map onto the
`.html` files (`/legal/privacy`, not `/legal/privacy.html`), and the old
top-level paths 301 into `/legal/` so anything already pointing at them keeps
working.

---

## 4. After the site is live

Set these in `SohoApplication/.env`, then rebuild the app:

```
EXPO_PUBLIC_LEGAL_BASE_URL=https://www.soho-bd.com/legal
EXPO_PUBLIC_LEGAL_ENTITY_NAME=<registered entity name>
```

Note that `.env` is git-ignored and EAS builds from git, so these must also go
into `eas.json` under `build.<profile>.env` or they will be empty in production
builds.

In App Store Connect:

- **Privacy Policy URL** → `https://www.soho-bd.com/legal/privacy`
- **Support URL** → `https://www.soho-bd.com/support`
- Account deletion (Guideline 5.1.1(v)) is documented at
  `https://www.soho-bd.com/legal/data-deletion`
- **Marketing URL** (optional) → `https://www.soho-bd.com`

---

## 5. Open item: review reporting

The apps let customers write product reviews, which makes this
user-generated content under App Store Guideline 1.2. That guideline expects a
way to report offensive content **from inside the app**, plus the ability to
block abusive users.

`ReviewList.tsx` currently has no report or block mechanism. The Terms and
Support pages therefore route reports to the support email and WhatsApp rather
than promising an in-app button that doesn't exist. That is honest, but it may
not satisfy a reviewer — building a report action into the review list is the
safer path before submission.

---

## 6. Brand assets

Typography, palette and logo are taken from the app so the site and the product
read as one brand. Everything is self-hosted — no Google Fonts, no analytics,
no third-party scripts. That is deliberate: a privacy policy page that quietly
ships a visitor's IP address to a font host would have to disclose that in its
own text. It also means the pages render identically for App Review's fetcher
and load fast on a slow connection.

| Asset | Source in `SohoApplication` | Used for |
|---|---|---|
| `assets/fonts/Urbanist-Variable.ttf` | `assets/fonts/Urbanist[wght].ttf` | All body copy, section headings, nav. One variable file (85 KB) covers every weight the app registers separately. |
| `assets/fonts/Classyvogue.ttf` | `assets/fonts/Classyvogueregular.ttf` | Page titles and the hero only. |
| `assets/soho-wordmark.png` | `assets/images/soho.png` | The masthead logo, 341×141 transparent PNG. |
| `assets/favicon-*.png`, `apple-touch-icon.png` | cropped from `assets/images/Soho1024x1024.png` | Browser tab and home-screen icons. |

The palette matches the app: black `#000000` on white, `#F3F3F3` for tinted
sections and callouts, `#999999` for muted meta text, `#E5E5E5` hairlines.
Body copy uses `#4A4A4A` rather than the app's `#999999` — at 2.9:1 that grey
fails WCAG AA, which is fine for a one-line label in a mobile UI but not for
pages of legal text.

Two font limitations worth knowing before editing copy:

- **Classyvogue has no em dash** — it renders as a blank box. It is used for
  page titles only, so keep em dashes out of `<h1>` text.
- **Urbanist has no Taka sign (৳)**, being Latin-only. The browser falls back
  per character, and the stack names `Noto Sans Bengali` first so it lands
  somewhere predictable. The app has the same limitation, so the two are
  consistent.

### Cache busting

The stylesheet is linked as `assets/styles.css?v=N`. **Bump that number in all
eight HTML files whenever you edit the CSS**, or returning visitors keep the
old stylesheet for up to a day:

```bash
sed -i 's/styles\.css?v=[0-9]*/styles.css?v=4/' *.html
```

Fonts are served `immutable` with a one-year cache since they never change.

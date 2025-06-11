
# Crypto Fantasy League – Detailed Specification

> **Version:** 2025-06-11 v1.0  
> **Scope:** MVP (Alpha → Beta → Launch)  
> **Author:** ChatGPT collaborative spec session  

---

## 1 Vision & Goals  
**Mission** — Turn on-chain trading into a social, game-like competition where anyone can draft wallets or meme tokens and battle friends for weekly bragging rights.

**Success North-Stars**
- **Day-7 retention ≥ 40 %**
- **≥ 3 games played per user / week**
- **Viral coefficient ≥ 0.3** via invite system

---

## 2 Target Personas
| Persona | Motivation | Pain Today |
| --- | --- | --- |
| **“DeFi Degens”** (daily traders) | Show off trade instincts | Hard to showcase P/L publicly |
| **“Meme Hodlers”** (casual) | Light‑hearted competition | No low‑stakes fantasy option |
| **Influencer Communities** | Engage followers | Need fresh content / contests |

---

## 3 Core Game Loop
1. **Draft** 7 assets (wallets or meme tokens) and **select a Captain** → lineup locks **Sunday 23:59 UTC**.  
2. **Watch** live ticker & matchup card (Captain tile marked ★ 2×).  
3. **React** mid‑week:  
   * Wednesday waiver batch (13:25 UTC)  
   * Up to 3 instant free‑agent pickups (**‑2 pts each**) until Friday 23:59 UTC  
   * **Stop‑Loss Shield** (one per team per week)  
4. **Results** pushed Monday; tied matchups resolved by coin‑flip.  
5. **Share** recap → invite friends → repeat.

---

## 4 Game Modes (v1)

### 4.1 Wallet League
Pick 7 public wallet addresses. **Score = Δ portfolio equity in USD**. Bonus +5 pts for realized gains ≥ 10 % of draft equity.

### 4.2 Meme‑Coin League
Pick 7 ERC‑20 meme tokens. Daily stats collected: price Δ, volume Δ, holder growth, social score.

**Rotisserie scoring** — rank 1‑N on each stat per team, points 10 → 1.

---

## 5 Scoring Engine (pluggable)
```
portfolio_return = (valuation_today / valuation_draft) − 1
risk_adj_score  = (portfolio_return − rf_rate) / stdev(returns_7d)
```
Commissioner selects **Raw**, **Risk‑Adjusted**, or **Par** at league creation.

### 5.1 Roster & Point Modifiers
| Mechanic | Rule |
| --- | --- |
| **Captain** | Weekly points of chosen asset × 2. Auto‑assigned to first asset if unset at lineup lock. Cannot be changed or dropped during the week. |
| **Stop‑Loss Shield** | One per team per week. Activated on an asset Mon‑Fri; replaces that asset’s largest single‑day negative return with 0. Expires unused at Monday rollover. |
| **Free‑Agent Pickup** | −2 pts applied instantly per pickup (max 3 per week). New asset starts scoring from market value at pickup time. |

---

## 6 Roster Management

### 6.1 Weekly Waivers (Wednesday)
| Item | Spec |
| --- | --- |
| **Batch time** | 13:25 UTC every Wednesday |
| **Priority** | First‑come‑first‑served across league |
| **Claims/team** | 3 per week |
| **Submission order** | Claims processed earliest‑submitted first for that team |
| **Drop requirement** | Manager must specify `dropAssetId`; claim rejected if it targets the Captain |
| **Start value** | New asset begins scoring from its market value at 13:25 UTC |
| **Dropped asset** | Becomes immediate free agent |

### 6.2 Free‑Agent Pickups
| Item | Spec |
| --- | --- |
| **Window** | Post‑waiver batch → Friday 23:59 UTC |
| **Limit** | 3 pickups per team per week |
| **Penalty** | −2 pts applied instantly |
| **Cooldown** | None — pickups can be back‑to‑back |
| **Visibility** | Small “FA” tag on new asset tile for all users |

---

## 7 Season Calendar
| Phase | When | Action |
| --- | --- | --- |
| **Pre‑season** | Friday–Saturday | Users set line‑ups; tutorial quests |
| **Regular Season** | 8 weeks | Weekly head‑to‑head, waiver window every Wednesday 13:25 UTC, free‑agent window closes Friday 23:59 UTC |
| **Playoffs** | 2 weeks | Top 4 teams; single elimination |
| **Off‑Season** | 1 week | All‑time leaderboards, feature drops |

---

## 8 Engagement Features
* **Captain mechanic** – core 2× boost.  
* **Power‑Ups:** **Stop‑Loss Shield** only (details above).  
* **Streaks:** login & watch‑list streak → confetti & XP.  
* **Social feed:** tweet‑sized smack talk in matchup view.  
* **Achievements:** P/L milestones, perfect draft, upset of the week.  
* **Push reminders:** Draft lock T‑24 h & T‑1 h (no push for waivers or Shield).

---

## 9 Tech Stack Overview
| Layer | Choice | Rationale |
| --- | --- | --- |
| Mobile | Flutter 3 | Single code base iOS/Android, good Firebase synergy |
| Backend | Firebase Auth, Firestore, Cloud Functions, Cloud Scheduler | Managed, near‑real‑time sockets via `onSnapshot` |
| Data Providers | Etherscan API, Coingecko/Covalent, X/Twitter scraping via SerpAPI | Price + on‑chain + social buzz |
| CI/CD | GitHub Actions → Firebase Hosting (web admin) & App Store/Play internal testing | Fast iteration |

---

## 10 Data Model (Firestore)
```
/leagues/{leagueId}
  name, commissionerId, mode, scoringType, seasonWeek
/leagues/{leagueId}/teams/{teamId}
  userId, avatar, draft[], bench[], wins, losses, streak
  /weeks/{week}
    captainAssetId: string
    shield: { status: "available"|"activated"|"consumed", assetId?: string, day?: string }
    faMovesRemaining: number  -- starts at 3
    /faMoves/{moveId}
      timestamp, addAssetId, dropAssetId
/leagues/{leagueId}/scores/{week}
  teamId, rawReturn, riskScore, ranking
/assets/{assetId}
  symbol, type (wallet|token), meta{}
/dailyStats/{assetId}/{date}
  priceUsd, volumeUsd, holders, socialScore
```

---

## 11 Cloud Functions & Schedulers
| Trigger | Function | Purpose |
| --- | --- | --- |
| HTTPS callable | `submitDraft()` | Validate & lock picks + Captain |
| Pub/Sub (5 min) | `pullMarketData()` | Fetch price / balance snapshots |
| Firestore write `/dailyStats` | `recalcScores()` | Update league standings |
| Pub/Sub Wed 13:25 UTC | `processWaivers()` | Batch settle claims, enforce Captain drop rule |
| Firestore write `/faMoves/*` | `processFaMove()` | Apply −2 pts, enforce limit, tag asset |
| Pub/Sub Fri 23:59 UTC | `closeFaWindow()` | Disable FA pickups until next season week |
| Daily 00:05 UTC | `applyShield()` | Zero out shielded loss, mark consumed |
| Pub/Sub Sun 23:55 UTC | `advanceWeek()` | Roll `seasonWeek++`, unlock draft |

---

## 12 Security & Compliance
* Firestore Rules v9: user may write only their `/teams/{teamId}` before draft lock.  
* Sign wallet message if linking a personal address.  
* GDPR‑compliant: store only email & UID.  
* HTTPS enforced, API keys in Secret Manager.

---

## 13 Key Screens & Flows
1. **Onboarding:** hero → OAuth → username → pick first league.  
2. **Draft Room:** asset grid, Captain selector, countdown.  
3. **Matchup Dashboard:** live score ticker, asset tiles (★ 2×, 🛡️, FA tag), chat tab.  
4. **League Lobby:** standings table, upcoming schedule.  
5. **Profile:** trophies, historical stats, linked wallets.

---

## 14 Notifications & Comms
| Event | Channel | Timing |
| --- | --- | --- |
| Draft opens | FCM push | Friday 00:00 UTC |
| Draft lock T‑24 h | FCM push | Saturday 23:59 UTC |
| Draft lock T‑1 h | FCM push | Sunday 22:59 UTC |
| Weekly recap & leaderboard | Email digest (SendGrid) | Monday 08:00 UTC |
| Patch notes & promos | In-app inbox | As released |

---

## 15 Monetization Tracks
* **Premium subscription** → unlimited private leagues, advanced stats.  
* **IAP:** Stop‑Loss Shield skins & cosmetic bundles (future phase).  
* **Sponsor banners** in ticker (CPM).  
* Revenue share with influencer leagues.

---

## 16 Roadmap & Milestones
| Stage | Deliverables | ETA |
| --- | --- | --- |
| **M0 – PoC** | Data pull → Firestore, console log scores | 2 weeks |
| **M1 – Alpha** | Draft flow, live ticker, basic wallet league | +4 weeks |
| **M2 – Beta** | Meme‑Coin league, friends invites, FCM pushes | +6 weeks |
| **M3 – Launch** | Playoffs, Stop‑Loss Shield, App Store/Play release | +6 weeks |
| **M4 – V1.1** | Subscriptions, influencer leagues, NFT avatars | +8 weeks |

---

## 17 KPI & Analytics
* Firebase Analytics events: `draft_submitted`, `matchup_viewed`, `fa_pickup`, `shield_used`.  
* Cohort retention chart in BigQuery.  
* Mixpanel funnel: install → draft → week 2 active.

---

## 18 Risks & Mitigations
| Risk | Impact | Mitigation |
| --- | --- | --- |
| API rate limits | Scores stale | Cache & staggered fetch, multiple providers |
| Volatile gas fees | Wallet valuation errors | Use L2 oracles, 5‑min smoothing |
| Regulatory scrutiny | App blocked | Fantasy classification, no real‑money prizes |
| Whale manipulation | Unfair scoring | Cap wallet size, risk‑adjusted scoring |
| Captain blank | Lost 2× boost | Auto‑assign to first asset |
| FA spam | Score gaming | −2 pts penalty & 3‑pickup cap |
| DST drift | Scheduler misfires | Store all times in UTC |

---

## 19 Open Items / Future Enhancements
* Additional power‑ups (Double‑Captain rework, Scout Vision v2).  
* FAAB or budget-based waiver system.  
* Push notifications for waiver outcomes & FA pickups.  
* Trading between teams.  
* Web‑only spectator mode.

---

**End of spec**

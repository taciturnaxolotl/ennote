# enɳoté

**Pronunciation:** en-no-TAY  
**Search terms:** ennote, ennoté, en note

A Stack-inspired micro-note app for quick capture and focused execution.

---

## Philosophy

Break tasks into micro-notes. Prepare on desktop, execute on phone. Notes are ephemeral by design—captured quickly, completed quickly, then gone.

---

## Color Palette

*Inspired by laurieherault.com — dark, minimal, focused*

### Primary (Dark)

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#171717` | App background |
| Surface | `#212121` | Note cards, inputs |
| Surface Elevated | `#2A2A2A` | Modals, popovers |
| Text Primary | `#FAFAFA` | Headings, note content |
| Text Secondary | `#A3A3A3` | Timestamps, hints |
| Accent | `#FBBF23` | Progress bars, buttons, links |
| Accent Muted | `#78590A` | Accent at lower opacity contexts |
| Success | `#4ADE80` | Completed notes |
| Border | `#2E2E2E` | Subtle dividers |

### Light Mode (Optional)

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#FAFAFA` | App background |
| Surface | `#FFFFFF` | Note cards, inputs |
| Surface Elevated | `#FFFFFF` | Modals, popovers |
| Text Primary | `#171717` | Headings, note content |
| Text Secondary | `#6B6B6B` | Timestamps, hints |
| Accent | `#CA8A04` | Darker yellow for light bg |
| Accent Muted | `#FEF3C7` | Light yellow tint |
| Success | `#22C55E` | Completed notes |
| Border | `#E5E5E5` | Subtle dividers |

---

## Architecture

### Platforms

- **iOS App** (Swift/SwiftUI) — Primary experience
- **Web App** (lightweight) — Desktop note preparation only

### Sync Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                         CloudKit                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────┐                    ┌─────────────┐       │
│   │  Private DB │                    │  Public DB  │       │
│   │             │                    │             │       │
│   │  User's     │                    │  QR Stacks  │       │
│   │  personal   │                    │  (unlisted) │       │
│   │  notes      │                    │             │       │
│   └──────┬──────┘                    └──────┬──────┘       │
│          │                                  │              │
│          │ iCloud                           │ No auth      │
│          │ (automatic)                      │ required     │
│          │                                  │              │
└──────────┼──────────────────────────────────┼──────────────┘
           │                                  │
           ▼                                  ▼
    ┌─────────────┐                   ┌─────────────┐
    │   iOS App   │◄──── QR Scan ─────│   Web App   │
    │             │                   │  (Desktop)  │
    │  - Personal │                   │             │
    │    notes    │                   │  - Prepare  │
    │  - QR fetch │                   │    notes    │
    │  - Execute  │                   │  - Generate │
    │    stack    │                   │    QR code  │
    └─────────────┘                   └─────────────┘
```

---

## Data Models

### Note (Personal - Private DB)

```swift
struct Note: Identifiable {
    let id: UUID
    var content: String
    var isCompleted: Bool
    var order: Int
    let createdAt: Date
    var completedAt: Date?
}
```

### Stack (QR Transfer - Public DB)

```swift
struct Stack: Identifiable {
    let id: String              // Random 12-char alphanumeric
    var notes: [String]         // Just the content strings
    let createdAt: Date
    let expiresAt: Date         // createdAt + TTL
    var fetched: Bool           // Mark true on first fetch
}
```

---

## QR Flow

### Web → iOS Transfer

1. **User enters notes on web** (one per line)
2. **Web creates Stack record** in CloudKit public DB
   - `id`: Random 12-char string (e.g., `a7Bx9kL2mN4p`)
   - `notes`: Array of strings
   - `expiresAt`: Now + 5 minutes
   - `fetched`: false
3. **Web displays QR code** encoding: `ennote://stack/{id}`
4. **User scans QR with iOS app**
5. **iOS fetches Stack** from public DB by ID
6. **iOS marks `fetched: true`** and imports notes
7. **Stack auto-expires** — CloudKit TTL or cleanup job

### Expiration Strategy

| Trigger | Action |
|---------|--------|
| First fetch | Mark `fetched: true` |
| 5 min TTL | Record becomes stale |
| Cleanup job | Delete where `fetched == true` OR `expiresAt < now` |

**Instant expiration option:** Delete record immediately after first successful fetch (most secure, but no retry if fetch fails mid-transfer).

---

## iOS App Structure

### Views

```
├── NoteListView          # Main view - list of active notes
│   ├── NoteRow           # Single note with swipe actions
│   └── AddNoteField      # Quick-add at bottom
├── StackView             # Focus mode - one note at a time
│   ├── CurrentNote       # Large, centered current note
│   ├── ProgressBar       # Notes completed / total
│   └── TimerBar          # Optional time progress
├── ScannerView           # QR code scanner
└── SettingsView          # Preferences
```

### Core Features

- **Quick Add**: Pull down or tap to add note instantly
- **Swipe Actions**: Complete (right), Delete (left)
- **Stack Mode**: Focus on one note at a time, swipe to complete
- **QR Import**: Scan to pull notes from web
- **iCloud Sync**: Automatic across user's devices

### Stack Mode (Focus Execution)

Inspired by Laurie's Stack:

```
┌────────────────────────────────┐
│ ████████░░░░░░░░  4/10 notes   │  <- Progress bar
│ ██████░░░░░░░░░░  12:34 left   │  <- Timer bar (optional)
├────────────────────────────────┤
│                                │
│                                │
│     Review PR for auth flow    │  <- Current note (large)
│                                │
│                                │
├────────────────────────────────┤
│        ← swipe to complete →   │
└────────────────────────────────┘
```

---

## Web App

Minimal single-page app. No framework needed—vanilla HTML/CSS/JS + CloudKit JS.

### Features

- Large textarea for notes (one per line)
- Optional timer config (Until / Duration / Pomodoro)
- "Create Stack" button → generates QR
- QR displayed with 5-minute countdown
- No login required

### Tech

- Static HTML/CSS/JS
- CloudKit JS SDK for public DB writes
- QR generation via `qrcode.js` or similar
- Host anywhere (Vercel, Cloudflare Pages, GitHub Pages)

---

## CloudKit Setup

### Container

- Container ID: `iCloud.com.yourname.ennote`
- Enable CloudKit in Xcode capabilities

### Record Types

**Private Database:**

| Field | Type |
|-------|------|
| `content` | String |
| `isCompleted` | Int64 (0/1) |
| `order` | Int64 |
| `createdAt` | Date/Time |
| `completedAt` | Date/Time |

**Public Database (Stack):**

| Field | Type |
|-------|------|
| `notes` | String List |
| `expiresAt` | Date/Time |
| `fetched` | Int64 (0/1) |

### Security

- Private DB: Only accessible by record owner (automatic)
- Public DB: Readable/writable by anyone with record ID
- Stack IDs are 12-char random alphanumeric (~62^12 combinations)
- Records expire quickly, minimizing exposure window

---

## Future Considerations

- **Watch App**: Quick note view/complete
- **Shortcuts Integration**: "Add to enɳoté" action
- **Web Dashboard**: Read-only view of personal notes via CloudKit web (requires auth)
- **Share Extension**: Quick capture from other apps

---

## Widget Integration

Widgets should feel native to iOS — no heavy branding, respects system appearance, glanceable.

### Design Principles

- **No app logo in widget** — iOS users know what app it's from
- **System fonts** (SF Pro) — matches iOS aesthetic
- **Vibrancy & materials** — use system backgrounds, not solid `#171717`
- **Minimal chrome** — content first, no borders or containers
- **Respect Dynamic Type** — scale with user's text size preference

### Widget Sizes

#### Small (Single Note)
Shows the next uncompleted note. Tap to open app in Stack mode.

```
┌─────────────────┐
│                 │
│  Review PR for  │
│  auth flow      │
│                 │
│  3 more         │  <- subtle, secondary text
└─────────────────┘
```

#### Medium (Note List)
Shows 3-4 upcoming notes with progress indicator.

```
┌───────────────────────────────────────┐
│  ○ Review PR for auth flow            │
│  ○ Update dependencies                │
│  ○ Write tests for sync               │
│                                       │
│  ●●●○○○○○  3/8                        │  <- progress dots
└───────────────────────────────────────┘
```

#### Large (Stack Overview)
Full stack view with timer if active.

```
┌───────────────────────────────────────┐
│  enɳoté                    12:34 left │
│  ━━━━━━━━━━░░░░░░  3/8                │
├───────────────────────────────────────┤
│  ● Review PR for auth flow            │  <- current (highlighted)
│  ○ Update dependencies                │
│  ○ Write tests for sync               │
│  ○ Deploy to staging                  │
│  ○ Send update to team                │
└───────────────────────────────────────┘
```

#### Lock Screen (Accessory Widgets)

**Circular:** Note count remaining
```
  ┌───┐
  │ 5 │
  └───┘
```

**Rectangular:** Next note truncated
```
┌─────────────────────┐
│ ○ Review PR for...  │
└─────────────────────┘
```

**Inline:** Minimal status
```
enɳoté: 5 notes remaining
```

### Implementation

```swift
// Widget/EnoteWidget.swift

import WidgetKit
import SwiftUI

struct NoteEntry: TimelineEntry {
    let date: Date
    let notes: [Note]
    let timerEnd: Date?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        NoteEntry(date: .now, notes: [.placeholder], timerEnd: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NoteEntry) -> Void) {
        // Fetch from shared App Group container
        let notes = NoteStore.shared.activeNotes
        completion(NoteEntry(date: .now, notes: notes, timerEnd: nil))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteEntry>) -> Void) {
        let notes = NoteStore.shared.activeNotes
        let entry = NoteEntry(date: .now, notes: notes, timerEnd: nil)
        
        // Refresh every 15 minutes or when timer ends
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SmallNoteWidget: View {
    var entry: NoteEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let note = entry.notes.first {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(3)
                
                Spacer()
                
                if entry.notes.count > 1 {
                    Text("\(entry.notes.count - 1) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            Text("No notes")
                .foregroundStyle(.secondary)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
```

### Data Sharing

Widgets run in a separate process — need App Groups for shared data.

1. **Enable App Groups** in both app and widget targets
2. **Shared UserDefaults** for quick access:
   ```swift
   let sharedDefaults = UserDefaults(suiteName: "group.com.yourname.ennote")
   ```
3. **Shared SwiftData container** for full note access:
   ```swift
   let container = try ModelContainer(
       for: Note.self,
       configurations: ModelConfiguration(
           groupContainer: .identifier("group.com.yourname.ennote")
       )
   )
   ```
4. **Trigger refresh** when notes change:
   ```swift
   WidgetCenter.shared.reloadAllTimelines()
   ```

### Interactive Widgets (iOS 17+)

Enable completing notes directly from widget:

```swift
struct NoteRowWidget: View {
    let note: Note
    
    var body: some View {
        Button(intent: CompleteNoteIntent(noteID: note.id)) {
            HStack {
                Image(systemName: "circle")
                Text(note.content)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// AppIntents
struct CompleteNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Note"
    
    @Parameter(title: "Note ID")
    var noteID: String
    
    func perform() async throws -> some IntentResult {
        await NoteStore.shared.complete(noteID)
        return .result()
    }
}
```

### StandBy Mode (iOS 17+)

Widgets work automatically in StandBy — just ensure:
- Good contrast at distance
- No tiny text
- Works in both light/dark (StandBy can force red tint at night)

---

## Development Phases

### Phase 1: Core iOS App
- [ ] Note CRUD with SwiftData
- [ ] iCloud sync (private DB)
- [ ] Basic list view
- [ ] Quick add

### Phase 2: Stack Mode
- [ ] Focus execution view
- [ ] Swipe to complete
- [ ] Progress bar
- [ ] Timer options

### Phase 3: QR Transfer
- [ ] CloudKit public DB setup
- [ ] Web app (textarea + QR generation)
- [ ] iOS QR scanner
- [ ] Stack import flow
- [ ] Auto-expiration

### Phase 4: Widgets
- [ ] App Groups setup
- [ ] Small widget (next note)
- [ ] Medium widget (note list)
- [ ] Large widget (stack overview)
- [ ] Lock screen widgets
- [ ] Interactive widgets (iOS 17+)
- [ ] WidgetCenter refresh on changes

### Phase 5: Polish
- [ ] Dark/light mode
- [ ] Haptics
- [ ] Animations
- [ ] StandBy optimization
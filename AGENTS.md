# AGENTS.md

Documentation for AI agents working in the ennote codebase.

---

## Project Overview

**enɳoté** (pronounced: en-no-TAY) is a Stack-inspired micro-note app for quick capture and focused execution. Built with Swift/SwiftUI for iOS.

**Philosophy**: Break tasks into micro-notes. Notes are ephemeral by design—captured quickly, completed quickly, then gone.

---

## Project Structure

```
ennote/
├── ennote/                           # Xcode project root
│   ├── ennote/                       # Main iOS app target
│   │   ├── App/
│   │   │   ├── ennoteApp.swift       # @main entry point, container setup
│   │   │   └── ContentView.swift     # Root view, bottom bar and editor sheet
│   │   ├── Views/
│   │   │   ├── NoteListView.swift    # Main list with @Query and swipe actions
│   │   │   ├── NoteRow.swift         # One note: toggle button plus text button
│   │   │   ├── NewNoteBar.swift      # Glass bar in the bottom safe area
│   │   │   └── NoteEditorSheet.swift # Attributed TextEditor for add and edit
│   │   └── Resources/
│   │       ├── Assets.xcassets/      # Accent color
│   │       ├── ennote.icon/          # Icon Composer app icon
│   │       └── ennote.entitlements   # App Groups
│   ├── ennoteWidget/                 # Widget extension target
│   │   ├── ennoteWidget.swift        # Timeline provider and widget views
│   │   ├── InteractiveWidget.swift   # Tap-to-complete widget
│   │   ├── NewNoteControl.swift      # Control Center button
│   │   └── ennoteWidgetExtension.entitlements
│   ├── Shared/                       # Compiled into both targets
│   │   ├── Note.swift                # @Model SwiftData note entity
│   │   ├── NoteStorage.swift         # ModelContainer factory
│   │   ├── AppGroup.swift            # App Group constants and helpers
│   │   └── Theme.swift               # Color.themeAccent
│   ├── ennoteWidget-Info.plist       # Widget extension point identifier
│   └── ennote.xcodeproj/             # Xcode project file
├── spec.md                           # Comprehensive design document
├── README.md                         # Project overview
└── LICENSE.md                        # O'Saasy license
```

---

## Technology Stack

### iOS App
- **Language**: Swift 6 (strict concurrency, default actor isolation `MainActor`)
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Minimum Deployment**: iOS 26.0
- **Widgets**: WidgetKit with App Intents, plus a Control Center control

### Development Tools
- **IDE**: Xcode 15+
- **Build System**: Xcode build system (no external build tools)
- **Version Control**: Git
- **No Package Manager**: All dependencies managed via Xcode

---

## Build & Run

### iOS App

**Build in Xcode:**
1. Open `ennote/ennote.xcodeproj` in Xcode
2. Select the `ennote` scheme
3. Choose simulator or device
4. Cmd+R to build and run

**Build from command line:**
```bash
# Note: Requires Xcode (not just Command Line Tools)
cd ennote
xcodebuild -project ennote.xcodeproj -scheme ennote -destination 'platform=iOS Simulator,name=iPhone 15'
```

**No test suite currently exists** - this is a personal project in early development.

---

## Code Conventions

### Swift Style

**Naming:**
- `camelCase` for variables, functions, properties: `activeNotes`, `completeNote()`, `isCompleted`
- `PascalCase` for types: `Note`, `NoteStorage`
- Prefix private functions with `private`: `private func setupContainer()`
- Descriptive names over brevity: `activeNoteCount()` not `count()`

**Code Organization:**
- Use `// MARK: -` section headers for logical grouping
- Common sections: `// MARK: - Properties`, `// MARK: - Actions`, `// MARK: - Private Helpers`
- Extensions separate from main type definition
- One type per file (exceptions: small related types)

**SwiftUI Patterns:**
- `@Query` macro for SwiftData queries: `@Query(filter: #Predicate<Note> { !$0.isCompleted }) var notes: [Note]`
- `@Environment(\.modelContext)` for data mutations
- `@Binding` for two-way data flow
- `ViewThatFits` for responsive layouts (especially in widgets)
- `.sheet(item:)` preferred over `.sheet(isPresented:)` for modals
- `#Preview` macro for SwiftUI previews

**Concurrency:**
- Everything is `MainActor` by default (`SWIFT_DEFAULT_ACTOR_ISOLATION`)
- Mark shared plumbing reachable from widgets and intents `nonisolated`: `nonisolated enum AppGroup`
- `Task { }` for launching async work from sync context

**Error Handling:**
- Try-catch with optional fallback: `(try? context.fetch(descriptor)) ?? []`
- Guard-let for early returns: `guard let container = modelContainer else { return }`
- Print for non-critical errors: `print("Widget failed: \(error)")`
- `fatalError()` only for unrecoverable setup issues

**Comments:**
- Triple-slash for type documentation: `/// Shared note storage`
- Inline for non-obvious logic: `// 5 min TTL`
- Multi-line blocks for complex patterns
- **Don't over-comment** - prefer self-documenting code
- **Never add "what" comments** - focus on "why" if needed

---

## Critical Patterns & Gotchas

### App Group Fallback

**The Problem**: App Groups require a paid Apple Developer account. Personal/free accounts can't use them.

**The Pattern**: Check if App Group is available, fall back to local-only storage if not.

```swift
// ennote/Shared/AppGroup.swift
static var containerURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
}

// Every caller goes through the one factory in Shared/NoteStorage.swift
let configuration = AppGroup.containerURL == nil
    ? ModelConfiguration()
    : ModelConfiguration(groupContainer: .identifier(AppGroup.identifier))
return try? ModelContainer(for: Note.self, configurations: configuration)
```

**Implications:**
- Without App Group, widgets show empty - they can't access app's data
- App still works fine for personal testing
- To enable widgets: Use paid Apple Developer account and enable App Groups capability

### Widget Refresh

**Critical**: After any data mutation, refresh widgets immediately.

```swift
import WidgetKit

// After adding/completing/deleting a note:
WidgetCenter.shared.reloadAllTimelines()
```

Every mutation in `ContentView` and `NoteListView` calls it after saving.

### Toggle Dwell Time

**Pattern**: Toggling a note waits `toggleDwellTime` (5s) before committing. Toggling
again inside that window cancels the pending change instead of queueing a second one.

```swift
// NoteListView.swift
if let pending = pendingToggles.removeValue(forKey: id) {
    pending.cancel()
    return
}
pendingToggles[id] = Task {
    try? await Task.sleep(for: toggleDwellTime)
    guard !Task.isCancelled, note.modelContext != nil else { return }
    // ... apply, save, refresh
}
```

**Why**: The dwell is the undo window. The `modelContext != nil` guard matters because
a note can be deleted while its toggle is still pending.

### SwiftData Queries

**Pattern**: Use `@Query` in views, fetch descriptors in services.

```swift
// In views (automatic updates):
@Query(filter: #Predicate<Note> { !$0.isCompleted }, sort: \.order) 
var activeNotes: [Note]

// In services (manual fetch):
let descriptor = FetchDescriptor<Note>(
    predicate: #Predicate { !$0.isCompleted },
    sortBy: [SortDescriptor(\.order)]
)
let notes = try context.fetch(descriptor)
```

### CloudKit Container ID

**Current**: `iCloud.sh.dunkirk.ennote.beta`
**App Group**: `group.sh.dunkirk.ennote.beta`

These are specific to this project - when forking or adapting:
1. Create new CloudKit container in Apple Developer portal
2. Update `ennote.entitlements` and `ennoteWidgetExtension.entitlements`
3. Update `AppGroup.identifier` in `Shared/AppGroup.swift`

### Force Unwraps

**Avoid** except in these safe contexts:
- `chars.randomElement()!` - collection known to be non-empty
- Sample data construction where failure is acceptable: `Note.sampleNotes[0]`
- Never in production data paths

### Color Palette

**Defined in Theme.swift** - refer to `spec.md` for full palette.

Key colors:
- Background: `#171717`
- Surface: `#212121`
- Text Primary: `#FAFAFA`
- Accent: `#FBBF23` (yellow)
- Success: `#4ADE80` (green for completed notes)

**Pattern**: Use `Color(hex: "#171717")` extension defined in Theme.swift.

---

## Testing

**Current state**: No automated tests exist.

**Manual testing workflow:**
1. Build and run in iOS Simulator
2. Add notes, complete them, delete them
3. Test widgets in widget gallery (long press home screen)
4. Test iCloud sync between devices (if available)

**Future**: Consider adding XCTest suite for:
- Note CRUD operations
- Widget timeline generation

---

## Git Workflow

**Commit message style:**
```
feat: brief description of feature
fix: brief description of bug fix
```

**Pattern observed:**
- Short, lowercase descriptions
- Commits are granular per feature
- No body text in commits (all context in code)

**Examples from history:**
```
feat: mess with styles to look nicer
feat: better edit and delete as well as two line notes
feat: update widgets and icon
feat: inital version
```

**No PR workflow** - direct commits to `main` (personal project).

---

## Data Flow

### Local Notes (Personal)

```
User Input → SwiftUI View (@Environment(\.modelContext))
          ↓
     SwiftData (Note model)
          ↓
    ModelContext.save()
          ↓
     App Group Container (if available)
          ↓
     Widget reads via NoteStorage.makeContainer()
```

### iCloud Sync (Future)

Not yet implemented. When added:
- Use CloudKit Private DB for user's personal notes
- SwiftData + CloudKit integration
- Automatic sync across user's devices

---

## Common Tasks

### Adding a New View

1. Create the file in `ennote/ennote/Views/`
2. Use SwiftUI `View` protocol
3. Add `#Preview` macro at bottom for live preview
4. Build to ensure no errors

**No project file edit needed.** The project uses file-system-synchronized groups
(`objectVersion = 77`), so any file inside `ennote/`, `ennoteWidget/`, or `Shared/`
joins the matching target automatically. `Shared/` belongs to both targets.

One exception: the widget's `Info.plist` lives at the project root as
`ennoteWidget-Info.plist`, because a plist inside a synchronized folder gets copied
into the bundle as a resource and collides with the generated one.

Example:
```swift
import SwiftUI

struct MyNewView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    MyNewView()
}
```

### Adding a New Model Property

1. Add property to model in `Shared/Note.swift`
2. SwiftData handles migrations automatically for simple changes
3. Update convenience methods if needed
4. Rebuild - SwiftData will migrate existing data

**Gotcha**: Complex schema changes (relationships, renames) may require manual migration.

### Updating Widget

1. Make changes to `ennoteWidget/ennoteWidget.swift`
2. Ensure widget target is selected in scheme
3. Build and run widget scheme to test
4. Refresh widget in gallery: Long press → Edit Widgets

**Gotcha**: Widgets cache aggressively. Force quit app and remove/re-add widget to see changes.

### Modifying Theme/Colors

1. Edit `App/Theme.swift` for programmatic colors
2. Edit `Resources/Assets.xcassets/` for asset catalog colors
3. Use `Color(hex: "#RRGGBB")` for custom colors
4. Follow palette defined in `spec.md`

---

## Troubleshooting

### "App Group not available" in logs

**Cause**: Using free Apple Developer account (personal team).

**Solution**: Either:
- Ignore - app works fine, widgets won't show data
- Upgrade to paid Apple Developer Program ($99/year)
- Enable App Groups in Signing & Capabilities

### Widget shows "No notes" despite having notes

**Causes**:
1. App Group not available (see above)
2. Widget not refreshing after changes
3. Widget and app using different data containers

**Solutions**:
1. Check if `AppGroup.containerURL` is nil
2. Ensure `WidgetCenter.shared.reloadAllTimelines()` is called after mutations
3. Verify both targets have same App Group identifier

### SwiftData "Failed to create ModelContainer"

**Cause**: Schema conflict or migration issue.

**Solution**:
- Delete app from simulator/device (clears all data)
- Reset simulator: Device → Erase All Content and Settings
- Check model definition for obvious errors

---

## Architecture Decisions

### Why SwiftData over Core Data?

- Modern Swift-first API
- Less boilerplate than Core Data
- Built-in iCloud sync support (when implemented)
- Macro-based model definition is cleaner

### Why MainActor by default?

- Nearly all of this app is SwiftUI views and SwiftData mutations, both main-thread
- Opting the whole module in removes the annotation noise
- The few pieces the widget and intents touch off the main actor are marked `nonisolated`

### Why widgets instead of complications?

- Complications require watchOS app (not yet built)
- Widgets work on iPhone lock screen (iOS 16+)
- More screen space for note content
- Plan to add watchOS later

---

## Future Work

See `spec.md` Phase 4 and 5 for planned features.

**Next priorities** (inferred from incomplete features):
1. Full CloudKit sync for personal notes
2. Watch app (glanceable note view)
3. Shortcuts integration ("Add to enɳoté" action)
4. Comprehensive test suite

---

## Resources

- **Design Spec**: See `spec.md` for complete architecture and design decisions
- **Apple Documentation**:
  - [SwiftData](https://developer.apple.com/documentation/swiftdata)
  - [CloudKit](https://developer.apple.com/documentation/cloudkit)
  - [WidgetKit](https://developer.apple.com/documentation/widgetkit)
  - [App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- **Inspiration**: [Laurie Herault's Stack app](https://laurieherault.com)

---

## Contact & Repository

- **Author**: Kieran Klukas ([@dunkirk.sh](https://dunkirk.sh))
- **Canonical Repo**: [tangled.org/@dunkirk.sh/ennote](https://tangled.org/@dunkirk.sh/ennote)
- **License**: O'Saasy (see LICENSE.md)

---

## Quick Reference

**File to edit for...**

| Task | File |
|------|------|
| Add new model property | `ennote/Shared/Note.swift` |
| Change app colors | `ennote/ennote/Resources/Assets.xcassets` |
| Modify main list view | `ennote/ennote/Views/NoteListView.swift` |
| Update widget layout | `ennoteWidget/ennoteWidget.swift` |
| Modify note CRUD | `ennote/ennote/Views/NoteListView.swift` |
| Update App Group ID | `ennote/Shared/AppGroup.swift` |

**Commands:**

| Task | Command |
|------|---------|
| View git history | `git log --oneline -20` |
| Check Xcode project info | `xcodebuild -list -project ennote/ennote.xcodeproj` |

---

*Last updated: 2026-08-31*

# AGENTS.md

Documentation for AI agents working in the ennote codebase.

---

## Project Overview

**enɳoté** (pronounced: en-no-TAY) is a Stack-inspired micro-note app for quick capture and focused execution. Built with Swift/SwiftUI for iOS with a companion web app for desktop note preparation.

**Philosophy**: Break tasks into micro-notes. Prepare on desktop, execute on phone. Notes are ephemeral by design—captured quickly, completed quickly, then gone.

---

## Project Structure

```
ennote/
├── web/                              # Vanilla HTML/CSS/JS web app
│   ├── app.js                        # QR stack creation logic
│   ├── index.html                    # Single-page desktop interface
│   └── styles.css                    # Dark theme styling
├── ennote/                           # Xcode project root
│   ├── ennote/                       # Main iOS app
│   │   ├── App/                      # App entry and global state
│   │   │   ├── ennoteApp.swift       # @main entry point, SwiftData setup
│   │   │   ├── ContentView.swift     # Root view with tab/mode switching
│   │   │   └── Theme.swift           # Color palette and styling constants
│   │   ├── Models/                   # Data models
│   │   │   ├── Note.swift            # @Model SwiftData note entity
│   │   │   └── Stack.swift           # CloudKit QR transfer model
│   │   ├── Views/                    # SwiftUI views
│   │   │   ├── NoteListView.swift    # Main list view with @Query
│   │   │   ├── NoteRow.swift         # Individual note with swipe actions
│   │   │   ├── AddNoteField.swift    # Quick-add input field
│   │   │   ├── AddNoteSheet.swift    # Modal for adding notes
│   │   │   ├── EditNoteSheet.swift   # Modal for editing notes
│   │   │   ├── FloatingAddButton.swift # FAB for adding notes
│   │   │   ├── StackView.swift       # Focus mode - one note at a time
│   │   │   └── ScannerView.swift     # QR code scanner
│   │   ├── Services/                 # Business logic
│   │   │   ├── NoteStore.swift       # @MainActor note CRUD operations
│   │   │   └── CloudKitService.swift # actor for CloudKit sync
│   │   └── Resources/                # Assets and config
│   │       ├── Assets.xcassets/      # Images, colors, icons
│   │       ├── ennote.entitlements   # iCloud + App Groups
│   │       └── Info.plist            # App configuration
│   ├── ennoteWidget/                 # Widget extension
│   │   ├── ennoteWidget.swift        # Widget timeline provider
│   │   ├── InteractiveWidget.swift   # iOS 17+ interactive buttons
│   │   └── ennoteWidgetExtension.entitlements
│   ├── Shared/                       # Code shared between app and widget
│   │   ├── AppGroup.swift            # App Group constants and helpers
│   │   └── Settings.swift            # Shared settings/preferences
│   └── ennote.xcodeproj/             # Xcode project file
├── spec.md                           # Comprehensive design document
├── README.md                         # Project overview
└── LICENSE.md                        # O'Saasy license
```

---

## Technology Stack

### iOS App
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (iOS 17+)
- **Sync**: CloudKit (private + public databases)
- **Minimum Deployment**: iOS 17.0
- **Widgets**: WidgetKit with App Intents (iOS 17+)
- **QR Scanning**: AVFoundation (VisionKit alternative)

### Web App
- **Stack**: Vanilla HTML/CSS/JavaScript
- **QR Generation**: qrcode.js library
- **CloudKit**: CloudKit JS SDK (for public DB writes)
- **Hosting**: Static files (Vercel, Cloudflare Pages, GitHub Pages)

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

### Web App

**Run locally:**
```bash
cd web
python3 -m http.server 8000
# Open http://localhost:8000
```

**Deploy:**
- No build step required - just deploy the `web/` directory to any static host
- Ensure CloudKit JS SDK is configured with the correct container ID

---

## Code Conventions

### Swift Style

**Naming:**
- `camelCase` for variables, functions, properties: `activeNotes`, `completeNote()`, `isCompleted`
- `PascalCase` for types: `Note`, `NoteStore`, `CloudKitService`
- Prefix private functions with `private`: `private func setupContainer()`
- Descriptive names over brevity: `fetchStackFromCloudKit()` not `fetchStack()`

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
- `@MainActor` for UI-bound classes: `@MainActor final class NoteStore`
- `actor` for thread-safe services: `actor CloudKitService`
- No explicit `@MainActor` needed in SwiftUI views (implicit)
- `async/await` for CloudKit operations
- `Task { }` for launching async work from sync context

**Error Handling:**
- Try-catch with optional fallback: `(try? context.fetch(descriptor)) ?? []`
- Guard-let for early returns: `guard let container = modelContainer else { return }`
- Print for non-critical errors: `print("Widget failed: \(error)")`
- `fatalError()` only for unrecoverable setup issues
- CloudKit errors checked by type: `catch let error as CKError where error.code == .unknownItem`

**Comments:**
- Triple-slash for type documentation: `/// CloudKit service for syncing notes`
- Inline for non-obvious logic: `// 5 min TTL`
- Multi-line blocks for complex patterns
- **Don't over-comment** - prefer self-documenting code
- **Never add "what" comments** - focus on "why" if needed

### JavaScript Style (Web App)

**Structure:**
- IIFE wrapper: `(function() { 'use strict'; ... })()`
- Constants at top: `const EXPIRY_MINUTES = 5;`
- DOM element references cached
- Pure functions where possible
- No framework - vanilla JS

**Naming:**
- `camelCase` for everything: `generateStackId()`, `parseNotes()`
- `SCREAMING_SNAKE_CASE` for constants: `STACK_ID_LENGTH`

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

// Usage in NoteStore.swift and ennoteApp.swift
if AppGroup.containerURL != nil {
    // Use App Group container (shared with widget)
    let config = ModelConfiguration(groupContainer: .identifier(AppGroup.identifier))
    modelContainer = try ModelContainer(for: Note.self, configurations: config)
} else {
    // Fall back to default container (local only, widget won't work)
    modelContainer = try ModelContainer(for: Note.self)
}
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

**Pattern used in NoteStore.swift:**
- Every function that modifies data calls `reloadWidgets()`
- Centralized helper avoids forgetting to refresh

### Toggle Dwell Time

**Pattern**: Notes have a 0.65s delay before completing/uncompleting for smooth animation.

```swift
// In NoteRow.swift and widgets
Task {
    try? await Task.sleep(for: .seconds(0.65))
    note.isCompleted.toggle()
    // ... save and refresh
}
```

**Why**: Gives time for swipe animation and haptic feedback before state change.

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
4. Update web app's CloudKit JS SDK configuration

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
4. Test QR flow: Web app → Generate QR → Scan in iOS app
5. Test iCloud sync between devices (if available)

**Future**: Consider adding XCTest suite for:
- Note CRUD operations
- CloudKit sync logic
- Stack QR generation/parsing
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
     Widget reads via NoteStore.shared.activeNotes
```

### QR Transfer (Web → iOS)

```
Web App:
  User enters notes → Generate random Stack ID
                  ↓
            Save to CloudKit Public DB
                  ↓
            Generate QR: ennote://stack/{id}
                  ↓
            Display with 5-min countdown

iOS App:
  Scan QR → Extract Stack ID from URL
         ↓
    Fetch Stack from CloudKit Public DB
         ↓
    Import notes to local SwiftData
         ↓
    Mark Stack as fetched (or delete immediately)
```

### iCloud Sync (Future)

Not yet implemented. When added:
- Use CloudKit Private DB for user's personal notes
- SwiftData + CloudKit integration
- Automatic sync across user's devices

---

## Common Tasks

### Adding a New View

1. Create file in `ennote/ennote/Views/`
2. Use SwiftUI `View` protocol
3. Add `#Preview` macro at bottom for live preview
4. Import view in parent (usually `ContentView.swift`)
5. Build to ensure no errors

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

1. Add property to model in `Models/Note.swift`
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

### Web App Modifications

1. Edit `web/app.js`, `web/index.html`, or `web/styles.css`
2. No build step - refresh browser
3. Test QR generation with sample notes
4. **Don't test CloudKit writes** without valid container config

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

### CloudKit errors in console

**Cause**: CloudKit container not configured or user not signed into iCloud.

**Solution**:
- Ensure user is signed into iCloud on device
- Verify entitlements include correct container ID
- Check Apple Developer portal for container status

### SwiftData "Failed to create ModelContainer"

**Cause**: Schema conflict or migration issue.

**Solution**:
- Delete app from simulator/device (clears all data)
- Reset simulator: Device → Erase All Content and Settings
- Check model definition for obvious errors

### Web app QR code not generating

**Causes**:
1. JavaScript error (check console)
2. Missing qrcode.js library

**Solutions**:
1. Open browser dev tools, check console
2. Verify qrcode.js is loaded in HTML

---

## Architecture Decisions

### Why SwiftData over Core Data?

- Modern Swift-first API
- Less boilerplate than Core Data
- Built-in iCloud sync support (when implemented)
- Macro-based model definition is cleaner

### Why actor for CloudKitService?

- CloudKit operations are async and may be called from multiple contexts
- Actor ensures thread-safe access without manual locks
- Async/await integration is cleaner than callbacks

### Why @MainActor for NoteStore?

- NoteStore is primarily accessed from SwiftUI views (main thread)
- Avoiding thread-hopping improves performance
- SwiftData ModelContext requires main thread access

### Why vanilla JS for web app?

- No build step = instant iteration
- Simple deployment (just static files)
- App is single-page, minimal complexity
- Framework would be overkill for QR generation

### Why widgets instead of complications?

- Complications require watchOS app (not yet built)
- Widgets work on iPhone lock screen (iOS 16+)
- More screen space for note content
- Plan to add watchOS later

---

## Future Work

See `spec.md` Phase 4 and 5 for planned features.

**Next priorities** (inferred from incomplete features):
1. Full CloudKit sync for personal notes (currently only QR transfer works)
2. Stack mode improvements (timer, progress animations)
3. Watch app (glanceable note view)
4. Shortcuts integration ("Add to enɳoté" action)
5. Comprehensive test suite

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
| Add new model property | `ennote/ennote/Models/Note.swift` |
| Change app colors | `ennote/ennote/App/Theme.swift` |
| Modify main list view | `ennote/ennote/Views/NoteListView.swift` |
| Update widget layout | `ennoteWidget/ennoteWidget.swift` |
| Change CloudKit logic | `ennote/ennote/Services/CloudKitService.swift` |
| Modify note CRUD | `ennote/ennote/Services/NoteStore.swift` |
| Update App Group ID | `ennote/Shared/AppGroup.swift` |
| Web app QR logic | `web/app.js` |
| Web app styling | `web/styles.css` |

**Commands:**

| Task | Command |
|------|---------|
| Run local web server | `cd web && python3 -m http.server 8000` |
| View git history | `git log --oneline -20` |
| Check Xcode project info | `xcodebuild -list -project ennote/ennote.xcodeproj` |

---

*Last updated: 2025-01-26*

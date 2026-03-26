# ClosuresDemo — Xcode Project Setup

## Step 1: Create the Xcode Project

1. Open **Xcode**
2. **File → New → Project** (⇧⌘N)
3. Choose **iOS → App**
4. Set:
   - Product Name: `ClosuresDemo`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Include Tests: ✅ Yes
5. Save to `/Users/zypherman/Developer/ClosuresDemo`

## Step 2: Add the Source Files

Delete the generated `ContentView.swift`. Then in the Project Navigator:

1. Right-click on the `ClosuresDemo` group → **Add Files to "ClosuresDemo"…**
2. Select all files from this directory. Match the groups:

```
ClosuresDemo/
├── ClosuresDemoApp.swift       ← replace the generated one
├── ContentView.swift
├── Shared/                     ← New Group
│   ├── EvalCounter.swift
│   ├── Handler.swift
│   └── DemoComponents.swift
└── Demos/                      ← New Group
    ├── Demo1_EnvironmentClosure.swift
    ├── Demo2_ViewPropertyClosure.swift
    └── Demo3_BestPractice.swift
```

3. For the Tests target, add:
```
ClosuresDemoTests/
└── ClosureBehaviorTests.swift  ← replace the generated one
```

## Step 3: Verify the Build

**⌘B** — should compile with zero errors.

> Note: SourceKit shows "symbol not found" errors when editing individual files
> because symbols live in other files. These resolve inside the full Xcode project.

## Step 4: Run the App

**⌘R** — app launches on Simulator showing the three-demo navigation list.

## Step 5: Run the Performance Tests

**⌘U** — all tests run. After the first run:
- Click the clock icon next to each `measure {}` call in the test results
- Choose **"Set Baseline"** so future regressions are flagged automatically

## Step 6: Profile in Instruments

1. **⌘I** (Product → Profile) — choose **Time Profiler** template
2. Click **Record**, then interact with the demo app
3. **Add the "Points of Interest" instrument** from the `+` button in the toolbar
4. Filter by subsystem: `com.ClosuresDemo`
5. Run the **Stress Test** buttons in Demo 1 and Demo 2
6. Compare the event density between `Demo1-Bad.Child` and `Demo1-Good.Child`

The bad child shows 50+ events for 50 state changes.
The good child shows 1–2 events for the same 50 changes.

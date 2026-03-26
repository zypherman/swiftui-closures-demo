#!/usr/bin/env python3
"""
Generates a minimal valid ClosuresDemo.xcodeproj for Xcode 26 / iOS 26.

Usage: python3 generate_xcodeproj.py
Run from: /Users/zypherman/Developer/ClosuresDemo/
"""

import os
import uuid

# ── UUID factory ──────────────────────────────────────────────────────────────
def uid():
    """24-char uppercase hex UUID (pbxproj convention)."""
    return uuid.uuid4().hex.upper()[:24]

# ── Fixed UUIDs (stable so regenerating the script gives same project) ────────
IDS = {
    # Project
    "project":              "8A1B2C3D4E5F6A7B8C9D0E1F",
    "main_group":           "8A1B2C3D4E5F6A7B8C9D0E20",
    "products_group":       "8A1B2C3D4E5F6A7B8C9D0E21",
    "shared_group":         "8A1B2C3D4E5F6A7B8C9D0E22",
    "demos_group":          "8A1B2C3D4E5F6A7B8C9D0E23",
    "tests_group":          "8A1B2C3D4E5F6A7B8C9D0E24",

    # App target
    "app_target":           "AA000000000000000000001",
    "app_sources_phase":    "AA000000000000000000002",
    "app_frameworks_phase": "AA000000000000000000003",
    "app_resources_phase":  "AA000000000000000000004",
    "app_debug_config":     "AA000000000000000000005",
    "app_release_config":   "AA000000000000000000006",
    "app_config_list":      "AA000000000000000000007",
    "app_product":          "AA000000000000000000008",

    # Test target
    "test_target":          "BB000000000000000000001",
    "test_sources_phase":   "BB000000000000000000002",
    "test_frameworks_phase":"BB000000000000000000003",
    "test_debug_config":    "BB000000000000000000004",
    "test_release_config":  "BB000000000000000000005",
    "test_config_list":     "BB000000000000000000006",
    "test_product":         "BB000000000000000000007",

    # Project config list
    "proj_debug_config":    "CC000000000000000000001",
    "proj_release_config":  "CC000000000000000000002",
    "proj_config_list":     "CC000000000000000000003",

    # SwiftUI + Foundation framework refs
    "swiftui_framework":    "DD000000000000000000001",
    "foundation_framework": "DD000000000000000000002",
    "xctest_framework":     "DD000000000000000000003",
}

# ── Source files ─────────────────────────────────────────────────────────────
APP_FILES = [
    # (display_name, relative_path, uuid_ref, uuid_build)
    ("ClosuresDemoApp.swift",          "ClosuresDemoApp.swift",                    "F0000000000000000000001", "F1000000000000000000001"),
    ("ContentView.swift",              "ContentView.swift",                        "F0000000000000000000002", "F1000000000000000000002"),
    ("EvalCounter.swift",              "Shared/EvalCounter.swift",                 "F0000000000000000000003", "F1000000000000000000003"),
    ("Handler.swift",                  "Shared/Handler.swift",                     "F0000000000000000000004", "F1000000000000000000004"),
    ("DemoComponents.swift",           "Shared/DemoComponents.swift",              "F0000000000000000000005", "F1000000000000000000005"),
    ("Demo1_EnvironmentClosure.swift", "Demos/Demo1_EnvironmentClosure.swift",     "F0000000000000000000006", "F1000000000000000000006"),
    ("Demo2_ViewPropertyClosure.swift","Demos/Demo2_ViewPropertyClosure.swift",    "F0000000000000000000007", "F1000000000000000000007"),
    ("Demo3_BestPractice.swift",       "Demos/Demo3_BestPractice.swift",           "F0000000000000000000008", "F1000000000000000000008"),
]

TEST_FILES = [
    ("ClosureBehaviorTests.swift", "ClosuresDemoTests/ClosureBehaviorTests.swift", "F0000000000000000000009", "F1000000000000000000009"),
]

SHARED_FILES = APP_FILES[2:5]   # EvalCounter, Handler, DemoComponents (indices 2–4)
DEMOS_FILES  = APP_FILES[5:]    # Demo1–3 (indices 5–7)
ROOT_FILES   = APP_FILES[:2]    # App + ContentView (indices 0–1)


def pbxproj():
    lines = []

    def section(name, entries):
        lines.append(f"\n/* Begin {name} section */")
        for e in entries:
            lines.append(e)
        lines.append(f"/* End {name} section */")

    # ── PBXBuildFile ───────────────────────────────────────────────────────────
    build_files = []
    for name, path, ref_id, build_id in APP_FILES + TEST_FILES:
        build_files.append(f"\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {name} */; }};")

    section("PBXBuildFile", build_files)

    # ── PBXFileReference ───────────────────────────────────────────────────────
    file_refs = []
    for name, path, ref_id, build_id in APP_FILES + TEST_FILES:
        ft = "sourcecode.swift"
        file_refs.append(f'\t\t{ref_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; path = {name}; sourceTree = "<group>"; }};')

    file_refs.append(f'\t\t{IDS["app_product"]} /* ClosuresDemo.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ClosuresDemo.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    file_refs.append(f'\t\t{IDS["test_product"]} /* ClosuresDemoTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = ClosuresDemoTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')

    section("PBXFileReference", file_refs)

    # ── PBXFrameworksBuildPhase ─────────────────────────────────────────────────
    fw_phases = []
    fw_phases.append(f"""
\t\t{IDS['app_frameworks_phase']} = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")
    fw_phases.append(f"""
\t\t{IDS['test_frameworks_phase']} = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")
    section("PBXFrameworksBuildPhase", fw_phases)

    # ── PBXGroup ────────────────────────────────────────────────────────────────
    groups = []

    # Main group
    groups.append(f"""
\t\t{IDS['main_group']} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{IDS['shared_group']} /* Shared */,
\t\t\t\t{IDS['demos_group']} /* Demos */,
\t\t\t\t{ROOT_FILES[0][2]} /* {ROOT_FILES[0][0]} */,
\t\t\t\t{ROOT_FILES[1][2]} /* {ROOT_FILES[1][0]} */,
\t\t\t\t{IDS['tests_group']} /* ClosuresDemoTests */,
\t\t\t\t{IDS['products_group']} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};""")

    # Products group
    groups.append(f"""
\t\t{IDS['products_group']} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{IDS['app_product']} /* ClosuresDemo.app */,
\t\t\t\t{IDS['test_product']} /* ClosuresDemoTests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    # Shared group
    shared_children = "\n".join(f"\t\t\t\t{f[2]} /* {f[0]} */," for f in SHARED_FILES)
    groups.append(f"""
\t\t{IDS['shared_group']} /* Shared */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{shared_children}
\t\t\t);
\t\t\tpath = Shared;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    # Demos group
    demos_children = "\n".join(f"\t\t\t\t{f[2]} /* {f[0]} */," for f in DEMOS_FILES)
    groups.append(f"""
\t\t{IDS['demos_group']} /* Demos */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{demos_children}
\t\t\t);
\t\t\tpath = Demos;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    # Tests group
    test_children = "\n".join(f"\t\t\t\t{f[2]} /* {f[0]} */," for f in TEST_FILES)
    groups.append(f"""
\t\t{IDS['tests_group']} /* ClosuresDemoTests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{test_children}
\t\t\t);
\t\t\tpath = ClosuresDemoTests;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    section("PBXGroup", groups)

    # ── PBXNativeTarget ─────────────────────────────────────────────────────────
    targets = []
    targets.append(f"""
\t\t{IDS['app_target']} /* ClosuresDemo */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {IDS['app_config_list']} /* Build configuration list for PBXNativeTarget "ClosuresDemo" */;
\t\t\tbuildPhases = (
\t\t\t\t{IDS['app_sources_phase']} /* Sources */,
\t\t\t\t{IDS['app_frameworks_phase']} /* Frameworks */,
\t\t\t\t{IDS['app_resources_phase']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = ClosuresDemo;
\t\t\tproductName = ClosuresDemo;
\t\t\tproductReference = {IDS['app_product']} /* ClosuresDemo.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};""")
    targets.append(f"""
\t\t{IDS['test_target']} /* ClosuresDemoTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {IDS['test_config_list']} /* Build configuration list for PBXNativeTarget "ClosuresDemoTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{IDS['test_sources_phase']} /* Sources */,
\t\t\t\t{IDS['test_frameworks_phase']} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = ClosuresDemoTests;
\t\t\tproductName = ClosuresDemoTests;
\t\t\tproductReference = {IDS['test_product']} /* ClosuresDemoTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};""")
    section("PBXNativeTarget", targets)

    # ── PBXProject ──────────────────────────────────────────────────────────────
    proj = [f"""
\t\t{IDS['project']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 2630;
\t\t\t\tLastUpgradeCheck = 2630;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{IDS['app_target']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 26.3;
\t\t\t\t\t}};
\t\t\t\t\t{IDS['test_target']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 26.3;
\t\t\t\t\t\tTestTargetID = {IDS['app_target']};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {IDS['proj_config_list']} /* Build configuration list for PBXProject "ClosuresDemo" */;
\t\t\tcompatibilityVersion = "Xcode 26.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {IDS['main_group']};
\t\t\tproductRefGroup = {IDS['products_group']} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{IDS['app_target']} /* ClosuresDemo */,
\t\t\t\t{IDS['test_target']} /* ClosuresDemoTests */,
\t\t\t);
\t\t}};"""]
    section("PBXProject", proj)

    # ── PBXResourcesBuildPhase ──────────────────────────────────────────────────
    res = [f"""
\t\t{IDS['app_resources_phase']} = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""]
    section("PBXResourcesBuildPhase", res)

    # ── PBXSourcesBuildPhase ────────────────────────────────────────────────────
    sources = []

    app_sources = "\n".join(f"\t\t\t\t{f[3]} /* {f[0]} in Sources */," for f in APP_FILES)
    sources.append(f"""
\t\t{IDS['app_sources_phase']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{app_sources}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")

    test_sources = "\n".join(f"\t\t\t\t{f[3]} /* {f[0]} in Sources */," for f in TEST_FILES)
    # Tests also need Shared files
    shared_in_test = "\n".join(f"\t\t\t\t{f[3]} /* {f[0]} in Sources */," for f in SHARED_FILES)
    sources.append(f"""
\t\t{IDS['test_sources_phase']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{test_sources}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")

    section("PBXSourcesBuildPhase", sources)

    # ── XCBuildConfiguration ─────────────────────────────────────────────────────
    configs = []

    # App Debug
    configs.append(f"""
\t\t{IDS['app_debug_config']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSET_CATALOG_COMPILER_ASSETS_OPTIMIZATIONS = space;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;
\t\t\t\tLE_SWIFT_VERSION = 6.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.closuresdemo.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")

    # App Release
    configs.append(f"""
\t\t{IDS['app_release_config']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSET_CATALOG_COMPILER_ASSETS_OPTIMIZATIONS = space;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.closuresdemo.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")

    # Test Debug
    configs.append(f"""
\t\t{IDS['test_debug_config']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.closuresdemo.tests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/ClosuresDemo.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ClosuresDemo";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")

    # Test Release
    configs.append(f"""
\t\t{IDS['test_release_config']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.closuresdemo.tests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/ClosuresDemo.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ClosuresDemo";
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")

    # Project Debug
    configs.append(f"""
\t\t{IDS['proj_debug_config']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_NAMES = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")

    # Project Release
    configs.append(f"""
\t\t{IDS['proj_release_config']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")

    section("XCBuildConfiguration", configs)

    # ── XCConfigurationList ──────────────────────────────────────────────────────
    config_lists = [f"""
\t\t{IDS['app_config_list']} /* Build configuration list for PBXNativeTarget "ClosuresDemo" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{IDS['app_debug_config']} /* Debug */,
\t\t\t\t{IDS['app_release_config']} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{IDS['test_config_list']} /* Build configuration list for PBXNativeTarget "ClosuresDemoTests" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{IDS['test_debug_config']} /* Debug */,
\t\t\t\t{IDS['test_release_config']} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{IDS['proj_config_list']} /* Build configuration list for PBXProject "ClosuresDemo" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{IDS['proj_debug_config']} /* Debug */,
\t\t\t\t{IDS['proj_release_config']} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};"""]
    section("XCConfigurationList", config_lists)

    # ── Assemble ─────────────────────────────────────────────────────────────────
    body = "\n".join(lines)
    return f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 77;
\tobjects = {{{body}
\t}};
\trootObject = {IDS['project']} /* Project object */;
}}
"""


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    proj_dir = os.path.join(base, "ClosuresDemo.xcodeproj")
    os.makedirs(proj_dir, exist_ok=True)

    pbxproj_path = os.path.join(proj_dir, "project.pbxproj")
    with open(pbxproj_path, "w") as f:
        f.write(pbxproj())

    print(f"✅ Generated: {pbxproj_path}")
    print("   Open with: open ClosuresDemo.xcodeproj")


if __name__ == "__main__":
    main()

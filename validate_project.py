#!/usr/bin/env python3
"""
validate_project.py - Waypoint Lab Cross-Platform Validation Script
Verifies project file structure, GPX XML validity, Info.plist schema,
PBX project reference integrity, and Swift syntax sanity.
"""

import os
import sys
import re
import xml.etree.ElementTree as ET

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.join(BASE_DIR, "WaypointLab")
XCODEPROJ_PATH = os.path.join(BASE_DIR, "WaypointLab.xcodeproj", "project.pbxproj")
INFO_PLIST_PATH = os.path.join(PROJECT_DIR, "Resources", "Info.plist")
SAMPLE_GPX_PATH = os.path.join(PROJECT_DIR, "Resources", "SampleRoute.gpx")

REQUIRED_SOURCE_FILES = [
    os.path.join(PROJECT_DIR, "WaypointLabApp.swift"),
    os.path.join(PROJECT_DIR, "Models", "Waypoint.swift"),
    os.path.join(PROJECT_DIR, "Models", "RoutePoint.swift"),
    os.path.join(PROJECT_DIR, "Services", "LocationManager.swift"),
    os.path.join(PROJECT_DIR, "Services", "SearchService.swift"),
    os.path.join(PROJECT_DIR, "Services", "RouteSimulationManager.swift"),
    os.path.join(PROJECT_DIR, "Services", "FavoritesManager.swift"),
    os.path.join(PROJECT_DIR, "Views", "MainTabView.swift"),
    os.path.join(PROJECT_DIR, "Views", "MapView.swift"),
    os.path.join(PROJECT_DIR, "Views", "ManualCoordinateView.swift"),
    os.path.join(PROJECT_DIR, "Views", "SearchView.swift"),
    os.path.join(PROJECT_DIR, "Views", "RouteSimulationView.swift"),
    os.path.join(PROJECT_DIR, "Views", "FavoritesView.swift"),
    os.path.join(PROJECT_DIR, "Views", "SettingsView.swift"),
    INFO_PLIST_PATH,
    SAMPLE_GPX_PATH,
    XCODEPROJ_PATH,
]

def check_file_existence():
    print("[1/5] Checking file structure integrity...")
    missing = []
    for file_path in REQUIRED_SOURCE_FILES:
        if not os.path.isfile(file_path):
            missing.append(file_path)
            print(f"  [FAIL] Missing file: {file_path}")
        else:
            rel = os.path.relpath(file_path, BASE_DIR)
            print(f"  [PASS] Found: {rel}")
    if missing:
        raise RuntimeError(f"Missing {len(missing)} required project files.")
    print("  -> File structure verified successfully.\n")

def check_gpx_validity():
    print("[2/5] Validating SampleRoute.gpx XML & coordinates...")
    if not os.path.isfile(SAMPLE_GPX_PATH):
        raise FileNotFoundError(f"GPX file not found: {SAMPLE_GPX_PATH}")
    
    tree = ET.parse(SAMPLE_GPX_PATH)
    root = tree.getroot()
    
    # Strip namespaces for generic element search
    trackpoints = []
    for elem in root.iter():
        if elem.tag.endswith("trkpt") or elem.tag.endswith("wpt"):
            trackpoints.append(elem)
            
    print(f"  [INFO] Extracted {len(trackpoints)} trackpoints from GPX.")
    if len(trackpoints) == 0:
        raise ValueError("GPX contains no track points (<trkpt>).")
        
    for idx, pt in enumerate(trackpoints):
        lat_str = pt.attrib.get("lat")
        lon_str = pt.attrib.get("lon")
        if lat_str is None or lon_str is None:
            raise ValueError(f"Trackpoint #{idx} missing lat/lon attributes.")
        lat = float(lat_str)
        lon = float(lon_str)
        if not (-90.0 <= lat <= 90.0):
            raise ValueError(f"Trackpoint #{idx} latitude out of bounds: {lat}")
        if not (-180.0 <= lon <= 180.0):
            raise ValueError(f"Trackpoint #{idx} longitude out of bounds: {lon}")
            
    print(f"  [PASS] All {len(trackpoints)} coordinates conform to standard WGS84 bounds [-90,90] and [-180,180].")
    print("  -> GPX schema and coordinate validation passed.\n")

def check_plist():
    print("[3/5] Validating Info.plist XML & Privacy Keys...")
    tree = ET.parse(INFO_PLIST_PATH)
    root = tree.getroot()
    dict_elem = root.find("dict")
    if dict_elem is None:
        raise ValueError("Info.plist missing top-level <dict> element.")
        
    keys = [k.text for k in dict_elem.findall("key")]
    required_keys = [
        "CFBundleDisplayName",
        "CFBundleIdentifier",
        "NSLocationWhenInUseUsageDescription",
        "LSRequiresIPhoneOS"
    ]
    for rk in required_keys:
        if rk not in keys:
            raise KeyError(f"Info.plist missing required key: {rk}")
        print(f"  [PASS] Required key present: {rk}")
    print("  -> Info.plist validation passed.\n")

def check_pbxproj():
    print("[4/5] Checking Xcode project.pbxproj file references...")
    with open(XCODEPROJ_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Search for all registered file paths in PBXFileReference
    file_ref_pattern = re.compile(r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/', re.DOTALL)
    match = file_ref_pattern.search(content)
    if not match:
        raise ValueError("Unable to parse PBXFileReference section in project.pbxproj.")
        
    ref_section = match.group(1)
    file_names = re.findall(r'path = ([^;]+);', ref_section)
    
    for fn in file_names:
        clean_fn = fn.strip(' "')
        if clean_fn.endswith(".app"):
            continue
        # Search if this file exists anywhere under WaypointLab
        found = False
        for root, _, files in os.walk(PROJECT_DIR):
            if clean_fn in files:
                found = True
                break
        if not found:
            raise FileNotFoundError(f"PBXFileReference targets '{clean_fn}' but file is absent on disk.")
        print(f"  [PASS] Referenced file verified: {clean_fn}")
    print("  -> PBX project reference validation passed.\n")

def check_swift_syntax():
    print("[5/5] Performing static sanity check on Swift source files...")
    swift_files = [f for f in REQUIRED_SOURCE_FILES if f.endswith(".swift")]
    for sf in swift_files:
        with open(sf, "r", encoding="utf-8") as f:
            code = f.read()
            
        # Basic brace balance check
        open_braces = code.count("{")
        close_braces = code.count("}")
        if open_braces != close_braces:
            raise SyntaxError(f"Mismatched braces in {sf}: {open_braces} open vs {close_braces} close")
            
        open_parens = code.count("(")
        close_parens = code.count(")")
        if open_parens != close_parens:
            raise SyntaxError(f"Mismatched parentheses in {sf}: {open_parens} open vs {close_parens} close")
            
        # Check required imports
        if "struct " in code or "class " in code:
            has_import = "import Foundation" in code or "import SwiftUI" in code or "import CoreLocation" in code
            if not has_import:
                raise SyntaxError(f"Swift file missing core framework import: {sf}")
                
        rel = os.path.relpath(sf, BASE_DIR)
        print(f"  [PASS] Syntax sanity verified: {rel} ({len(code.splitlines())} lines)")
    print("  -> Swift static inspection passed.\n")

def main():
    print("==================================================")
    print("  Waypoint Lab - Project Validation Suite")
    print("==================================================\n")
    try:
        check_file_existence()
        check_gpx_validity()
        check_plist()
        check_pbxproj()
        check_swift_syntax()
        print("==================================================")
        print("  ALL VALIDATION CHECKS PASSED [OK]")
        print("==================================================")
        return 0
    except Exception as e:
        print(f"\n[VALIDATION FAILED]: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())

# Cattle Lineage/Family Tree Feature - Complete Guide

## Overview
The lineage feature allows you to track and visualize cattle family trees, including mothers (dams) and fathers (sires) across multiple generations.

## Features Implemented

### 1. Database Changes
- **New Field**: Added `sire_id` to cows table
- **Relationships**: 
  - `mother_id` (existing) - tracks the dam/mother
  - `sire_id` (new) - tracks the sire/father
  - Both create full parent-offspring relationships

### 2. Cow Model Enhancements
New methods added:
- `all_offspring` - Returns all calves (both as mother and as sire)
- `lineage_tree(depth)` - Builds a full lineage tree structure
- `ancestors(generations)` - Returns all ancestors up to N generations
- `descendants(generations)` - Returns all descendants up to N generations
- `pedigree_summary` - Returns a 3-generation pedigree summary

### 3. Visual Lineage Page
Access from any cow's detail page by clicking **"Family Tree"** button

#### Features:
- **3-Generation Pedigree Chart**: Visual diagram showing:
  - The cow
  - Parents (Mother & Sire)
  - Grandparents (all 4)
  
- **Ancestors List**: Shows all known ancestors
- **Descendants List**: Shows all offspring

- **Clickable Links**: Click any cow in the tree to view their lineage

### 4. Form Updates
When adding/editing a cow, you can now select:
- **Mother** - The dam/mother cow
- **Sire** - The father/bull

## How to Use

### Adding Parent Information

1. Go to any cow
2. Click "Edit Cow"
3. Scroll to "Mother (for calves)" and "Sire/Father" dropdowns
4. Select the appropriate parent cows
5. Save

### Viewing Lineage

1. Go to any cow's detail page
2. Click the green "Family Tree" button
3. View the pedigree chart showing 3 generations
4. Click any cow in the chart to navigate to their lineage

### Example Use Case (Based on Your Drawing)

Your drawing showed:
```
JOMO III
├── Jomo Heifer (Died/2022)
└── JOMO IV (1/1/2022)
    └── Jomo 5 Bull (21/11/2025)
```

To recreate this:

1. **Create/Edit JOMO III**:
   - Name: "JOMO III"
   - (Set as a foundation animal, no parents)

2. **Create JOMO IV**:
   - Name: "JOMO IV"
   - Birth Date: 1/1/2022
   - Mother: (select JOMO III if female) OR Sire: (select JOMO III if male)

3. **Create Jomo 5 Bull**:
   - Name: "Jomo 5 Bull"
   - Birth Date: 21/11/2025
   - Sire: JOMO IV (since it's a bull)

4. **View the lineage** by clicking "Family Tree" on any of these cows

## Technical Details

### Routes
- `/cows/:id/lineage` - Main lineage view
- Accessible via `lineage_cow_path(cow)`

### Controller
- `LineageController#show` - Displays lineage page
- Generates pedigree data, ancestors, and descendants

### Visual Design
- Bootstrap-based pedigree chart
- Color-coded boxes:
  - Purple gradient for the main cow
  - White for known parents/grandparents
  - Gray dashed for unknown ancestors
- Responsive layout (works on mobile)

## Benefits

1. **Breeding Program Management**: Track genetic lines
2. **Performance Analysis**: Compare offspring performance across different sires
3. **Avoid Inbreeding**: See relationships before breeding decisions
4. **Record Keeping**: Complete family history documentation
5. **Visual Clarity**: Easy-to-understand pedigree charts

## Next Steps

You can enhance this further by:
- Adding photos to the pedigree boxes
- Calculating inbreeding coefficients
- Tracking genetic traits
- Exporting pedigree certificates
- Adding more generations to the display

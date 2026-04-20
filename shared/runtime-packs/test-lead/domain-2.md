# 测试总监师 — Domain 2: UI Quality Assessment

## 2.1 Layout and Visual Evaluation

### 2.1.1 Layout Four-Factor

**Visual hierarchy**:
- Most important content is most prominent
- Headings establish clear information architecture
- Related content is grouped visually
- User attention flows naturally from primary to secondary

**Alignment**:
- Elements align to consistent grid lines
- No arbitrary offsets or misaligned edges
- Form fields align vertically
- Buttons align with form edges or grid

**Spacing**:
- Spacing follows design system scale (4px/8px base)
- Consistent spacing between similar elements
- Adequate whitespace between sections
- No cramped or overlapping content

**Whitespace**:
- Content has breathing room
- Not overloaded with information
- Margins and padding are balanced
- Mobile viewport does not feel cramped

**Common layout defects**:
- Content overflows container
- Horizontal scroll on mobile
- Elements overlap at certain viewports
- Footer not at bottom (short page)
- Modal not centered

### 2.1.2 Color and Contrast

**Brand color accuracy**:
- Colors match design token specifications
- No raw hex values where semantic tokens should be used
- Dark mode colors are correct (not just inverted)

**WCAG AA contrast verification**:

| Element Type | Minimum Ratio | Check Method |
|---|---|---|
| Normal text (< 18pt regular) | 4.5:1 | DevTools Accessibility panel |
| Large text (≥ 18pt regular, ≥ 14pt bold) | 3:1 | DevTools Accessibility panel |
| UI components (borders, icons) | 3:1 | DevTools Accessibility panel |
| Placeholder text | 4.5:1 (same as normal text) | DevTools Accessibility panel |

**Common contrast failures**:
- Light gray text on white (#999 on #fff ≈ 2.8:1)
- White text on light yellow
- Blue link text on blue background
- Disabled text that is too light to read

### 2.1.3 Typography Hierarchy

**Size ratios**:
- Title:body ratio is clear (e.g., 2:1 or greater)
- Caption/helper text is smaller than body
- No two levels are too similar in size

**Weight contrast**:
- Headings have heavier weight than body
- Bold text stands out from regular
- Not everything is bold (loses emphasis)

**Line height**:
- Body text: 1.4–1.6
- Headings: 1.2–1.3
- Captions: 1.3–1.5

**Common typography defects**:
- All text same size (no hierarchy)
- Line height too tight (text overlaps)
- Font stack not applied (fallback font visible)
- Text truncation without ellipsis

## 2.2 Interaction and Content Assessment

### 2.2.1 Button and Affordance States

Every interactive element must have distinct states:

| State | Visual Requirement | Common Failures |
|---|---|---|
| Default | Clearly interactive | Looks like static text |
| Hover | Visual change within 100ms | No change, or change too subtle |
| Active/Pressed | Visually depressed | No feedback on click |
| Focus | Visible indicator | Outline removed, no replacement |
| Disabled | Visually distinct, non-interactive | Looks like default, still clickable |
| Loading | Loading indicator shown | No feedback during async operation |

**Mobile touch targets**:
- Minimum 44×44px for essential targets (WCAG 2.5.5)
- Flag anything obviously below 20×20px
- Check spacing between adjacent targets (prevents mis-taps)

### 2.2.2 Five-State Coverage

Every page must demonstrate all five states in screenshot evidence:

| State | What to Verify | Missing Risk |
|---|---|---|
| Initial | First impression, no data | Layout broken at first load |
| Empty | No data to display | Empty state missing or unstyled |
| Loading | Async operation in progress | No loading feedback |
| Success | Operation completed | User unsure if action worked |
| Error | Something went wrong | Error not visible or unclear |

**Verification method**:
- Cross-reference screenshot matrix in interaction-check.md
- Confirm each state has both desktop and mobile screenshot
- Verify screenshots are full-page (not cropped)

### 2.2.3 Content Quality

**Text overflow**:
- Long text truncates with ellipsis (not cut off mid-character)
- No text overlapping other elements
- No text extending beyond container boundaries

**Placeholder copy**:
- Follows product voice and tone
- Not lorem ipsum or developer placeholder text
- Helpful and specific (e.g., "Enter your work email" not "Enter text")

**Error messages**:
- Specific and actionable ("Password must be at least 8 characters" not "Invalid input")
- Located near the relevant field
- Visually distinct from normal text
- Do not expose sensitive information ("Email not found" not "Email not registered")

**Data format consistency**:
- Dates use consistent format (ISO 8601 or locale-appropriate)
- Currency shows correct symbol and decimal places
- Phone numbers formatted consistently
- Null/empty values show appropriate placeholder ("—" or "N/A")

## 2.3 Responsive and Accessibility Baseline

### 2.3.1 Mobile Viewport (375px)

**Navigation**:
- Hamburger menu or equivalent is usable
- Menu items are tappable
- Current page is indicated
- Menu closes when item selected

**Form fields**:
- Inputs are fillable without zoom
- Keyboard does not obscure input
- Date pickers work on mobile
- File uploads functional

**CTA placement**:
- Primary action within thumb reach (bottom center or bottom right)
- Not hidden behind keyboard
- Not too close to edge (risk of miss-tap)

**Text readability**:
- No horizontal scroll
- Text does not overflow container
- Font size readable without zoom (minimum 16px for inputs)
- Line length comfortable (30–40 characters per line ideal)

### 2.3.2 Breakpoint Transitions

Verify at three widths:

| Width | Device Class | Key Checks |
|---|---|---|
| 375px | Mobile | Navigation, touch targets, text size |
| 768px | Tablet | Layout adaptation, sidebars, tables |
| 1440px | Desktop | Full layout, spacing, multi-column |

**Common transition defects**:
- Content overflow at intermediate widths
- Layout collapses between breakpoints
- Elements disappear at certain widths
- Horizontal scroll appears

### 2.3.3 Accessibility Visual Baseline

**Focus indicators**:
- All interactive elements have visible focus
- Focus ring is not clipped or obscured
- Focus order is logical

**Form labels**:
- All inputs have associated labels (not just placeholders)
- Labels are visible and readable
- Required fields indicated

**Color independence**:
- Information is not conveyed by color alone
- Error states have icon or text in addition to color
- Success states have checkmark or text in addition to color
- Test: convert screenshot to grayscale — is all information still decipherable?

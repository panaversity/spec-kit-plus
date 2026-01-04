---
description: Create or update the feature specification from a natural language feature description.
handoffs: 
  - label: Build Technical Plan
    agent: sp.plan
    prompt: Create a plan for the spec. I am building with...
  - label: Clarify Spec Requirements
    agent: sp.clarify
    prompt: Clarify specification requirements
    send: true
scripts:
  sh: scripts/bash/create-new-feature.sh --json "{ARGS}"
  ps: scripts/powershell/create-new-feature.ps1 -Json "{ARGS}"
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Interview Mode Detection

Check if `$ARGUMENTS` contains the `--interview` flag:

- **If `--interview` is present**: Enable interview mode, strip the flag from the description
- **If `--interview` is absent**: Continue with standard flow (skip to [Outline](#outline))

**Syntax Examples**:
- `/sp.specify --interview Add user authentication` → Interview mode ON, description = "Add user authentication"
- `/sp.specify Add user authentication` → Standard mode (no interview)

When interview mode is enabled, execute the **Interview Flow** section below before proceeding to the Outline.

---

## Interview Flow (Interview Mode Only)

When `--interview` flag is detected, execute this interview process before spec generation. The interview is fully AI-driven with no predefined questions or categories.

### Step I-1: Analyze Feature Description

Carefully analyze the user's feature description to identify:

1. **What is clearly specified** - Extract concrete details already provided
2. **What is ambiguous or missing** - Identify gaps that would lead to [NEEDS CLARIFICATION] markers
3. **What assumptions would you make** - Note where you'd have to guess without user input

Focus on aspects that significantly impact:
- Feature scope and boundaries
- User experience and workflows
- Data handling and security
- Integration points
- Success measurement

### Step I-2: Generate Targeted Questions

Based on your analysis, generate **3-7 targeted questions** specific to THIS feature.

**Question Generation Rules**:
- Only ask about genuinely unclear aspects
- Skip anything already answered in the description
- Prioritize by impact: scope > security > UX > technical details
- Each question should resolve a potential [NEEDS CLARIFICATION] marker
- Questions must be specific to this feature, not generic

**Do NOT**:
- Use predefined question templates
- Ask about things that have reasonable defaults
- Ask multiple questions about the same ambiguity

### Step I-3: Execute Interview

There are two modes for conducting the interview. Use **Interactive Mode** if you can present questions one at a time and wait for responses. Use **Questionnaire Mode** as a fallback if you cannot do multi-turn interactions.

---

#### Option A: Interactive Mode (Preferred)

Present questions ONE at a time. For each question:

```markdown
## Question [N]/[TOTAL]: [Specific Topic]

**Why this matters**: [1 sentence explaining impact on the specification]

[Your question here - be specific and contextual]

You can answer with a short response, or say "skip" to move on.
```

**Interview Rules**:
1. Present exactly ONE question, then wait for response
2. **Do NOT recommend or suggest answers** - you're asking because you genuinely don't know
3. Accept the user's answer as-is
4. If the answer is unclear, ask a brief follow-up for clarification
5. Record each answer for use in spec generation
6. Proceed to next question

**Stop Conditions** (whichever comes first):
- All questions answered
- User signals "done", "skip all", or "enough"
- Maximum 7 questions reached

---

#### Option B: Questionnaire Mode (Fallback)

Use this mode if:
- You cannot reliably pause and wait for user responses between questions
- The environment doesn't support multi-turn interactions
- User requests all questions upfront

Present all questions as a numbered questionnaire:

```markdown
## Interview Questionnaire

I have [N] questions to clarify before generating the specification. Please answer each briefly (or write "skip" to skip any).

---

**Q1: [Topic]**
[Why this matters]: [1 sentence]
[Question]

**Q2: [Topic]**
[Why this matters]: [1 sentence]
[Question]

**Q3: [Topic]**
[Why this matters]: [1 sentence]
[Question]

...

---

Please respond with your answers (e.g., "Q1: answer, Q2: answer, Q3: skip").
```

**Questionnaire Rules**:
1. Present ALL questions in a single message
2. **Do NOT recommend or suggest answers**
3. Number questions clearly (Q1, Q2, Q3...)
4. Accept answers in any reasonable format (numbered, bulleted, or prose)
5. If an answer is unclear, ask ONE follow-up message for all unclear items

---

### Step I-4: Confirm Understanding

After all questions are answered (either mode), summarize back to the user:

```markdown
## Interview Complete

Based on your answers, here's what I understood:

- **[Topic 1]**: [Summary of answer and how it will be used]
- **[Topic 2]**: [Summary of answer and how it will be used]
- ...

Does this look correct? (yes to proceed, or clarify any points)
```

Wait for user confirmation before proceeding.

### Step I-5: Prepare Interview Context

Build an interview context containing:
- All Q&A pairs
- How each answer maps to spec sections
- Any remaining ambiguities not covered by interview

This context enriches the spec generation in the Outline section.

---

## Outline

The text the user typed after `/sp.specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `{ARGS}` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

1. **Generate a concise short name** (2-4 words) for the branch:
   - Analyze the feature description and extract the most meaningful keywords
   - Create a 2-4 word short name that captures the essence of the feature
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
   - Keep it concise but descriptive enough to understand the feature at a glance
   - Examples:
     - "I want to add user authentication" → "user-auth"
     - "Implement OAuth2 integration for the API" → "oauth2-api-integration"
     - "Create a dashboard for analytics" → "analytics-dashboard"
     - "Fix payment processing timeout bug" → "fix-payment-timeout"

2. **Check for existing branches before creating new one**:

   a. First, fetch all remote branches to ensure we have the latest information:

      ```bash
      git fetch --all --prune
      ```

   b. Find the highest feature number across all sources for the short-name:
      - Remote branches: `git ls-remote --heads origin | grep -E 'refs/heads/[0-9]+-<short-name>$'`
      - Local branches: `git branch | grep -E '^[* ]*[0-9]+-<short-name>$'`
      - Specs directories: Check for directories matching `specs/[0-9]+-<short-name>`

   c. Determine the next available number:
      - Extract all numbers from all three sources
      - Find the highest number N
      - Use N+1 for the new branch number

   d. Run the script `{SCRIPT}` with the calculated number and short-name:
      - Pass `--number N+1` and `--short-name "your-short-name"` along with the feature description
      - Bash example: `{SCRIPT} --json --number 5 --short-name "user-auth" "Add user authentication"`
      - PowerShell example: `{SCRIPT} -Json -Number 5 -ShortName "user-auth" "Add user authentication"`

   **IMPORTANT**:
   - Check all three sources (remote branches, local branches, specs directories) to find the highest number
   - Only match branches/directories with the exact short-name pattern
   - If no existing branches/directories found with this short-name, start with number 1
   - You must only ever run this script once per feature
   - The JSON is provided in the terminal as output - always refer to it to get the actual content you're looking for
   - The JSON output will contain BRANCH_NAME and SPEC_FILE paths
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot")

3. Load `templates/spec-template.md` to understand required sections.
   - **If interview mode was used**: Also load the interview context from Step I-5.

4. Follow this execution flow:

    1. Parse user description from Input
       If empty: ERROR "No feature description provided"
       **If interview mode**: Merge description with interview answers (answers enrich the description)

    2. Extract key concepts from description
       Identify: actors, actions, data, constraints
       **If interview mode**: Use interview-confirmed values where available

    3. For unclear aspects:
       - Make informed guesses based on context and industry standards
       - **If interview mode**: First check if interview already answered this
       - Only mark with [NEEDS CLARIFICATION: specific question] if:
         - The choice significantly impacts feature scope or user experience
         - Multiple reasonable interpretations exist with different implications
         - No reasonable default exists
         - **AND interview did not already provide an answer**
       - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
       - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details

    4. Fill User Scenarios & Testing section
       If no clear user flow: ERROR "Cannot determine user scenarios"
       **If interview mode**: Use confirmed actor from interview if provided

    5. Generate Functional Requirements
       Each requirement must be testable
       Use reasonable defaults for unspecified details (document assumptions in Assumptions section)
       **If interview mode**: Incorporate relevant interview answers into requirements

    6. Define Success Criteria
       Create measurable, technology-agnostic outcomes
       Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion)
       Each criterion must be verifiable without implementation details
       **If interview mode**: Use interview-provided success metrics if available

    7. Identify Key Entities (if data involved)

    8. **If interview mode AND scope boundaries were discussed**: Add Out of Scope subsection
       Format as bullet list under Requirements section

    9. Return: SUCCESS (spec ready for planning)

5. Write the specification to SPEC_FILE using the template structure, replacing placeholders with concrete details derived from the feature description (arguments) while preserving section order and headings.

   **If interview mode was used**: Add an Interview Summary section at the end of the spec:

   ```markdown
   ## Interview Summary

   This specification was generated with pre-interview clarification ([N] questions answered).

   ### Key Decisions

   | Topic | Decision |
   |-------|----------|
   | [Topic from Q1] | [User's answer] |
   | [Topic from Q2] | [User's answer] |
   | ... | ... |
   ```

6. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create Spec Quality Checklist**: Generate a checklist file at `FEATURE_DIR/checklists/requirements.md` using the checklist template structure with these validation items:

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]
      
      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]
      
      ## Content Quality
      
      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed
      
      ## Requirement Completeness
      
      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified
      
      ## Feature Readiness

      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification

      ## Interview Integration (if `--interview` was used)

      - [ ] All interview answers are reflected in appropriate spec sections
      - [ ] Interview Summary section is present at end of spec with key decisions table

      ## Notes

      - Items marked incomplete require spec updates before `/sp.clarify` or `/sp.plan`
      ```

   b. **Run Validation Check**: Review the spec against each checklist item:
      - For each item, determine if it passes or fails
      - Document specific issues found (quote relevant spec sections)

   c. **Handle Validation Results**:

      - **If all items pass**: Mark checklist complete and proceed to step 6

      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user in this format:

           ```markdown
           ## Question [N]: [Topic]
           
           **Context**: [Quote relevant spec section]
           
           **What we need to know**: [Specific question from NEEDS CLARIFICATION marker]
           
           **Suggested Answers**:
           
           | Option | Answer | Implications |
           |--------|--------|--------------|
           | A      | [First suggested answer] | [What this means for the feature] |
           | B      | [Second suggested answer] | [What this means for the feature] |
           | C      | [Third suggested answer] | [What this means for the feature] |
           | Custom | Provide your own answer | [Explain how to provide custom input] |
           
           **Your choice**: _[Wait for user response]_
           ```

        4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
           - Use consistent spacing with pipes aligned
           - Each cell should have spaces around content: `| Content |` not `|Content|`
           - Header separator must have at least 3 dashes: `|--------|`
           - Test that the table renders correctly in markdown preview
        5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        6. Present all questions together before waiting for responses
        7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
        8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        9. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

7. Report completion with branch name, spec file path, checklist results, and readiness for the next phase (`/sp.clarify` or `/sp.plan`).

**NOTE:** The script creates and checks out the new branch and initializes the spec file before writing.

## General Guidelines

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: RESTful APIs unless specified otherwise

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)

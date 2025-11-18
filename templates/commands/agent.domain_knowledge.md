---
description: Capture domain expertise to deeply understand the professional work being automated or augmented by AI
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

You are capturing deep domain expertise at `/memory/domain_knowledge.md`. This workflow is inspired by Jake Heller's approach to building AI products: **understand the work deeply before building**.

This is a critical step for AI Native Software Development. Before you can build AI that replaces or assists professionals, you must understand:

1. **What does the professional actually do?** (The real work, not the job description)
2. **How would the BEST person in this field approach the task?** (If they had unlimited time)
3. **What are the specific steps?** (Broken down into a detailed workflow)

Follow this execution flow:

## Step 1: Identify the Domain Expert Source

- If the user is the domain expert, interview them directly through structured questions
- If the user is not the expert, identify who is or suggest "going undercover" to learn the work
- Document the source of domain expertise

## Step 2: Understand the Real Work

Ask structured questions to understand:

1. **Current Process**: How is this work done today?
   - What are the steps a professional takes?
   - What tools do they use?
   - What information do they need?
   - What decisions do they make?

2. **Pain Points**: What takes the most time?
   - What's repetitive?
   - What's error-prone?
   - What requires deep expertise?
   - What's currently outsourced or expensive?

3. **Quality Criteria**: What defines "good" work in this domain?
   - How do experts evaluate quality?
   - What are the edge cases?
   - What are common mistakes?

4. **Value Delivered**: What is the business impact?
   - What does the end customer get?
   - How much would they pay for this service today?
   - What's the cost of doing it poorly?

## Step 3: Work Backwards from the Best

For the identified task/domain, document:

1. **The Ideal Workflow**: If the best professional in the field had unlimited time and resources, what would they do?

   Example (from Jake Heller - Legal Research):
   - Research plan (understand the question deeply)
   - Search (find relevant sources)
   - Read (analyze each source thoroughly)
   - Note (extract key information)
   - Write (synthesize into an answer)

2. **Decision Points**: At each step, what intelligence/judgment is required?

3. **Deterministic vs. Intelligent Steps**:
   - Which steps require reasoning/intelligence? (→ will need LLM prompts)
   - Which steps are pure logic/math? (→ can use standard code)

## Step 4: Define Success Metrics

For each step in the ideal workflow, define "what good looks like":

1. **Objective Metrics**: Quantifiable measures
   - Accuracy (e.g., "95% precision on test set")
   - Speed (e.g., "completes in < 5 seconds")
   - Coverage (e.g., "finds all relevant cases")

2. **Subjective Metrics**: Quality assessments
   - Relevance (e.g., "7/7 on expert relevance scale")
   - Completeness (e.g., "covers all key precedents")
   - Clarity (e.g., "lawyer can act on it without questions")

3. **Business Metrics**: Value delivered
   - Time saved (e.g., "reduces 4 hours to 15 minutes")
   - Cost reduction (e.g., "saves $500 per contract")
   - Quality improvement (e.g., "catches 3x more issues")

## Step 5: Create the Domain Knowledge Document

The `/memory/domain_knowledge.md` file should contain:

```markdown
# Domain Knowledge: [DOMAIN_NAME]

## Domain Overview
[Brief description of the professional domain being automated/augmented]

## Domain Expert Source
[Who provided this expertise and their qualifications]

## Current State Analysis

### How the Work is Done Today
[Detailed breakdown of current process]

### Pain Points & Opportunities
[What's slow, expensive, error-prone, or requires deep expertise]

### Value Delivered
[What customers get and what they'd pay for it]

## Ideal Workflow (Working Backwards from the Best)

### Step 1: [STEP_NAME]
- **What**: [What happens in this step]
- **Intelligence Required**: [What judgment/reasoning is needed]
- **Type**: [Intelligent (LLM) or Deterministic (Code)]
- **Success Criteria**: [What "good" looks like]

### Step 2: [STEP_NAME]
[Repeat for each step]

## Success Metrics & Evals

### Objective Metrics
[Quantifiable measures with targets]

### Subjective Metrics
[Quality assessments with evaluation rubrics]

### Business Metrics
[Value delivered with ROI calculations]

## Edge Cases & Common Failures
[What can go wrong and how to handle it]

## Domain-Specific Constraints
[Regulatory, ethical, or business constraints]

## Competitive Landscape
[How others solve this problem and what they charge]
```

## Step 6: Validation Checklist

Before finalizing the domain knowledge document, validate:

- [ ] Real professional input captured (not just assumptions)
- [ ] Ideal workflow breaks down into specific, testable steps
- [ ] Each step classified as intelligent (LLM) or deterministic (code)
- [ ] Success criteria defined for every step
- [ ] Business value quantified
- [ ] Edge cases and failure modes documented
- [ ] Competitive context understood

## Step 7: Output Summary

Provide the user with:

1. **Key Insights**: What you learned about the domain
2. **Workflow Complexity**: How many steps, what types (LLM vs code)
3. **Success Criteria**: Most critical metrics to track
4. **Next Steps**: What to do with this knowledge (hint: create evals)

## Important Notes

- **This is NOT vibe-coding**: You are doing deep research before writing any code
- **Quality over speed**: Take time to really understand the domain
- **Talk to real users**: If possible, interview actual professionals in this field
- **Be specific**: "Legal research" is too vague. "Summarize contract terms for data privacy clauses" is specific.
- **Think about pricing**: Understanding value helps you price appropriately (10-20% of value delivered, not $20/month SaaS pricing)

## Template Structure

The document should follow this hierarchy:
1. Domain Overview (context)
2. Current State (problems)
3. Ideal Workflow (solution architecture)
4. Success Metrics (how to measure)
5. Edge Cases (what to watch for)

Keep the document **focused and actionable**. Every section should help you build better AI.

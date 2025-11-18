# Domain Knowledge: [DOMAIN_NAME]

<!--
This document captures deep domain expertise for building AI that replaces or assists professionals.
Based on Jake Heller's approach: "Understand the work deeply before building."
-->

## Domain Overview

[Brief description of the professional domain being automated/augmented]

**Target Professional Role**: [e.g., Lawyer, Paralegal, Customer Support Agent, Accountant]

**Specific Task/Workflow**: [e.g., Contract review for data privacy clauses, Legal research for precedents]

**Current Market**: [Size, existing solutions, what people pay today]

## Domain Expert Source

**Expert**: [Name/Role of person providing expertise]

**Qualifications**: [Years of experience, credentials, why they're qualified]

**Date Captured**: [YYYY-MM-DD]

## Current State Analysis

### How the Work is Done Today

**High-Level Process**:
1. [Step 1 in current workflow]
2. [Step 2 in current workflow]
3. [Continue...]

**Tools & Resources Used**:
- [Tool 1]: [Purpose]
- [Tool 2]: [Purpose]
- [Resource 1]: [Purpose]

**Time Investment**:
- Typical case: [X hours/days]
- Complex case: [Y hours/days]
- Estimated annual volume: [Z cases]

**Information Sources**:
- [Where professionals get the information they need]

### Pain Points & Opportunities

**Time-Intensive Work**:
- [What takes the longest]
- [What's repetitive/tedious]

**Error-Prone Areas**:
- [Common mistakes]
- [High-risk failure modes]

**Expertise Requirements**:
- [What requires deep knowledge]
- [What could be automated]

**Cost Structure**:
- Professional hourly rate: [$X/hour]
- Average cost per task: [$Y]
- Outsourcing cost (if applicable): [$Z]

### Value Delivered

**Customer Outcome**:
[What the end customer gets from this work]

**Willingness to Pay**:
- Current pricing: [$X per task/month/year]
- Value to customer: [$Y saved/earned]
- ROI: [Z%]

**Cost of Poor Quality**:
- Mistakes can cost: [$X or Y outcome]
- Delays can cost: [$X or Y outcome]

## Ideal Workflow (Working Backwards from the Best)

> If the BEST professional in this field had unlimited time and resources, what would they do?

### Step 1: [STEP_NAME]

**What**: [Detailed description of what happens in this step]

**Intelligence Required**:
[What judgment, reasoning, or expertise is needed?]

**Type**:
- [ ] Intelligent (requires LLM prompt)
- [ ] Deterministic (standard code/logic/math)

**Inputs**:
- [Data/information needed]

**Outputs**:
- [What this step produces]

**Success Criteria**:
[What "good" looks like for this step]

**Time (Human)**: [X minutes/hours]
**Time (AI Target)**: [Y seconds/minutes]

---

### Step 2: [STEP_NAME]

[Repeat the same structure for each step]

---

[Continue for all steps in the ideal workflow]

## Success Metrics & Evals

### Objective Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| [Accuracy] | [95%+] | [Comparison to human gold standard] |
| [Speed] | [< 5 seconds] | [API response time] |
| [Coverage] | [100% of required fields] | [Automated field extraction check] |
| [Precision] | [>90%] | [Test set evaluation] |

### Subjective Metrics

| Metric | Target | Evaluation Method |
|--------|--------|-------------------|
| [Relevance] | [7/7 score] | [Expert review on rubric] |
| [Completeness] | [Covers all key points] | [Checklist evaluation] |
| [Clarity] | [No follow-up needed] | [User feedback] |
| [Professional Tone] | [Matches standards] | [LLM-as-judge with rubric] |

### Business Metrics

| Metric | Current (Human) | Target (AI) | Value Delivered |
|--------|----------------|-------------|-----------------|
| [Time per task] | [4 hours] | [15 minutes] | [93.75% reduction] |
| [Cost per task] | [$500] | [$50] | [$450 saved] |
| [Quality score] | [85%] | [95%+] | [+10% improvement] |
| [Volume capacity] | [10/week] | [1000/week] | [100x scale] |

## Edge Cases & Common Failures

### Known Edge Cases

1. **[Edge Case 1 Name]**
   - Description: [What makes this challenging]
   - Frequency: [How often it occurs]
   - Current handling: [How experts handle it today]
   - AI handling plan: [Strategy for AI to handle it]

2. **[Edge Case 2 Name]**
   [Repeat structure]

### Common Failure Modes

1. **[Failure Mode 1]**
   - Symptoms: [How to detect it]
   - Impact: [What goes wrong]
   - Prevention: [How to avoid it]
   - Recovery: [What to do if it happens]

2. **[Failure Mode 2]**
   [Repeat structure]

### Human Baseline Performance

**Expert Professional**:
- Accuracy: [X%]
- Speed: [Y time]
- Consistency: [Z%]

**Average Professional**:
- Accuracy: [X%]
- Speed: [Y time]
- Consistency: [Z%]

**AI Must Match/Exceed**: [Which baseline?]

## Domain-Specific Constraints

### Regulatory/Legal Requirements
- [Requirement 1]
- [Requirement 2]

### Ethical Considerations
- [Consideration 1]
- [Consideration 2]

### Business Constraints
- [Constraint 1]
- [Constraint 2]

### Data Privacy/Security
- [Requirement 1]
- [Requirement 2]

## Competitive Landscape

### Existing Solutions

| Solution | Approach | Pricing | Strengths | Weaknesses |
|----------|----------|---------|-----------|------------|
| [Competitor 1] | [Human/AI/Hybrid] | [$X] | [What they do well] | [Gaps/limitations] |
| [Competitor 2] | [Human/AI/Hybrid] | [$Y] | [What they do well] | [Gaps/limitations] |

### Market Positioning

**Our Differentiation**:
[What makes our AI approach better/different]

**Target Market Segment**:
[Who will value this most]

**Pricing Strategy**:
[How to price - 10-20% of value delivered, not SaaS commodity pricing]

## Implementation Insights

### What to Build First (MVP)

**Core Workflow Step**: [Which step delivers most value]

**Minimum Quality Bar**: [What's acceptable for beta users]

**Test Data Needed**: [What data to collect before building]

### What Makes This Hard

**Technical Challenges**:
- [Challenge 1]
- [Challenge 2]

**Domain Challenges**:
- [Challenge 1]
- [Challenge 2]

### What Makes This Valuable

**Unique Insights**:
- [Insight 1 that experts know but others don't]
- [Insight 2]

**Moat/Defensibility**:
- [Why this is hard to replicate]
- [What creates competitive advantage]

## Next Steps

1. **Create Evals**: Run `/sp.agent.business_success_evals` to define how to measure success
2. **Gather Test Data**: Collect [N] examples of real professional work
3. **Build Baseline**: Implement simplest version that works
4. **Iterate on Quality**: Use evals to drive to 95%+ accuracy
5. **Beta Testing**: Deploy with real users and measure actual value

## Notes & Learnings

**Key Insights from Domain Expert**:
- [Insight 1]
- [Insight 2]
- [Insight 3]

**Assumptions to Validate**:
- [ ] Assumption 1
- [ ] Assumption 2
- [ ] Assumption 3

**Open Questions**:
- [ ] Question 1
- [ ] Question 2
- [ ] Question 3

---

**Version**: [VERSION] | **Author**: [NAME] | **Last Updated**: [YYYY-MM-DD]

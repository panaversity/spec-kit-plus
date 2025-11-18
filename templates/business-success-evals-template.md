# Business Success Evals: [DOMAIN_NAME]

<!--
This document defines how we measure whether our AI is good enough to ship.
Based on Jake Heller's principle: "Evals are the difference between 60% demos and 97% production systems."
-->

## Overview

**What We're Building**: [Brief description linking to domain knowledge]

**Why Evals Matter**:
> "Building a demo is easy. Making it work in practice is hard. Most people quit at 60% accuracy when they need 97%+. The difference is rigorous evals."
> — Jake Heller, Founder of Casetext ($650M acquisition)

**Business Success Criteria**:
[What must be true for this AI to deliver real value]

## Success Thresholds

### Minimum Viable Quality (Don't Ship Below This)

| Component | Metric | Threshold | Rationale |
|-----------|--------|-----------|-----------|
| [Overall System] | [Accuracy] | [90%] | [Below this, users lose trust] |
| [Step 1] | [Metric] | [X%] | [Why this matters] |
| [Step 2] | [Metric] | [Y%] | [Why this matters] |
| [Cost] | [$ per request] | [< $Z] | [Must be < 10% of value delivered] |
| [Latency] | [P95] | [< N seconds] | [User experience requirement] |

### Target Quality (Our Goal)

| Component | Metric | Target | Competitive Benchmark |
|-----------|--------|--------|----------------------|
| [Overall System] | [Accuracy] | [95%] | [Human expert: 92%] |
| [Step 1] | [Metric] | [X%] | [Human: Y%] |
| [Step 2] | [Metric] | [X%] | [Best competitor: Y%] |
| [Cost] | [$ per request] | [< $Z] | [Human cost: $W] |
| [Latency] | [P95] | [< N seconds] | [Human time: M hours] |

### Delight Quality (Exceptional Performance)

| Component | Metric | Delight | Impact |
|-----------|--------|---------|--------|
| [Overall System] | [Accuracy] | [99%] | [Better than any human] |
| [Speed] | [Response time] | [< 1 second] | [10x faster than target] |
| [Cost] | [$ per request] | [< $X] | [5x cheaper than target] |

## Evaluation Framework

### Step 1: [STEP_NAME] Evals

**From Domain Knowledge**: [Reference to the workflow step in domain_knowledge.md]

**What Good Looks Like**:
[Clear, specific definition of success for this step]

#### Objective Criteria (Automated)

| Criterion | Measurement | Target | Test Method |
|-----------|-------------|--------|-------------|
| [Field extraction completeness] | [All required fields present] | [100%] | [Automated schema validation] |
| [Response time] | [API latency] | [< 2s] | [Performance benchmark] |
| [Format compliance] | [Matches expected structure] | [100%] | [JSON schema validation] |

**Automated Test Code**:
```python
def eval_step1_completeness(output):
    """Validates all required fields are present"""
    required_fields = ["field1", "field2", "field3"]
    return all(field in output for field in required_fields)

def eval_step1_speed(trace):
    """Validates response time"""
    return trace.duration_ms < 2000
```

#### Subjective Criteria (LLM-as-Judge or Human)

| Criterion | Rubric | Target | Evaluation Method |
|-----------|--------|--------|-------------------|
| [Relevance] | [0-10 scale] | [≥ 8] | [LLM judge with detailed prompt] |
| [Clarity] | [Pass/Fail] | [Pass] | [Human expert review] |
| [Completeness] | [0-100%] | [≥ 90%] | [Checklist coverage] |

**LLM Judge Prompt Example**:
```
You are evaluating [step name] output quality. Score 0-10 based on:

Relevance (0-4 points):
- 4: Perfectly addresses the core question
- 3: Addresses the question with minor gaps
- 2: Partially relevant
- 1: Tangentially related
- 0: Not relevant

Completeness (0-3 points):
- 3: Covers all key aspects
- 2: Covers most aspects
- 1: Covers some aspects
- 0: Incomplete

Clarity (0-3 points):
- 3: User can act immediately without clarification
- 2: Minor clarification might be needed
- 1: Significant clarification needed
- 0: Unclear or confusing

Provide score and brief justification.
```

#### Test Dataset for Step 1

**Golden Examples**:
- Location: `/evals/step1_golden_examples.jsonl`
- Size: [N examples]
- Source: [Real professional work from X]
- Format: `{input: ..., expected_output: ..., quality_score: ...}`

**Edge Cases**:
- Location: `/evals/step1_edge_cases.jsonl`
- Size: [M examples]
- Includes: [List of edge case types]

**Regression Tests**:
- Location: `/evals/step1_regressions.jsonl`
- Size: [Growing set, started with P examples]
- Rule: Every prod failure becomes a regression test

---

### Step 2: [STEP_NAME] Evals

[Repeat the same structure for each step in the workflow]

---

## Component-Level Evals

> "Test each piece individually. If the final output is wrong, you need to know which step failed."
> — Jake Heller

### Search Quality Eval (If Applicable)

**Metric**: Relevance of retrieved documents
**Target**: Top 5 results include ≥ 3 highly relevant docs
**Method**: Human annotation of sample queries

### Summarization Quality Eval (If Applicable)

**Metric**: Accuracy and completeness of summaries
**Target**: 95% factual accuracy, covers all key points
**Method**: Comparison against expert summaries

### Extraction Quality Eval (If Applicable)

**Metric**: Precision and recall of extracted entities
**Target**: Precision ≥ 95%, Recall ≥ 90%
**Method**: Comparison against manually labeled test set

## End-to-End Integration Evals

### Full Workflow Test

**Test Cases**: [N diverse scenarios covering common + edge cases]

**Success Criteria**:
- [ ] Overall accuracy ≥ [target]%
- [ ] No step falls below minimum threshold
- [ ] End-to-end latency < [X] seconds
- [ ] Cost per request < $[Y]

**Test Dataset Location**: `/evals/e2e_integration_tests.jsonl`

## Test Datasets

### Golden Examples Dataset

**Purpose**: Baseline quality measurement

**Size**: [50-100 examples]

**Source**: [Real professional work, anonymized]

**Structure**:
```json
{
  "id": "example_001",
  "input": {...},
  "expected_output": {...},
  "human_expert": "Jane Doe",
  "quality_score": 9.5,
  "difficulty": "medium",
  "tags": ["common_case", "contract_review"]
}
```

**Curation Process**:
1. Collect real examples from [source]
2. Have expert professionals review/annotate
3. Validate quality scores with multiple reviewers
4. Update quarterly with new examples

### Edge Cases Dataset

**Purpose**: Test robustness and failure modes

**Examples**:
1. **Ambiguous Input**: [Description and expected behavior]
2. **Incomplete Data**: [Description and expected behavior]
3. **Conflicting Information**: [Description and expected behavior]
4. **Unusual Format**: [Description and expected behavior]
5. **Extreme Length**: [Description and expected behavior]

**Location**: `/evals/edge_cases/`

### Regression Tests

**Purpose**: Prevent quality backsliding

**Collection Process**:
1. Every production failure becomes a test case
2. Beta user feedback → test cases
3. A/B test losers → negative examples

**Current Size**: [N tests]

**Growth Rate**: [~M new tests per month]

## Operational Metrics

### Cost Targets

**Cost Structure**:
| Component | Estimated Cost | Target | Budget |
|-----------|---------------|--------|--------|
| [LLM API calls] | [$X per 1K requests] | [< $Y per request] | [$Z monthly] |
| [Compute] | [$A per hour] | [< $B per request] | [$C monthly] |
| [Total] | [$D per request] | [< $E per request] | [$F monthly] |

**Value-Based Pricing**:
- Value delivered per request: [$X]
- Target cost: [10-20% of value]
- Maximum acceptable cost: [$Y]

**Cost Monitoring**:
- Daily: Track cost per request trend
- Weekly: Analyze cost drivers
- Monthly: ROI review

### Latency Targets

**Response Time Distribution**:
| Percentile | Target | Maximum Acceptable | User Impact |
|------------|--------|-------------------|-------------|
| P50 | [< 1s] | [< 2s] | [Feels instant] |
| P90 | [< 3s] | [< 5s] | [Acceptable] |
| P95 | [< 5s] | [< 8s] | [Noticeable delay] |
| P99 | [< 10s] | [< 15s] | [User may abandon] |

**Timeout Policy**: [Hard cutoff at X seconds]

**Latency Breakdown by Step**:
- Step 1: [Target time]
- Step 2: [Target time]
- [...]

### Quality Monitoring in Production

**Real-Time Metrics**:
- Accuracy on sampled production requests
- User satisfaction scores (thumbs up/down)
- Task completion rate

**Sampling Strategy**:
- Sample [X]% of production requests
- Prioritize: edge cases, low-confidence outputs, user-flagged issues

**Alert Thresholds**:
- Accuracy drops below [Y]% → page on-call
- Cost exceeds $[Z] per request → alert finance
- P95 latency > [W]s → investigate performance

## A/B Testing Framework

### Current Baseline

**Version**: [baseline_v1.0]

**Performance**:
- Accuracy: [X]%
- Cost: [$Y per request]
- Latency: [Z seconds P95]

**Description**: [What this version does]

### Optimization Focus

**Primary Metric**: [Accuracy]

**Trade-offs We're Willing to Make**:
- Willing to increase cost by [X]% for [Y]% accuracy gain
- NOT willing to sacrifice latency beyond [Z] seconds

### Experiment Design

**Hypothesis**: [What we think will improve performance]

**Variant Description**: [What's different in the new version]

**Test Parameters**:
- Traffic split: [50/50 or other]
- Sample size needed: [N requests for statistical significance]
- Duration: [X days]

**Success Criteria**:
- [ ] Accuracy improves by ≥ [X]%
- [ ] Cost stays within [Y]% of baseline
- [ ] Latency doesn't increase by more than [Z]%
- [ ] Statistical significance achieved (p < 0.05)

### Historical A/B Tests

| Test ID | Date | Variant | Result | Key Learning |
|---------|------|---------|--------|--------------|
| [001] | [2025-01] | [Changed prompt] | [+3% accuracy] | [Better instruction format helps] |
| [002] | [2025-02] | [Different model] | [-1% accuracy] | [Larger model not worth cost] |

## Continuous Improvement

### Daily Monitoring Dashboard

**Key Metrics to Check**:
1. Accuracy on sample set (should be ≥ [X]%)
2. Cost per request (should be < $[Y])
3. P95 latency (should be < [Z]s)
4. Error rate (should be < [W]%)

**Alert Conditions**:
- Any metric crosses threshold → investigate immediately

### Weekly Review Checklist

- [ ] Review accuracy trend (improving/stable/declining?)
- [ ] Analyze new failure cases (add to regression tests)
- [ ] Check cost efficiency (any spikes?)
- [ ] Examine user feedback
- [ ] Plan next A/B test based on learnings

### Monthly Deep Dive

- [ ] Comprehensive eval run on full test set
- [ ] Detailed error analysis by category
- [ ] Competitive benchmark comparison
- [ ] ROI calculation (value delivered vs cost)
- [ ] Test data refresh (add new golden examples)
- [ ] Eval framework update (new metrics? better rubrics?)

### Error Analysis Protocol

**When Evals Fail**:

1. **Categorize the Failure**:
   - Which step failed?
   - What type of error? (accuracy, hallucination, format, etc.)
   - Edge case or systemic issue?

2. **Root Cause Analysis**:
   - Prompt issue?
   - Model limitation?
   - Data quality problem?
   - Integration bug?

3. **Add to Regression Tests**:
   - Create test case from failure
   - Define expected behavior
   - Validate fix doesn't break other cases

4. **Systematic Fix**:
   - Address root cause, not just symptom
   - Re-run full eval suite
   - Document learning

## Integration with Development Workflow

### Test-Driven Development for AI

1. **Write eval first** (define success criteria)
2. **Run eval** (should fail initially)
3. **Implement/iterate** (build or improve the prompt/model)
4. **Run eval again** (check progress)
5. **Repeat** until reaching target threshold

### Release Gates

**Before merging code**:
- [ ] All component evals pass minimum thresholds
- [ ] End-to-end evals pass
- [ ] No regression test failures
- [ ] Cost within budget
- [ ] Latency within limits

**Before deploying to production**:
- [ ] Beta user testing complete
- [ ] Production sampling strategy in place
- [ ] Monitoring/alerting configured
- [ ] Rollback plan ready

## Pricing Implications

### Value-Based Pricing Strategy

**Value Delivered**:
- Time saved: [X hours → Y minutes]
- Cost saved: [$Z per task with human]
- Quality improvement: [W% better outcomes]

**Total Value**: [$V per task]

**Our Price**: [10-20% of value = $P per task]

### Cost vs. Price Analysis

| Metric | Amount | Note |
|--------|--------|------|
| Our cost per request | [$X] | [Must stay below this] |
| Value delivered | [$Y] | [What customer gets] |
| Our price | [$Z] | [10-20% of value] |
| Margin | [$Z - $X] | [Must be profitable] |

**Margin Requirements**:
- Minimum margin: [X]%
- Target margin: [Y]%
- Must cover: [Sales, support, infrastructure, R&D]

## Next Steps

1. **Implement Baseline Evals**:
   - Set up eval harness (code framework)
   - Create initial test datasets
   - Run first eval to establish baseline

2. **Iterate to Target Quality**:
   - Use evals to guide prompt engineering
   - Test different models/approaches
   - Document what works (and what doesn't)

3. **Prepare for Production**:
   - Set up monitoring infrastructure
   - Configure alerts
   - Train team on eval interpretation

4. **Continuous Improvement**:
   - Weekly eval reviews
   - Monthly deep dives
   - Quarterly competitive benchmarks

---

**Version**: [VERSION] | **Author**: [NAME] | **Last Updated**: [YYYY-MM-DD]

**Related Documents**:
- Domain Knowledge: `/memory/domain_knowledge.md`
- Implementation Plan: `/specs/[FEATURE]/plan.md`
- Test Data: `/evals/`

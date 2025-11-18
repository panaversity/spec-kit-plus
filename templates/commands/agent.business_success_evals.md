---
description: Define business success criteria and create evaluation framework for AI agents - the "evals" that determine if your AI is good enough to ship
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

You are creating a comprehensive evaluation (evals) framework at `/memory/business_success_evals.md`. This is inspired by Jake Heller's emphasis that **evals are the most critical part of building production AI** - most startups fail here.

According to Jake Heller's experience building CoCounsel (acquired for $650M):

> "Building a demo is easy. Making it work in practice is hard. Most people quit at 60% accuracy when they need 97%+. The difference is rigorous evals."

Follow this execution flow:

## Step 1: Load Domain Knowledge

Read `/memory/domain_knowledge.md` to understand:
- The ideal workflow steps
- The success criteria for each step
- The business value being delivered

If domain knowledge doesn't exist, prompt the user to run `/sp.agent.domain_knowledge` first.

## Step 2: Define "What Good Looks Like"

For EVERY step in your ideal workflow (from domain knowledge), define:

### Objective Criteria
What can be measured automatically?

Examples:
- "Answer must contain at least 3 relevant sources"
- "Response time must be < 5 seconds"
- "Must extract all 7 required fields from the document"
- "Precision on test set must be > 95%"

### Subjective Criteria
What requires human judgment but can be scored?

Examples:
- "Relevance rated 6/7 or higher by domain expert"
- "Completeness: covers all major precedents (yes/no)"
- "Clarity: lawyer can act without follow-up questions (yes/no)"
- "Tone matches professional standards (1-5 scale)"

## Step 3: Create Test Datasets

You need real data to test against:

1. **Golden Examples**: 20-50 real examples of the task with known good outputs
   - Source: Real professional work (anonymized if needed)
   - Includes: Input + expected output + quality score

2. **Edge Cases**: 10-20 challenging examples that break most attempts
   - Unusual inputs
   - Ambiguous situations
   - Known failure modes

3. **Regression Tests**: Examples from production failures (add over time)
   - Every prod bug becomes a test case
   - Prevents backsliding

## Step 4: Define Evaluation Methods

For each eval type, specify HOW to measure:

### A. Automated Objective Evals
- SQL queries against trace data
- Code assertions
- API response validation
- Performance benchmarks

Example:
```python
def eval_response_time(trace):
    return trace.duration_ms < 5000

def eval_completeness(output):
    required_fields = ["title", "date", "summary", "risk_level"]
    return all(field in output for field in required_fields)
```

### B. LLM-as-Judge (Subjective)
- Use LLM to score on rubric (0-10, or pass/fail)
- Provide detailed scoring criteria
- Validate against human ratings periodically

Example:
```
You are evaluating legal research quality. Score 0-10 on:
- Relevance: Does it answer the specific question? (0-4 points)
- Completeness: Covers all key precedents? (0-3 points)
- Clarity: Actionable without clarification? (0-3 points)
```

### C. Component-Level Evals
- Test individual pieces (search, summarization, etc.)
- Measure each step's quality independently
- Helps debug where failures occur

### D. End-to-End Evals
- Full workflow tests
- Measures final output quality
- Catches integration issues

## Step 5: Set Quality Thresholds

Based on business requirements:

1. **Minimum Viable Quality**: What's the lowest acceptable performance?
   - Below this = don't ship
   - Example: "Must achieve 90% accuracy on core test set"

2. **Target Quality**: What are you aiming for?
   - Competitive with human experts
   - Example: "Match or exceed human paralegal accuracy (95%+)"

3. **Delight Quality**: What would be exceptional?
   - Better/faster than best human
   - Example: "99% accuracy in 1/10th the time"

## Step 6: Cost & Latency Benchmarks

Track operational metrics:

1. **Cost per Request**
   - LLM API costs
   - Compute costs
   - Target: % of value delivered (e.g., if saving $100, cost < $10)

2. **Latency Targets**
   - P50, P90, P95, P99 response times
   - Timeout thresholds
   - User experience requirements

3. **Throughput**
   - Requests per second
   - Concurrent users
   - Scale limits

## Step 7: A/B Testing Framework

Plan for continuous improvement:

1. **Baseline**: Current best approach
2. **Variants**: Alternative prompts, models, workflows
3. **Success Metric**: Primary metric to optimize (accuracy? cost? speed?)
4. **Sample Size**: How many tests needed for statistical significance?

## Step 8: Create the Evals Document

The `/memory/business_success_evals.md` file should contain:

```markdown
# Business Success Evals: [DOMAIN_NAME]

## Overview
[What we're measuring and why it matters for business success]

## Success Thresholds

### Minimum Viable Quality
[Don't ship below this]

### Target Quality
[Our goal]

### Delight Quality
[Exceptional performance]

## Evaluation Framework

### Step 1: [STEP_NAME] Evals
**What Good Looks Like**: [Clear definition]

**Objective Criteria**:
- [ ] Criterion 1: [How to measure]
- [ ] Criterion 2: [How to measure]

**Subjective Criteria**:
- [ ] Criterion 1: [Rubric/scale]
- [ ] Criterion 2: [Rubric/scale]

**Test Dataset**: [Number of examples, source]

**Evaluation Method**: [Automated/LLM-judge/Human]

[Repeat for each step]

## Test Datasets

### Golden Examples
[Location, size, source, format]

### Edge Cases
[Challenging scenarios to test]

### Regression Tests
[Production failures turned into tests]

## Operational Metrics

### Cost Targets
- Per request: [Target cost]
- Budget: [Monthly/annual limit]
- ROI: [% of value delivered]

### Latency Targets
- P50: [Time]
- P95: [Time]
- Timeout: [Max acceptable time]

### Quality Monitoring
- Production accuracy tracking
- User feedback loops
- Error analysis process

## A/B Testing Plan

### Current Baseline
[What we're comparing against]

### Optimization Focus
[What we're trying to improve]

### Test Methodology
[How we'll run experiments]

## Continuous Improvement

### Daily Monitoring
[What to check every day]

### Weekly Reviews
[Trends to analyze]

### Monthly Deep Dives
[Comprehensive eval reviews]

### Error Analysis Protocol
[What to do when evals fail]
```

## Step 9: Validation Checklist

Before finalizing the evals framework:

- [ ] Every workflow step has defined success criteria
- [ ] Both objective and subjective measures included
- [ ] Test datasets specified (with real examples)
- [ ] Evaluation methods are concrete and actionable
- [ ] Quality thresholds set (minimum, target, delight)
- [ ] Cost and latency targets defined
- [ ] A/B testing framework in place
- [ ] Error analysis process documented
- [ ] Links back to business value from domain knowledge

## Step 10: Output Summary

Provide the user with:

1. **Eval Coverage**: How many steps have proper evals
2. **Test Data Needs**: What data to collect
3. **Critical Metrics**: Top 3 metrics to obsess over
4. **Implementation Guide**: How to build these evals (next steps)

## Important Principles (From Jake Heller)

### "Evals Are Everything"
> "Building a demo is easy. Getting to 97% accuracy is the hard part. Most people quit at 60% because they don't have rigorous evals."

### "The Grind"
> "Spend weeks tweaking prompts to get from 60% to 97%+. Iterate with real customer data and failures during beta."

### "Component-Level Evals"
> "Test each piece individually. If the final output is wrong, you need to know which step failed."

### "Human Baselines"
> "Compare your AI to the best human. If a paralegal gets 95% accuracy, your AI needs 95%+ to be viable."

### "Production Feedback Loops"
> "Every production failure becomes a regression test. Build systems to capture and learn from mistakes."

## Integration with Development Workflow

This evals framework should:

1. **Guide Implementation**: Use evals to drive TDD for AI
2. **Measure Progress**: Track improvement over iterations
3. **Prevent Regression**: Catch when changes break quality
4. **Enable Deployment**: Gate production releases on eval thresholds
5. **Drive Pricing**: Understand cost structure to price correctly

## Next Steps After Evals

Once evals are defined:

1. Implement baseline version (can be low quality at first)
2. Run evals to measure current performance
3. Iterate on prompts/models to improve scores
4. Repeat until hitting target quality thresholds
5. Set up production monitoring with same evals

This is NOT a one-time exercise. Evals evolve as you learn from production.

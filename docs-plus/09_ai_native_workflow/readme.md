# AI Native Software Development Workflow

> **Building AI that replaces or assists professionals** - Inspired by Jake Heller's approach that led to a $650M acquisition

---

## What is AI Native Software?

**AI Native Software** is not traditional software with AI sprinkled on top. It's software where **AI agents are the core product**, designed from day one to:

1. **Replace Professional Work**: Automate tasks currently done by knowledge workers (lawyers, accountants, support agents, etc.)
2. **Augment Expertise**: Make experts 10x more productive
3. **Democratize Access**: Make expensive professional services affordable to everyone

### Key Difference from Traditional SDD

| Traditional SDD | AI Native SDD |
|----------------|---------------|
| Human writes code | AI agents execute workflows |
| Focus on features | Focus on professional tasks |
| Ship working software | Ship AI that matches/exceeds human experts |
| Manual testing | Rigorous evals (60% → 97%+ accuracy) |
| Value = features delivered | Value = professional hours saved |

## The SpecKitPlus AI Native Workflow

Based on Jake Heller's lessons from building Casetext (AI legal research → $650M exit):

```
1. Constitution
   ↓
2. Domain Knowledge      ← NEW: Deep understanding of the work
   ↓
3. Business Success Evals ← NEW: Define what "good" looks like
   ↓
4. SpecKitPlus Loops (AI-Native)
   ├─ Specify (AI workflows, not features)
   ├─ Plan (Agents + MCP + Tools)
   ├─ Tasks (Component evals + integration)
   └─ Implement (Build + iterate to 97%+)
```

## Prerequisites

Before starting AI Native development:

### Skills Required
- ✓ MCP Builder L1 - Build MCP servers for agent tools
- ✓ MCP Exam - Validate MCP knowledge
- ✓ OpenAI Agents SDK L2 - Build production agents

See `/templates/skills/` for skill guides.

### Mindset Shift
- **Think like a business analyst**: What work is expensive and repetitive?
- **Work backwards from the best**: How would the best professional do this?
- **Obsess over evals**: 97%+ accuracy or don't ship
- **Price on value, not time**: Charge based on value delivered, not SaaS pricing

## Step-by-Step Workflow

### Step 0: Constitution (Same as Traditional SDD)

Establish project principles using `/sp.constitution`:

```bash
/sp.constitution Create principles for building AI that augments professional work:
- Test-First: Evals before implementation
- Human-Level Quality: Match or exceed expert professionals
- Transparent Pricing: Charge based on value delivered (10-20% of savings)
- Continuous Learning: Production failures become regression tests
```

This creates `/memory/constitution.md` with your AI Native principles.

---

### Step 1: **Domain Knowledge** (NEW)

**Purpose**: Deeply understand the professional work you're automating.

**Command**: `/sp.agent.domain_knowledge`

**What Jake Heller Says**:
> "If you don't know how lawyers actually do legal research, go undercover and learn. You can't build good AI without understanding the real work."

**Example Prompt**:
```bash
/sp.agent.domain_knowledge

I want to build AI that helps lawyers with contract review for data privacy clauses.

Current process:
1. Lawyer reads entire contract (2-4 hours)
2. Identifies data privacy sections
3. Compares against GDPR/CCPA requirements
4. Flags risky clauses
5. Suggests revisions
6. Documents findings

Current cost: $500-800 per contract (2-4 hours at $200-250/hour)
Volume: Law firms review ~50 contracts/week
Pain point: Manual, time-consuming, expensive
Value: Reduce time to 15 minutes, cost to $50
```

**Output**: `/memory/domain_knowledge.md` containing:
- Current state analysis (how work is done today)
- Ideal workflow (working backwards from the best)
- Each step broken down (intelligent vs. deterministic)
- Success criteria for each step
- Business metrics (time saved, cost saved)

---

### Step 2: **Business Success Evals** (NEW)

**Purpose**: Define measurable success criteria before building anything.

**Command**: `/sp.agent.business_success_evals`

**What Jake Heller Says**:
> "Building a demo is easy. Getting to 97% accuracy is hard. Most people quit at 60% because they don't have evals. Spend weeks grinding on prompts until you hit production quality."

**Example Prompt**:
```bash
/sp.agent.business_success_evals

Based on the contract review domain knowledge, define evals for:

Minimum Viable Quality (don't ship below this):
- Accuracy: 90% (catches 90% of risky clauses)
- Precision: 95% (95% of flagged clauses are actually risky)
- Recall: 85% (finds 85% of all risky clauses)

Target Quality (our goal):
- Accuracy: 95% (matches senior lawyer)
- Precision: 98%
- Recall: 92%
- Cost: <$5 per contract
- Latency: <60 seconds for 50-page contract

Test data needed:
- 50 real contracts with lawyer annotations (golden set)
- 20 edge cases (ambiguous clauses, foreign jurisdictions)
- Continuous: Every prod mistake becomes a regression test
```

**Output**: `/memory/business_success_evals.md` containing:
- Success thresholds (minimum, target, delight)
- Component-level evals (for each workflow step)
- Test datasets (golden examples, edge cases, regressions)
- Operational metrics (cost, latency, quality)
- A/B testing framework
- Error analysis process

---

### Step 3: Specify (AI-Native)

**Purpose**: Define what AI workflows you're building (not traditional features).

**Command**: `/sp.specify`

**Example Prompt**:
```bash
/sp.specify

Build "ContractGuard" - an AI agent that reviews contracts for data privacy compliance.

Agent Workflow:
1. Accept contract upload (PDF/DOCX)
2. Extract text and structure
3. Identify data privacy sections
4. Analyze against GDPR/CCPA requirements
5. Flag risky clauses with severity (low/medium/high)
6. Generate suggested revisions
7. Produce summary report with citations

Success Criteria (from business_success_evals.md):
- Must achieve 95% accuracy on test set
- Must complete in <60 seconds
- Must cost <$5 per contract
- Must cite specific contract sections and regulations

User Stories:
- As a lawyer, I upload a contract and get a risk assessment in 60 seconds
- As a paralegal, I review flagged clauses and accept/reject suggestions
- As a law firm partner, I see analytics on contract risks across all clients
```

**Output**: `/specs/001-contract-review-agent/spec.md`

---

### Step 4: Plan (Agents + MCP + Tools)

**Purpose**: Design the technical architecture (agents, tools, evals).

**Command**: `/sp.plan`

**Example Prompt**:
```bash
/sp.plan

Technical Architecture:

Agents:
- ContractReviewAgent (main agent)
  - Tools: extract_text, analyze_clause, compare_regulations, suggest_revision
  - Model: GPT-4o (needs reasoning)
  - MCP Server: contract-analysis-server

Multi-Agent Pattern:
- Triage: Determines contract type (employment, SaaS, NDA, etc.)
- Specialist Agents: Per contract type (each knows relevant regulations)
- Review Agent: Quality check on findings

MCP Servers:
1. contract-analysis-server
   - Tools: parse_contract, extract_clauses, classify_risk
   - Resources: GDPR text, CCPA text, precedents database

2. legal-research-server (reusable)
   - Tools: search_regulations, find_precedents, cite_source
   - Resources: Legal databases, case law

Eval Harness:
- Component evals: Test each tool independently
- Integration evals: Test full workflow
- Regression tests: Production failures
- A/B testing: Compare prompt variations

Tech Stack:
- Agents: OpenAI Agents SDK (Python)
- MCP Servers: TypeScript (for performance)
- Evals: Braintrust or custom eval framework
- Storage: PostgreSQL (contracts, findings, feedback)
- Deployment: Docker + Kubernetes

Cost Estimate:
- GPT-4o API: ~$0.50 per contract (10K tokens * $0.005/1K)
- Compute: ~$0.10 per contract
- Total: ~$0.60 cost → sell for $50 (92% margin)
```

**Output**: `/specs/001-contract-review-agent/plan.md`

---

### Step 5: Tasks (TDD with Evals)

**Purpose**: Break down into testable tasks with evals.

**Command**: `/sp.tasks`

**Example Output** (`/specs/001-contract-review-agent/tasks.md`):

```markdown
## Phase 1: Baseline Setup + Evals

### Task 1.1: Set up eval harness
- [ ] Create test dataset (golden examples)
- [ ] Implement eval runner
- [ ] Define baseline: human lawyer accuracy (92%)

### Task 1.2: MCP Server - contract-analysis-server
- [ ] Tool: extract_text (PDF → text)
  - Eval: Extract 100% of text accurately
- [ ] Tool: extract_clauses (text → structured clauses)
  - Eval: Identify 95% of privacy clauses
- [ ] Tool: classify_risk (clause → risk level)
  - Eval: Match expert classification 90%+

## Phase 2: Agent Implementation

### Task 2.1: ContractReviewAgent baseline
- [ ] Implement basic workflow (upload → analyze → report)
- [ ] Run eval: Expect ~60% accuracy initially
- [ ] Iterate on prompts until 90%+ (don't proceed until hit threshold)

### Task 2.2: Improve to target quality
- [ ] A/B test prompt variations
- [ ] Add few-shot examples
- [ ] Fine-tune clause classification
- [ ] Run eval: Must hit 95% accuracy

## Phase 3: Production Readiness

### Task 3.1: Integration evals
- [ ] End-to-end tests on 50 contracts
- [ ] Latency <60s for P95
- [ ] Cost <$5 per contract

### Task 3.2: Production monitoring
- [ ] Set up eval sampling (10% of prod)
- [ ] Alert if accuracy drops below 93%
- [ ] Capture failures for regression tests
```

---

### Step 6: Implement (The Grind to 97%+)

**Purpose**: Build, test, iterate until hitting production quality.

**Command**: `/sp.implement`

**What Jake Heller Says**:
> "This is where most people fail. They get to 60% and think they're done. You need to spend WEEKS iterating on prompts, testing edge cases, and analyzing failures. The difference between 60% and 97% is the difference between a demo and a product."

**The Process**:

1. **Implement Baseline** (expect low quality):
   ```python
   # ContractReviewAgent v0.1
   agent = Agent(
       name="contract_review",
       instructions="Review contract for data privacy issues",
       tools=[extract_text, analyze_clause],
       model="gpt-4o"
   )
   ```

2. **Run Evals** (measure current quality):
   ```bash
   python run_evals.py --baseline
   # Result: 58% accuracy ← This is normal!
   ```

3. **Analyze Failures**:
   - Which contracts failed?
   - Which clauses were missed?
   - Which false positives?
   - Categorize error types

4. **Iterate on Prompts**:
   ```python
   # v0.2 - Added specific instructions
   instructions = """You are a senior lawyer specializing in data privacy.
   Review the contract for GDPR and CCPA compliance.

   For each clause:
   1. Identify if it relates to data processing
   2. Compare against regulations (be specific)
   3. Assess risk level: low, medium, high
   4. Cite the exact regulation violated (if any)

   Common issues to check:
   - Lack of data subject rights (GDPR Art. 15-22)
   - No data retention limits (GDPR Art. 5)
   - Missing consent mechanisms (CCPA § 1798.100)
   ...
   """
   ```

5. **Re-run Evals**:
   ```bash
   python run_evals.py --version v0.2
   # Result: 72% accuracy ← Improving!
   ```

6. **Repeat Steps 3-5**:
   - Keep iterating until hitting target (95%+)
   - This can take days or weeks
   - Add few-shot examples
   - Fine-tune prompts
   - Improve tools (better clause extraction)

7. **Component-Level Debugging**:
   ```bash
   # If full workflow is at 72%, test each step:
   python run_evals.py --component extract_clauses
   # → 85% accuracy (this is dragging down overall score)

   # Focus improvement efforts on weak component
   ```

8. **Production Deployment** (only when hitting thresholds):
   - ✓ Accuracy ≥ 95%
   - ✓ Latency <60s (P95)
   - ✓ Cost <$5 per contract
   - ✓ Passed all integration tests

---

## AI Native vs Traditional: Key Differences

### Success Metrics

| Traditional | AI Native |
|-------------|-----------|
| Features shipped | Professional-level accuracy achieved |
| User feedback | Eval scores (objective + subjective) |
| Code coverage | Test dataset coverage + edge cases |
| Deployment speed | Quality threshold hit (don't ship at 60%) |

### Development Process

| Traditional | AI Native |
|-------------|-----------|
| Write code → test | Write evals → iterate until passing |
| Features → MVP | Quality → Production |
| Fast iteration | Slow, deliberate quality improvement |
| Ship and iterate | Hit thresholds then ship |

### Business Model

| Traditional SaaS | AI Native |
|------------------|-----------|
| $20-100/month | $50-500 per task (or % of value) |
| Seat-based pricing | Value-based pricing |
| Sell features | Sell professional labor savings |
| TAM = # of companies | TAM = # of professionals × salary |

## Example: Pricing AI Native Software

**Traditional SaaS (Wrong)**:
- "Contract review tool: $99/month"
- TAM: 10,000 law firms × $99 = $1M/year

**AI Native (Correct)**:
- "Contract review: $50 per contract"
- Value: Saves $450 vs. human lawyer ($500 - $50)
- Customer ROI: 90% cost savings + 10x faster
- TAM: 1M contracts/year × $50 = $50M/year

**Jake Heller's Advice**:
> "Price at 10-20% of the value you deliver. If you save a customer $1000, charge $100-200. Don't think like a SaaS company charging $20/month. Your TAM is the total salaries of everyone you're replacing."

## Common Pitfalls to Avoid

### 1. Skipping Domain Expertise
❌ "I'll just build AI for lawyers without talking to any lawyers"
✓ "I worked as a paralegal for 3 months to deeply understand the work"

### 2. Shipping at 60% Accuracy
❌ "We have a working demo, let's ship and iterate"
✓ "We won't ship until we hit 95%+ on our eval set"

### 3. No Evals
❌ "Testing with a few examples manually"
✓ "50 golden examples, 20 edge cases, automated eval harness"

### 4. SaaS Pricing
❌ "$49/month for unlimited contract reviews"
✓ "$50 per contract (saves you $450 vs. hiring a lawyer)"

### 5. No Business Value Measurement
❌ "Our AI is really good at summarizing contracts"
✓ "Our AI reduces contract review time from 3 hours to 10 minutes, saving $400 per contract"

## Resources & Next Steps

### Skills to Master
1. `/templates/skills/mcp-builder-l1.skill.md` - Build MCP servers
2. `/templates/skills/mcp-exam.skill.md` - Validate knowledge
3. `/templates/skills/openai-agents-sdk-l2.skill.md` - Build agents

### Applied Evals
- `/docs-plus/08_applied_evals/` - Deep dive into evaluation strategies
- Braintrust, LangSmith, or custom eval frameworks

### Reference Architecture
- Multi-agent patterns: Triage → Specialists
- MCP server patterns: Tools, Resources, Prompts
- Eval patterns: Component → Integration → E2E

### Inspiration
- **Jake Heller's Talk**: "How to Build an AI Startup" (YouTube)
- **Casetext Case Study**: CoCounsel - AI legal assistant
- **Key Quote**: "Just build it. The difficulty of integrating data, fine-tuning prompts, and handling edge cases creates a moat that's hard to replicate."

---

## Summary: The AI Native Mindset

**Traditional Software**: "What features should we build?"
**AI Native Software**: "What expensive professional work can we automate?"

**Traditional Metrics**: "Did we ship the feature?"
**AI Native Metrics**: "Did we hit 97% accuracy?"

**Traditional Pricing**: "$99/month SaaS"
**AI Native Pricing**: "$50 per task (saves you $450)"

**Traditional TAM**: "10K companies × $99/mo"
**AI Native TAM**: "Salaries of everyone we're replacing"

---

**Welcome to AI Native Software Development. Now go build something that makes expert knowledge accessible to everyone.**

---

**Version**: 1.0.0
**Last Updated**: 2025-01-15
**Based on**: Jake Heller (Casetext/CoCounsel $650M exit)
**Part of**: SpecKitPlus - Spec-Driven Development for AI Native Software

# Security Audit Process Template

## 1. Pre-Audit Preparation

<details>
<summary><strong>Project Understanding</strong></summary>

- [ ] Read all project documentation (README, whitepaper, technical specs)
- [ ] Review similar projects and common vulnerabilities in similar systems
- [ ] Research the team's previous projects and security history
- [ ] Understand the business model and economic incentives
- [ ] Identify critical components and high-risk areas
</details>

<details>
<summary><strong>Communication Setup</strong></summary>

- [ ] Establish communication channels with the client team
- [ ] Clarify scope, timeline, and deliverables
- [ ] Set up a private repository for findings during the audit
- [ ] Schedule check-in meetings if appropriate
</details>

## 2. Environment Setup

<details>
<summary><strong>Repository Setup</strong></summary>

- [ ] Clone the repository
```bash
git clone <repository-url>
cd <repository-name>
```
- [ ] Check commit hash/tag to be audited
```bash
git log -1 --format="%H"
```
</details>

<details>
<summary><strong>Development Environment</strong></summary>

- [ ] Install dependencies
```bash
# For Hardhat
npm install

# For Foundry
forge install
```
- [ ] Run tests to verify correct setup
```bash
# For Hardhat
npx hardhat test

# For Foundry
forge test
```
- [ ] Check test coverage
```bash
# For Hardhat
npx hardhat coverage

# For Foundry
forge coverage
```
</details>

<details>
<summary><strong>Static Analysis Tools Setup</strong></summary>

- [ ] Install required static analysis tools
```bash
# Install Slither
pip3 install slither-analyzer

# Install Aderyn
cargo install aderyn

# Install solidity-metrics
npm install -g solidity-code-metrics
```
</details>

## 3. Initial Code Metrics & Analysis

<details>
<summary><strong>Code Statistics</strong></summary>

- [ ] Run cloc to understand codebase size
```bash
cloc ./src
```
</details>

<details>
<summary><strong>Complexity Analysis</strong></summary>

- [ ] Run solidity-metrics for complexity assessment
```bash
solidity-code-metrics ./src/*.sol > metrics.md
solidity-code-metrics ./src/*.sol --html > metrics.html
```
- [ ] Use Solidity Visual Developer extension (right-click on file/folder and select "Solidity: metrics")
</details>

<details>
<summary><strong>Documentation Evaluation</strong></summary>

- [ ] Check NatSpec coverage on functions and contracts
- [ ] Verify inline comments quality and frequency
- [ ] Match documentation to actual implementation
</details>

## 4. Static Analysis

<details>
<summary><strong>Automated Vulnerability Detection</strong></summary>

- [ ] Run Slither
```bash
slither .
```
- [ ] Run Aderyn
```bash
aderyn .
```
- [ ] Run additional specialty tools as needed (Mythril, etc.)
```bash
myth analyze ./src/Contract.sol
```
</details>

<details>
<summary><strong>Custom Detector Configuration</strong></summary>

- [ ] Configure Slither for project-specific detectors if needed
```bash
slither . --detect reentrancy,uninitialized-state
```
</details>

<details>
<summary><strong>Results Triage</strong></summary>

- [ ] Create list of findings from automated tools
- [ ] Filter out false positives
- [ ] Prioritize remaining issues by severity
</details>

## 5. Manual Code Review

<details>
<summary><strong>Architecture Review</strong></summary>

- [ ] Analyze overall system architecture
- [ ] Identify component interactions and dependencies
- [ ] Review protocol/token economics (if applicable)
- [ ] Check upgrade mechanisms (if applicable)
</details>

<details>
<summary><strong>Systematic Contract Review</strong></summary>

- [ ] Review contracts from most critical to least critical
- [ ] Examine inheritance relationships
- [ ] Review state variables and access modifiers
- [ ] Analyze external calls and interactions with other contracts
- [ ] Check mathematical operations for overflow/underflow
- [ ] Review event emissions for completeness
</details>

<details>
<summary><strong>Function-Level Review</strong></summary>

For each contract function:
- [ ] Verify authorization checks
- [ ] Check integer handling
- [ ] Verify error handling
- [ ] Review input validation
- [ ] Check for reentrancy vulnerabilities
- [ ] Analyze gas usage and optimization
- [ ] Verify business logic correctness
</details>

<details>
<summary><strong>Common Vulnerability Checklist</strong></summary>

- [ ] Reentrancy
- [ ] Front-running
- [ ] Timestamp dependence
- [ ] Access control issues
- [ ] Logic errors
- [ ] Integer overflow/underflow
- [ ] Denial of service vectors
- [ ] Oracle manipulation
- [ ] Flash loan attack vectors
- [ ] Unchecked return values
- [ ] Incorrect event emissions
- [ ] State inconsistencies
- [ ] Gas griefing opportunities
</details>

## 6. Dynamic Analysis

<details>
<summary><strong>Custom Testing</strong></summary>

- [ ] Create custom tests for identified potential vulnerabilities
- [ ] Create property-based tests or fuzz tests
- [ ] Develop scenario/integration tests for complex workflows
</details>

<details>
<summary><strong>Invariant Testing</strong></summary>

- [ ] Identify system invariants
- [ ] Implement tests to verify invariants are maintained
- [ ] Use formal verification tools if applicable
</details>

<details>
<summary><strong>Exploit Testing</strong></summary>

- [ ] Develop proof-of-concept exploits for confirmed vulnerabilities
- [ ] Test exploits in a controlled environment
- [ ] Document exploitation steps and impact
</details>

## 7. Findings Compilation

<details>
<summary><strong>Classify Issues</strong></summary>

- [ ] Rate each finding by severity (High, Medium, Low, Informational, Gas)
- [ ] Rate each finding by likelihood (High, Medium, Low)
- [ ] Apply risk matrix to determine final severity
- [ ] Document false positives and why they were classified as such
</details>

<details>
<summary><strong>Document Findings</strong></summary>

For each finding:
- [ ] Write clear title (including root cause and impact)
- [ ] Write detailed description
- [ ] Document vulnerable code snippets
- [ ] Explain potential impact
- [ ] Provide proof of concept
- [ ] Suggest mitigation strategies
- [ ] Retest any mitigations applied during the audit
</details>

## 8. Report Generation

<details>
<summary><strong>Draft Report</strong></summary>

- [ ] Compile executive summary
- [ ] Summarize methodology
- [ ] List all findings with severity
- [ ] Include detailed descriptions for each finding
- [ ] Add recommendations section
- [ ] Include any tools used
</details>

<details>
<summary><strong>Markdown Report</strong></summary>

- [ ] Format findings in markdown
```markdown
## [H-1] Title of High Severity Finding

**Description:**
Detailed explanation...

**Impact:**
Explanation of impact...

**Proof of Concept:**
Code or steps to reproduce...

**Recommended Mitigation:**
Suggested fix...
```
</details>

<details>
<summary><strong>PDF Report Generation</strong></summary>

- [ ] Install required tools
```bash
# Install pandoc and LaTeX
sudo apt-get install pandoc texlive-latex-recommended texlive-fonts-recommended texlive-latex-extra

# For footnotebackref.sty if needed
sudo apt-get install texlive-latex-extra
```
- [ ] Set up Eisvogel template
```bash
mkdir -p ~/.pandoc/templates/
wget https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/master/eisvogel.tex -O ~/.pandoc/templates/eisvogel.latex
```
- [ ] Prepare logo.pdf in the working directory
- [ ] Generate PDF
```bash
pandoc report.md -o report.pdf --from markdown --template=eisvogel --listings
```
</details>

## 9. Client Delivery & Communication

<details>
<summary><strong>Report Delivery</strong></summary>

- [ ] Send report to client through agreed-upon channel
- [ ] Schedule report walkthrough call if needed
- [ ] Explain findings and prioritization
- [ ] Answer any questions about findings or recommendations
</details>

<details>
<summary><strong>Remediation Review (Optional)</strong></summary>

- [ ] Review client's remediation plan
- [ ] Retest fixed vulnerabilities
- [ ] Provide feedback on implemented fixes
- [ ] Update report with remediation status
</details>

## 10. Post-Audit Activities

<details>
<summary><strong>Knowledge Sharing</strong></summary>

- [ ] Document lessons learned
- [ ] Share anonymized findings internally (respecting NDA)
- [ ] Add to internal knowledge base
- [ ] Update audit templates based on new findings
</details>

<details>
<summary><strong>Follow-ups</strong></summary>

- [ ] Check in with client post-deployment
- [ ] Offer additional services if needed (monitoring, incident response)
- [ ] Collect testimonial if appropriate
</details>

## Useful Commands Reference

<details>
<summary><strong>cloc - Count Lines of Code</strong></summary>

```bash
# Count lines in entire project
cloc .

# Count lines in specific directory
cloc ./src

# Count lines in specific file types
cloc --include-lang=Solidity .
```
</details>

<details>
<summary><strong>Solidity Metrics</strong></summary>

```bash
# Install globally
npm install -g solidity-code-metrics

# Generate metrics for specific files
solidity-code-metrics ./src/Contract1.sol ./src/Contract2.sol

# Output to markdown
solidity-code-metrics ./src/*.sol > metrics.md

# Output to HTML
solidity-code-metrics ./src/*.sol --html > metrics.html
```
</details>

<details>
<summary><strong>Slither</strong></summary>

```bash
# Run on entire project
slither .

# Run on specific file
slither ./src/Contract.sol

# Run specific detectors
slither . --detect reentrancy,uninitialized-state

# Generate JSON output
slither . --json output.json

# Print contract summary
slither . --print contract-summary

# Check function dependencies
slither . --print function-summary
```
</details>

<details>
<summary><strong>Aderyn</strong></summary>

```bash
# Run basic scan
aderyn .

# Specify output format
aderyn . --output-format markdown

# Scan specific directories
aderyn ./src

# Exclude certain detectors
aderyn . --exclude-detector unused-return
```
</details>

<details>
<summary><strong>Testing Commands</strong></summary>

```bash
# Hardhat testing
npx hardhat test
npx hardhat coverage

# Foundry testing
forge test
forge test --match-contract ContractName
forge test --match-test testFunctionName
forge coverage

# Fuzzing with Foundry
forge test --fuzz-runs 10000
```
</details>

<details>
<summary><strong>Report Generation</strong></summary>

```bash
# Generate PDF from markdown
pandoc report.md -o report.pdf --from markdown --template=eisvogel --listings

# Add table of contents
pandoc report.md -o report.pdf --from markdown --template=eisvogel --listings --toc

# Generate DOCX for client revisions
pandoc report.md -o report.docx
```
</details>
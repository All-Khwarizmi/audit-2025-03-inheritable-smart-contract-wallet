# AI Prompting Template for Security Audits

## Initial Code Analysis

<details>
<summary><strong>Code Understanding Prompt</strong></summary>

```
I need to understand this smart contract code. I'll share the contract and would like you to:
1. Explain the main purpose of the contract
2. Identify key functions and how they interact
3. Outline the roles/permissions in the system
4. Highlight potential areas of concern from a security perspective
5. Explain any complex or unusual patterns used

Here's the contract:

[PASTE CONTRACT CODE HERE]
```
</details>

<details>
<summary><strong>Protocol Architecture Analysis</strong></summary>

```
I'm analyzing a protocol with multiple contracts. I need to understand how they interact. Here are the main contracts:

[PASTE CONTRACT IMPORTS/INTERFACES OR SUMMARIZE STRUCTURE]

Please help me:
1. Map the relationships between these contracts
2. Identify the flow of value/assets through the system
3. Determine where external interactions occur
4. Highlight potential trust assumptions
5. Identify composability risks with other protocols
```
</details>

<details>
<summary><strong>Static Analysis Tool Results Interpretation</strong></summary>

```
I've run some static analysis tools on a smart contract and received these results:

[PASTE TOOL OUTPUT HERE]

Can you help me:
1. Prioritize which findings need further investigation
2. Identify potential false positives
3. Explain any complex vulnerabilities in simpler terms
4. Suggest additional areas to investigate based on these findings
```
</details>

## Vulnerability Analysis

<details>
<summary><strong>Vulnerability Verification Prompt</strong></summary>

```
I think I've found a vulnerability in this contract. Please help me verify if it's valid:

Potentially vulnerable code:
[PASTE CODE SNIPPET]

My concern is:
[EXPLAIN VULNERABILITY HYPOTHESIS]

Can you:
1. Confirm if this is indeed a vulnerability
2. Explain the potential impact
3. Suggest a proof-of-concept approach
4. Recommend potential mitigations
```
</details>

<details>
<summary><strong>Test Case Generation</strong></summary>

```
I need to create a test case to verify this potential vulnerability:

[DESCRIBE VULNERABILITY]

Relevant contract code:
[PASTE CODE SNIPPET]

Please help me write a test case that:
1. Sets up the necessary conditions
2. Demonstrates the vulnerability
3. Verifies the impact
4. Shows how it could be exploited

The project uses [Hardhat/Foundry/Truffle] for testing.
```
</details>

<details>
<summary><strong>Exploit Refinement</strong></summary>

```
I'm working on this proof-of-concept exploit, but it's not working as expected:

[PASTE CURRENT EXPLOIT CODE]

The issue I'm trying to demonstrate is:
[DESCRIBE VULNERABILITY]

The error or unexpected behavior I'm seeing is:
[DESCRIBE CURRENT RESULTS]

Can you help me refine this exploit to properly demonstrate the vulnerability?
```
</details>

## Finding Documentation

<details>
<summary><strong>Vulnerability Documentation Template</strong></summary>

```
I need to document this vulnerability I've found. Here are the details:

- Contract: [CONTRACT NAME]
- Function: [FUNCTION NAME]
- Vulnerability type: [e.g., Reentrancy, Access Control, etc.]
- Code snippet:
[PASTE VULNERABLE CODE]

My understanding of the issue:
[BRIEFLY DESCRIBE ISSUE]

Please help me create a comprehensive finding that includes:
1. A concise but descriptive title that indicates root cause and impact
2. A detailed description of the vulnerability
3. An assessment of the impact
4. A proof of concept (in pseudocode or actual code)
5. Recommended mitigations
```
</details>

<details>
<summary><strong>Format Conversion (Internal to Platform-Specific)</strong></summary>

```
I need to convert my vulnerability finding from my internal format to [PLATFORM NAME] format.

Here's my current finding:

[PASTE YOUR FINDING IN CURRENT FORMAT]

Here's the target platform's expected format:

[PASTE EXPECTED FORMAT OR DESCRIBE IT]

Please reformat my finding to match the target platform while preserving all technical details and severity.
```
</details>

<details>
<summary><strong>Severity Assessment</strong></summary>

```
I need to determine the appropriate severity for this vulnerability:

[PASTE VULNERABILITY DESCRIPTION]

Based on this platform's severity guidelines:
[PASTE SEVERITY GUIDELINES OR SPECIFY PLATFORM]

Please help me assess:
1. The potential impact if this vulnerability is exploited
2. The likelihood of successful exploitation
3. The appropriate severity rating (High/Medium/Low)
4. Justification for this severity that I can include in my report
```
</details>

## Report Generation

<details>
<summary><strong>Executive Summary Creation</strong></summary>

```
I've completed a security audit of [PROJECT NAME]. Here are the key findings:

High severity issues:
[LIST HIGH ISSUES]

Medium severity issues:
[LIST MEDIUM ISSUES]

Low severity issues:
[LIST LOW ISSUES]

Please help me create an executive summary that:
1. Provides an overview of the protocol and its purpose
2. Summarizes the scope of the audit
3. Presents key findings and risk assessment
4. Offers general recommendations
5. Is written in a professional tone suitable for both technical and non-technical stakeholders
```
</details>

<details>
<summary><strong>Recommendations Section</strong></summary>

```
Based on these findings from my audit of [PROJECT NAME]:

[LIST KEY FINDINGS]

Please help me create a comprehensive recommendations section that:
1. Prioritizes changes based on risk level
2. Provides specific, actionable advice for each issue
3. Suggests general improvements to the codebase beyond just fixing vulnerabilities
4. Recommends best practices for ongoing security maintenance
```
</details>

<details>
<summary><strong>Technical Writing Improvement</strong></summary>

```
I've written this section for my audit report, but I'd like to improve its clarity and professionalism:

[PASTE YOUR DRAFT]

Please help me:
1. Improve the technical accuracy and precision
2. Enhance readability for both technical and business stakeholders
3. Fix any grammatical or stylistic issues
4. Ensure consistency in terminology and tone
```
</details>

## Client Communication

<details>
<summary><strong>Finding Discussion Preparation</strong></summary>

```
I need to discuss this finding with the client team:

[PASTE FINDING]

The client might challenge or have questions about this finding. Please help me:
1. Prepare clear explanations of the technical details
2. Anticipate potential questions or objections
3. Provide additional context about why this is important
4. Suggest how to discuss the severity assessment if contested
```
</details>

<details>
<summary><strong>Mitigation Review</strong></summary>

```
The client has proposed this fix for a vulnerability I identified:

Original vulnerable code:
[PASTE ORIGINAL CODE]

Proposed fix:
[PASTE PROPOSED FIX]

The original issue was:
[DESCRIBE VULNERABILITY]

Please help me evaluate if:
1. The proposed fix adequately addresses the vulnerability
2. The fix introduces any new issues or concerns
3. There are any edge cases not covered by the fix
4. There might be a more optimal or comprehensive solution
```
</details>

## Learning & Improvement

<details>
<summary><strong>Vulnerability Pattern Explanation</strong></summary>

```
I've encountered this vulnerability pattern:

[DESCRIBE VULNERABILITY]

Please help me understand:
1. The fundamental causes of this type of vulnerability
2. Common variations of this vulnerability pattern
3. Best practices to prevent it
4. Examples of notable exploits using this pattern
5. How to better identify it in future audits
```
</details>

<details>
<summary><strong>Audit Technique Enhancement</strong></summary>

```
I want to improve my ability to identify [SPECIFIC VULNERABILITY TYPE] vulnerabilities.

My current approach is:
[DESCRIBE CURRENT METHODOLOGY]

Please suggest:
1. More effective techniques to identify these issues
2. Tools or methods that might help
3. Common patterns or code smells to watch for
4. Resources for deepening my understanding of this vulnerability class
```
</details>
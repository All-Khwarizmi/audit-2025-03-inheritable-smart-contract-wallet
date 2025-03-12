# Secutiry Audit steps

## Context

- Read any documentation you find relevant to the project you are reviewing.
- Understand the business logic of the project you are reviewing.

## Setup

- Clone the repository you are reviewing.
- Run the different test scripts to see if the project is setup correctly.
- run static analysis tools if possible.

## Static Analysis

<details>
<summary>cloc</summary>

```bash
cloc .
OR
cloc ./src
```

</details>

<details>
<summary>Solidity Metrics (audit estimation)</summary>
It is however more useful to install solidity-metrics globally and call it from any directory:

```bash
npm install -g solidity-code-metrics
solidity-code-metrics myfile1.sol myfile2.sol
```

By default, the cli outputs to the console, you can however store the output in a file rather easily (both markdown and html are supported):

```bash
solidity-code-metrics myfile.sol > metrics.md
solidity-code-metrics myfile.sol --html > metrics.html
```

</details>

<details>
<summary>Slither</summary>
<h3>
Usage</h3>
<p>
Run Slither on a Hardhat/Foundry/Dapp/Brownie application:
</p>

```bash
slither .
```

This is the preferred option if your project has dependencies as Slither relies on the underlying compilation framework to compile source code.

However, you can run Slither on a single file that does not import dependencies:

```bash
slither tests/uninitialized.sol

```

</details>

<details>

<summary>Aderyn</summary>

</details>
  
<details>

<summary>Solidity Visual Developer</summary>

right click on the file or folder and select "Solidity: metrics"

</details>

## Dynamic Analysis

- Scoping

- Reconnaissance

- Vulnerability identification

- Reporting

## Reporting

- generate a markdown report
- generate a pdf report
- export the report to github

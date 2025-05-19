# AI-NFT Royalty Distribution Smart Contract

A robust Clarity smart contract for managing AI-generated NFTs with automated, transparent royalty distribution and performance-based share optimization.

---

## Overview

This contract enables minting, transferring, and managing AI-generated NFTs (Non-Fungible Tokens) with built-in royalty mechanisms. It supports:

- **Royalty distribution** to creators and up to five contributors per NFT.
- **Performance-based royalty optimization** for dynamic, data-driven share allocation.
- **Platform fee management** and administrative controls.
- **Secure withdrawal** of accumulated royalties.

---

## Features

- **Minting AI-NFTs:** Creators can mint NFTs, specifying title, royalty rate (up to 30%), contributors, and their shares.
- **Royalty Distribution:** On each sale, royalties are split between creator and contributors according to predefined shares.
- **Performance Optimization:** Contributor shares can be recalculated based on historical sales and performance data.
- **Platform Fee:** A 5% platform fee is deducted from each sale.
- **Withdrawal:** Any address with a royalty balance can withdraw their funds.
- **Administrative Controls:** The contract owner can pause the contract or update the platform fee recipient.

---

## Data Structures

- **NFT Metadata:** Stores creator, title, royalty percentage, contributors, and their shares.
- **Royalty Balances:** Tracks the STX balance owed to each participant.
- **Performance Data:** Used for optimizing contributor shares based on historical activity.

---

## Usage

### Minting an AI-NFT

```lisp
(mint-ai-nft
  creator
  title
  royalty-percentage
  contributors
  contributor-shares
)
```
- `creator`: Principal address of the NFT creator.
- `title`: UTF-8 string (max 100 chars).
- `royalty-percentage`: Integer (max 30).
- `contributors`: List of up to 5 principal addresses.
- `contributor-shares`: List of up to 5 integers, matching contributors.

### Transferring with Royalty Payment

```lisp
(transfer-with-royalty
  token-id
  sender
  recipient
  price
)
```
- Transfers the NFT, deducts platform fee and royalty, and distributes funds accordingly.

### Withdrawing Royalties

```lisp
(withdraw-royalties)
```
- Any address with a positive royalty balance can call this to withdraw their STX.

### Optimizing Royalty Distribution

```lisp
(optimize-royalty-distribution
  token-id
  new-contributors
  new-shares
  performance-data
)
```
- Allows the contract owner to update contributors and shares based on recent performance metrics.

---

## Administrative Functions

- **set-platform-address:** Update the platform fee recipient (owner only).
- **set-paused:** Pause or unpause the contract (owner only).

---

## Error Handling

| Error Code | Description                   |
|------------|-------------------------------|
| 100        | Not authorized                |
| 101        | Invalid token                 |
| 102        | Invalid royalty percentage    |
| 103        | Invalid contributors/shares   |
| 104        | Contract is paused            |
| 105        | Insufficient balance          |
| 106        | Invalid shares                |

---

## License

```
MIT License

Copyright (c) 2025 AI-NFT-Royalty-Distribution

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Contribution Guidelines

We welcome contributions to improve the contract's security, efficiency, and features.

**How to contribute:**

- Fork the repository and create your branch.
- Ensure your code follows Clarity best practices and is well-documented.
- Write tests for any new functionality.
- Submit a pull request with a clear description of your changes.

**Code of Conduct:**

- Be respectful and constructive in all communications.
- Report security vulnerabilities privately to the maintainers.

---

## Security

- Only the contract owner can perform administrative actions such as pausing the contract or updating platform addresses.
- All critical operations (minting, transferring, optimizing) include rigorous authorization and validation checks.
- Funds are only transferred after all conditions are verified.

---

## Limitations

- Supports up to 5 contributors per NFT.
- Royalty percentage is capped at 30%.
- Platform fee is fixed at 5%, but the recipient can be changed by the owner.
- Contributor share optimization is based on provided performance data and is not fully automated.

---

## Contact

For questions, suggestions, or security disclosures, please open an issue or contact the maintainers directly.

---

**AI-NFT Royalty Distribution**  
Empowering transparent and fair royalty management for AI-generated NFTs.

# 🎓 Skill-Based Micro-Credentials

A blockchain-based system for issuing and managing NFT credentials for task-based learning achievements on the Stacks blockchain.

## 🚀 Features

- 🏆 **NFT Credentials**: Issue unique skill-based credentials as NFTs
- 👨‍🏫 **Authorized Issuers**: Only verified institutions can issue credentials  
- 📊 **Difficulty Levels**: Rate skills from 1-10 difficulty
- 🔗 **Prerequisites**: Set skill requirements and learning paths
- 📈 **Issuer Reputation**: Track issuer statistics and reputation scores
- 🔄 **Transferable**: Credentials can be transferred between users
- ✅ **Verification**: Built-in credential verification system

## 📋 Contract Functions

### 🔐 Admin Functions
- `authorize-issuer` - Authorize new credential issuers
- `revoke-issuer` - Remove issuer authorization
- `create-skill-category` - Define skill categories with difficulty ranges

### 🎯 Issuer Functions  
- `issue-credential` - Issue new skill credentials to users
- `set-skill-requirements` - Define prerequisites for skills
- `burn-credential` - Remove invalid credentials

### 👤 User Functions
- `transfer-credential` - Transfer credentials to other users
- `verify-credential` - Verify credential authenticity

### 📖 Read-Only Functions
- `get-credential` - Retrieve credential details
- `get-user-credentials` - Get all user credentials
- `get-issuer-stats` - View issuer statistics
- `is-issuer-authorized` - Check issuer authorization status

## 🛠️ Usage Examples

### Deploy and Setup

```bash
clarinet deploy
```

### Authorize an Issuer

```bash
clarinet console
```

```clarity
(contract-call? .skill-credentials authorize-issuer 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

### Issue a Credential

```clarity
(contract-call? .skill-credentials issue-credential 
  'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
  "JavaScript Fundamentals"
  u3
  "https://metadata.example.com/js-cert-001")
```

### Verify a Credential

```clarity
(contract-call? .skill-credentials verify-credential u1)
```

## 📊 Data Structures

### Credential
- `recipient` - Credential holder
- `skill-name` - Name of the skill
- `issuer` - Who issued the credential  
- `difficulty-level` - Skill difficulty (1-10)
- `timestamp` - When it was issued
- `metadata-uri` - Additional metadata location

### Issuer Stats
- `total-issued` - Number of credentials issued
- `reputation-score` - Reputation rating
- `verified` - Verification status

## 🔧 Development

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Testing

```bash
clarinet test
```

### Local Development

```bash
clarinet integrate
```

## 🎯 Use Cases

- 🏫 **Educational Institutions** - Issue course completion certificates
- 💼 **Corporate Training** - Track employee skill development  
- 🛠️ **Technical Skills** - Verify programming and technical abilities
- 🎨 **Creative Skills** - Certify artistic and design competencies
- 📚 **Professional Development** - Document career advancement

## 🔒 Security Features

- Only authorized issuers can create credentials
- Prerequisites prevent skill inflation
- Issuer reputation system maintains quality
- Credential burning for invalid certificates
- Transfer restrictions maintain authenticity

## 🌟 Future Enhancements

- Skill expiration dates
- Batch credential issuance
- Advanced prerequisite logic
- Integration with learning platforms
- Credential marketplace

---

Built with ❤️ using Clarity and Stacks blockchain
```

**Git Commit Message:**
```
feat: implement skill-based micro-credentials NFT system with issuer authorization
```

**GitHub Pull Request Title:**
```
🎓 Add Skill-Based Micro-Credentials MVP - NFT System for Learning Achievements
```

**GitHub Pull Request Description:**
```
## 🎯 Summary
Implements a complete skill-based micro-credentials system using NFTs on Stacks blockchain for tracking and verifying task-based learning achievements.

## ✨ Features Added
- NFT-based credential system with unique skill certificates
- Authorized issuer management with reputation tracking  
- Difficulty-based skill levels (1-10 scale)
- Prerequisite system for learning path enforcement
- Credential verification and transfer capabilities
- Comprehensive admin controls for system management

## 🔧 Technical Implementation
- Complete Clarity smart contract (150+ lines)
- Secure authorization patterns for issuers
- Efficient data structures for credentials and user tracking
- Read-only functions for easy integration
- Error handling for all edge cases

## 📚 Documentation
- Comprehensive README with usage examples
- Clear function documentation and use cases
- Development setup instructions
- Security feature explanations

Ready for deployment and testing on Stacks testnet.

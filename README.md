# 🏛️ Local Government DAO

A decentralized autonomous organization for local government operations where residents can participate in community governance through transparent voting and treasury management.

## 🌟 Features

- 🗳️ **Democratic Voting**: Residents vote on community proposals and budgets
- 💰 **Treasury Management**: Transparent fund allocation and tracking
- 🏢 **Service Provider Management**: Community-driven selection of service providers
- 👥 **Resident Registration**: Verified community member participation
- ⚖️ **Weighted Voting**: Configurable voting power for residents

## 🚀 Getting Started

### Prerequisites

- Clarinet installed
- Stacks wallet for testing

### Installation

```bash
clarinet new local-government-dao
cd local-government-dao
```

## 📋 Usage Instructions

### For Residents

#### 1. Register as a Resident
```clarity
(contract-call? .Local-Government-DAO register-resident)
```

#### 2. Contribute to Treasury
```clarity
(contract-call? .Local-Government-DAO deposit-to-treasury u1000000)
```

#### 3. Create a Proposal
```clarity
(contract-call? .Local-Government-DAO create-proposal 
  "New Park Development" 
  "Build a community park in downtown area" 
  u5000000 
  "infrastructure" 
  u144)
```

#### 4. Vote on Proposals
```clarity
(contract-call? .Local-Government-DAO vote-on-proposal u1 true)
```

### For Administrators

#### Execute Approved Proposals
```clarity
(contract-call? .Local-Government-DAO execute-proposal u1)
```

#### Manage Service Providers
```clarity
(contract-call? .Local-Government-DAO add-service-provider 
  "Clean Streets Inc" 
  "waste-management" 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  u500000)
```

#### Pay Service Providers
```clarity
(contract-call? .Local-Government-DAO pay-service-provider u1)
```

## 🔍 Read-Only Functions

### Check Proposal Status
```clarity
(contract-call? .Local-Government-DAO get-proposal u1)
```

### View Treasury Balance
```clarity
(contract-call? .Local-Government-DAO get-treasury-balance)
```

### Check Resident Status
```clarity
(contract-call? .Local-Government-DAO get-resident-status 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 🏗️ Contract Architecture

### Core Components

- **Residents**: Registered community members with voting rights
- **Proposals**: Community initiatives requiring funding and approval
- **Treasury**: Shared fund pool for approved proposals
- **Service Providers**: External contractors for community services
- **Voting System**: Democratic decision-making mechanism

### Proposal Types

- `infrastructure` - Roads, parks, public buildings
- `budget` - Annual budget allocations
- `service` - Service provider contracts
- `policy` - Community policy changes

## 🔒 Security Features

- Resident verification required for participation
- One vote per resident per proposal
- Time-locked voting periods
- Treasury balance validation
- Administrative controls for sensitive operations

## 🧪 Testing

```bash
clarinet test
```

## 📊 Example Workflow

1. **Community Setup**: Residents register and contribute to treasury
2. **Proposal Creation**: Resident proposes new community center
3. **Voting Period**: Community votes over 144 blocks (~24 hours)
4. **Execution**: If approved, funds are transferred to proposer
5. **Service Management**: Ongoing payments to approved service providers

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

---

*Built with ❤️ for transparent local governance*
```

**Git Commit Message:**
```
feat: implement Local Government DAO with voting, treasury, and service provider management
```

**GitHub Pull Request Title:**
```
🏛️ Add Local Government DAO Smart Contract
```

**GitHub Pull Request Description:**
```
## Summary
Added a comprehensive Local Government DAO smart contract that enables transparent community governance through democratic voting and treasury management.

## Features Added
- ✅ Resident registration and verification system
- ✅ Proposal creation and voting mechanism  
- ✅ Treasury management with deposit and withdrawal controls
- ✅ Service provider management system
- ✅ Weighted voting power system
- ✅ Time-locked voting periods
- ✅ Comprehensive read-only functions for transparency

## Contract Capabilities
- Residents can register, create proposals, and vote on community initiatives
- Transparent treasury management with fund tracking
- Service provider onboarding and payment automation
- Democratic decision-making with configurable voting periods
- Administrative controls for sensitive operations

## Testing
- All core functions implemented and ready for testing
- Comprehensive error handling with descriptive error codes
- Read-only functions for complete state visibility

Ready for community deployment and testing! 🚀

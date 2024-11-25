# Fortupool 🎰

A decentralized no-loss lottery platform where users can deposit funds, participate in weekly prize draws, and potentially win rewards without risking their principal. The platform leverages Chainlink VRF for secure random number generation and LayerZero for cross-chain deposits.

<center>
<h3>Powered By</h3>
</br>
<div>
  <img src="https://docs.layerzero.network/img/LayerZero_Logo_Black.svg" width="200" alt="LayerZero">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuD0jFOi1zVS2l21dEJQyALuaxEXIKUma45w&s" width="200" alt="Chainlink">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://res.cloudinary.com/dvujqu8pe/image/upload/h_80,f_auto/v1679692494/Companies/goldsky-logo" width="200" alt="Chainlink">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://logovtor.com/wp-content/uploads/2020/11/openzeppelin-logo-vector.png" width="200" alt="Chainlink">
</div>
</center>

## Features ✨

- **No-Loss Lottery**: Users maintain their principal while having a chance to win prizes
- **Fair Chance System**: Winning probability scales with deposit amount and holding duration
- **Weekly Prize Distribution**: Regular reward distributions to keep the game exciting
- **Cross-Chain Deposits**: Seamless deposits from multiple blockchain networks via LayerZero
- **Verifiable Randomness**: Transparent winner selection powered by Chainlink VRF
- **Decentralized Operations**: Automated winner selection through dedicated operator service

## Architecture 🏗️

The project consists of three main components:

1. **Fortupool.sol** (`./src/Fortupool.sol`)
   - Core contract handling deposits, withdraw, and winner selection
   - Manages user balances and prize pool
   - Integrates with Chainlink VRF for random number generation
   - Implements weekly prize distribution logic

2. **FortuReceiver.sol** (`./src/FortuReceiver.sol`)
   - Handles cross-chain deposits via LayerZero protocol
   - Decodes incoming messages from other chains
   - Forwards deposit information to main Fortupool contract

3. **Fortu Operator** ([Repository](https://github.com/onekill0503/fortu-operator))
   - External service monitoring Chainlink VRF responses
   - Processes random numbers to select winners
   - Calculated every users tickets based on deposit amount and block holding
   - Maintains lottery cycles and scheduling

## How It Works 🔄

1. **Depositing**
   - Users can deposit funds directly on the native chain
   - Cross-chain deposits are handled through LayerZero integration
   - Each deposit increases the user's chance of winning

2. **Winning Chances**
   - Probability is calculated based on:
     - Deposit amount: Larger deposits = Higher chances
     - Holding duration: Longer holds = Higher chances

3. **Winner Selection**
   - Chainlink VRF generates verifiable random numbers
   - Operator service monitors for VRF responses
   - Winner selected based on weighted probabilities by operator
   - Prizes automatically distributed by owner

# Future Development Roadmap 🚀

## Operator Incentivization System 💸

### Operator Rewards Program
- Implement token rewards for successful winner submissions
- Revenue sharing model from protocol fees
- Staking requirements for operators to ensure reliability
- Automated operator rotation for fairness

## Protocol Enhancements 🔄

### Enhanced Prize Pool Mechanics
1. **Multiple Prize Tiers**
   - First prize: 50% of pool
   - Second prize: 30% of pool
   - Multiple smaller prizes: 20% of pool
   - Increases winning chances and user engagement

2. **Special Events**
   - Milestone celebrations
   - Partnership promotional pools

### Yield Optimization
1. **Multi-Protocol Yield Farming**
   - Integration with multiple DeFi protocols
   - Automated yield optimization
   - Risk-adjusted strategy selection
   - Higher rewards from better yield management

## User Experience Improvements 🎯

### Enhanced Ticket System
1. **NFT-Based Tickets**
   - Tradeable lottery tickets
   - Historical winning ticket collection
   - Special edition tickets
   - Secondary market for tickets

2. **Ticket Boosters**
   - Loyalty multipliers
   - Streak bonuses
   - Friend referral boosts
   - Community participation rewards

## Protocol Expansion 🌐

### Cross-Chain Enhancement
1. **Chain-Specific Pools**
   - Native token pools
   - Optimized gas management

## Governance & Tokenomics 🏛️

### Protocol Token
1. **Utility**
   - Governance rights
   - Fee sharing
   - Boost multipliers
   - Operator staking

2. **Tokenomics**
   - Operator rewards
   - User incentives
   - Protocol development
   - Community treasury

### DAO Structure
- Protocol parameter governance
- Strategy selection
- Operator management
- Treasury allocation

## Security & Risk Management 🔒

### Enhanced Security Features
- Multi-sig operations
- Time-locks for major changes
- Emergency shutdown mechanisms
- Regular security audits

### Risk Management
- Insurance pool

## Technical Improvements 🛠️

### Infrastructure
1. **Scalability**
   - Optimized gas usage
   - Batch processing
   - Performance optimization

2. **Monitoring & Analytics**
   - Advanced analytics dashboard
   - Real-time monitoring
   - Performance metrics
   - Risk indicators

### Smart Contract Upgrades
- Modular contract structure
- Upgradeable components
- Enhanced access control
- Optimized gas efficiency

## Revenue Streams 💰

### Fee Structure
1. **Protocol Fees**
   - Small deposit fee
   - Yield performance fee
   - Early withdrawal fee
   - Premium features

2. **Revenue Distribution**
   - Operator rewards
   - Protocol development
   - Community treasury
   - Token buyback/burn

## Next Steps 📋

### Immediate Priorities
1. Implement operator reward system
2. Develop multiple prize tiers
3. Enhance yield strategies
4. Launch governance structure

## Prerequisites 📋

- [Foundry](https://github.com/foundry-rs/foundry)
- LayerZero endpoints configuration at FortuReceiver
- Chainlink VRF (deposit some eth on main contract)

## Security 🔒

- Chainlink VRF ensures fair and verifiable randomness
- Smart contracts pending audit
- Built-in delay mechanisms for large withdrawals
- Emergency pause functionality for critical situations
- Operator service runs with limited permissions

## Related Projects 🔗

- [Fortu Operator](https://github.com/onekill0503/fortu-operator) - Operator service for winner selection and prize distribution

## License 📄

Distributed under the MIT License. See `LICENSE.md` for more information.

## Contact 📧

Your Name - [@0xAlwaysbedream](https://twitter.com/0xAlwaysbedream)

Project Link: [https://github.com/onekill0503/fortupool](https://github.com/onekill0503/fortupool)

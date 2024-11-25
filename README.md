# Fortupool 🎰

A decentralized no-loss lottery platform where users can deposit funds, participate in weekly prize draws, and potentially win rewards without risking their principal. The platform leverages Chainlink VRF for secure random number generation and LayerZero for cross-chain deposits.

<center>
<h3>Powered By</h3>
</br>
<div>
  <img src="https://docs.layerzero.network/img/LayerZero_Logo_Black.svg" width="200" alt="LayerZero">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuD0jFOi1zVS2l21dEJQyALuaxEXIKUma45w&s" width="200" alt="Chainlink">
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

## Prerequisites 📋

- [Foundry](https://github.com/foundry-rs/foundry)
- LayerZero endpoints configuration at FortuReceiver
- Chainlink VRF (deposit some eth on main contract)
- Rust (for running operator service)

## Installation 🛠️

```bash
# Clone the repository
git clone https://github.com/yourusername/fortupool.git
cd fortupool

# Install Foundry dependencies
forge install

# Build contracts
forge build

# Set up environment variables
cp .env.example .env
# Add your configuration details to .env
```

## Configuration ⚙️

1. Set up environment variables in `.env`:
   ```
   PRIVATE_KEY=your_private_key
   LAYERZERO_ENDPOINT=endpoint_address
   CHAINLINK_VRF_COORDINATOR=coordinator_address
   OPERATOR_ADDRESS=operator_contract_address
   ```

2. Configure supported chains in the network configuration file

## Usage 💡

1. **Deploy Contracts**
   ```bash
   forge script script/Deploy.s.sol:Deploy --rpc-url <your_rpc_url> --broadcast
   ```

2. **Run Tests**
   ```bash
   forge test
   ```

3. **Setup Operator Service**
   - Follow setup instructions at [fortu-operator](https://github.com/onekill0503/fortu-operator)
   - Configure operator with deployed contract addresses
   - Start operator service to begin monitoring for VRF events

## Testing 🧪

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/Fortupool.t.sol

# Run tests with verbosity
forge test -vvv
```

## Security 🔒

- Chainlink VRF ensures fair and verifiable randomness
- Smart contracts pending audit
- Built-in delay mechanisms for large withdrawals
- Emergency pause functionality for critical situations
- Operator service runs with limited permissions

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Related Projects 🔗

- [Fortu Operator](https://github.com/onekill0503/fortu-operator) - Operator service for winner selection and prize distribution

## License 📄

Distributed under the MIT License. See `LICENSE.md` for more information.

## Contact 📧

Your Name - [@0xAlwaysbedream](https://twitter.com/0xAlwaysbedream)

Project Link: [https://github.com/onekill0503/fortupool](https://github.com/onekill0503/fortupool)

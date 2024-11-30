# Competition Smart Contract

## Overview

This Clarity smart contract provides a decentralized platform for creating and participating in competitions on the Stacks blockchain. Participants can join competitions by paying a stake, and the winner is determined deterministically based on the block height.

## Features

- Create new competitions with a custom name, duration, and stake amount
- Join existing competitions by paying the required stake
- Automatic prize pool accumulation
- Deterministic winner selection
- Limited to 50 participants per competition

## Contract Functions

### `create-competition`
- Creates a new competition
- Parameters:
    - `name`: Competition name (up to 64 ASCII characters)
    - `duration`: Number of blocks the competition will run
    - `stake-amount`: Amount of STX required to join the competition
- Returns the unique competition ID

### `join-competition`
- Allows a user to join an ongoing competition
- Requires paying the stake amount
- Adds participant to the competition
- Increases the prize pool
- Prevents joining after competition end

### `end-competition`
- Closes the competition
- Distributes the entire prize pool to a single winner
- Winner is selected using a pseudo-random method based on block height
- Can only be called after the competition end block

### `get-competition`
- Read-only function to retrieve competition details
- Returns competition information if it exists

## Constants

- `contract-owner`: The address that deployed the contract
- Error constants for various validation checks:
    - `err-owner-only`: Unauthorized access attempt
    - `err-competition-not-found`: Specified competition does not exist
    - `err-competition-ended`: Attempted action after competition end

## Security Considerations

- Stake amounts are transferred to the contract upon joining
- Limited to 50 participants to prevent DOS
- Winner selection is deterministic to ensure fairness
- Competitions have a predefined duration

## Deployment Requirements

- Requires a Stacks wallet with sufficient STX for transaction fees
- Compatible with Stacks blockchain development environments

## Example Usage

```clarity
;; Create a competition
(create-competition "Weekly Coding Challenge" u1000 u100)

;; Join the competition (requires 100 STX stake)
(join-competition u1)

;; End the competition after duration
(end-competition u1)
```

## Potential Improvements

- Add more complex winner selection algorithms
- Implement partial prize distribution
- Add competition categories or types
- Create withdraw mechanisms for unclaimed prizes

## License

[Specify your license here, e.g., MIT, Apache 2.0]

## Contributing

Contributions are welcome! Please submit pull requests or open issues on the project repository.

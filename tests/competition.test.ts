import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock blockchain state
interface BlockchainState {
  pets: Map<number, Pet>;
  competitions: Map<number, Competition>;
  currentBlock: number;
  balances: Map<string, number>;
}

interface Pet {
  owner: string;
  dna: string;
  name: string;
  birthBlock: number;
  parent1?: number;
  parent2?: number;
}

interface Competition {
  name: string;
  startBlock: number;
  endBlock: number;
  stakeAmount: number;
  prizePool: number;
  participants: string[];
}

describe('Virtual Pet Competition', () => {
  let state: BlockchainState;
  const wallet1 = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const wallet2 = 'ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const deployer = 'ST3PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  
  beforeEach(() => {
    // Reset blockchain state before each test
    state = {
      pets: new Map(),
      competitions: new Map(),
      currentBlock: 1,
      balances: new Map([
        [wallet1, 1000],
        [wallet2, 1000],
        [deployer, 1000]
      ])
    };
  });
  
  // Mock contract functions
  const mintPet = (sender: string, name: string): number => {
    const petId = state.pets.size + 1;
    const pet: Pet = {
      owner: sender,
      dna: `DNA_${Math.random().toString(36)}`,
      name,
      birthBlock: state.currentBlock
    };
    state.pets.set(petId, pet);
    return petId;
  };
  
  const createCompetition = (
      sender: string,
      name: string,
      duration: number,
      stakeAmount: number
  ): number => {
    const competitionId = state.competitions.size + 1;
    const competition: Competition = {
      name,
      startBlock: state.currentBlock,
      endBlock: state.currentBlock + duration,
      stakeAmount,
      prizePool: 0,
      participants: []
    };
    state.competitions.set(competitionId, competition);
    return competitionId;
  };
  
  const joinCompetition = (sender: string, competitionId: number, petId: number): boolean => {
    const competition = state.competitions.get(competitionId);
    const pet = state.pets.get(petId);
    
    if (!competition || !pet) throw new Error('Competition or pet not found');
    if (pet.owner !== sender) throw new Error('Not pet owner');
    if (state.currentBlock >= competition.endBlock) throw new Error('Competition ended');
    
    const balance = state.balances.get(sender) || 0;
    if (balance < competition.stakeAmount) throw new Error('Insufficient balance');
    
    // Update balances
    state.balances.set(sender, balance - competition.stakeAmount);
    competition.prizePool += competition.stakeAmount;
    competition.participants.push(sender);
    return true;
  };
  
  // Tests
  it('allows minting a new pet', () => {
    const petId = mintPet(wallet1, 'Fluffy');
    const pet = state.pets.get(petId);
    
    expect(petId).toBe(1);
    expect(pet).toBeDefined();
    expect(pet?.name).toBe('Fluffy');
    expect(pet?.owner).toBe(wallet1);
  });
  
  it('allows creating a new competition', () => {
    const competitionId = createCompetition(deployer, 'Pet Olympics', 100, 10);
    const competition = state.competitions.get(competitionId);
    
    expect(competitionId).toBe(1);
    expect(competition).toBeDefined();
    expect(competition?.name).toBe('Pet Olympics');
    expect(competition?.stakeAmount).toBe(10);
  });
  
  it('allows joining a competition with a pet', () => {
    const petId = mintPet(wallet1, 'Competitor');
    const competitionId = createCompetition(deployer, 'Quick Race', 100, 50);
    
    const result = joinCompetition(wallet1, competitionId, petId);
    const competition = state.competitions.get(competitionId);
    
    expect(result).toBe(true);
    expect(competition?.participants).toContain(wallet1);
    expect(competition?.prizePool).toBe(50);
    expect(state.balances.get(wallet1)).toBe(950); // Initial 1000 - 50 stake
  });
  
  it('prevents joining a competition with someone else\'s pet', () => {
    const petId = mintPet(wallet1, 'Alice\'s Pet');
    const competitionId = createCompetition(deployer, 'Quick Race', 100, 50);
    
    expect(() =>
        joinCompetition(wallet2, competitionId, petId)
    ).toThrow('Not pet owner');
  });
  
  it('prevents joining a competition after it ends', () => {
    const petId = mintPet(wallet1, 'Late Pet');
    const competitionId = createCompetition(deployer, 'Quick Race', 10, 50);
    
    // Advance blockchain
    state.currentBlock += 11;
    
    expect(() =>
        joinCompetition(wallet1, competitionId, petId)
    ).toThrow('Competition ended');
  });
  
  it('prevents joining with insufficient balance', () => {
    const petId = mintPet(wallet1, 'Expensive Pet');
    const competitionId = createCompetition(deployer, 'High Stakes', 100, 2000);
    
    expect(() =>
        joinCompetition(wallet1, competitionId, petId)
    ).toThrow('Insufficient balance');
  });
});


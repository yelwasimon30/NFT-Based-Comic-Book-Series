# 📚 NFT-Based Comic Book Series

A Clarity smart contract that enables comic book chapters as NFTs, allowing readers to unlock, own, trade, and upgrade their digital comic collection on the Stacks blockchain.

## 🚀 Features

- 🎨 **Chapter NFTs**: Each comic chapter is represented as a unique NFT
- 🔓 **Time-Locked Releases**: Chapters unlock at specific block heights
- 💰 **Marketplace Ready**: Built-in transfer functionality for trading
- ⬆️ **Upgradeable**: Enhance your NFTs with upgrade levels
- 📖 **Reading Tracker**: Track when chapters are read
- 👥 **Collection Management**: View user's complete comic collection

## 📋 Contract Functions

### Owner Functions
- `create-chapter` - Create new comic chapters (owner only)

### Public Functions
- `mint-chapter` - Purchase and mint a chapter NFT
- `transfer-chapter` - Transfer chapter to another user
- `upgrade-chapter` - Upgrade your chapter NFT (increases value)
- `read-chapter` - Mark chapter as read (updates last-read timestamp)

### Read-Only Functions
- `get-chapter-info` - Get chapter metadata
- `get-chapter-owner` - Get current owner of a chapter
- `get-user-chapters` - Get user's chapter collection
- `is-chapter-unlocked` - Check if chapter is available for minting
- `get-ownership-info` - Get ownership details for a specific chapter

## 🛠️ Usage

### Deploy Contract
```bash
clarinet deploy
```

### Create a Chapter (Owner Only)
```clarity
(contract-call? .NFT-Based-Comic-Book-Series create-chapter 
  "Chapter 1: The Beginning" 
  "Our hero discovers their hidden powers"
  "https://example.com/chapter1.jpg"
  u1000000  ; Price in microSTX
  u144      ; Unlock after 144 blocks (~24 hours)
  u1000)    ; Max supply
```

### Mint a Chapter
```clarity
(contract-call? .NFT-Based-Comic-Book-Series mint-chapter u1)
```

### Transfer Chapter
```clarity
(contract-call? .NFT-Based-Comic-Book-Series transfer-chapter u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Upgrade Chapter
```clarity
(contract-call? .NFT-Based-Comic-Book-Series upgrade-chapter u1)
```

### Read Chapter
```clarity
(contract-call? .NFT-Based-Comic-Book-Series read-chapter u1)
```

## 📊 Data Structure

Each chapter contains:
- **Title**: Chapter name (64 chars max)
- **Description**: Chapter summary (256 chars max)  
- **Image URI**: Chapter artwork URL (128 chars max)
- **Price**: Minting cost in microSTX
- **Upgrade Level**: Enhancement level (0-10)
- **Unlock Height**: Block height when available
- **Supply**: Current and maximum supply limits

## 🎯 Business Model

1. **Primary Sales**: Users mint chapters at base price
2. **Secondary Market**: Users trade chapters peer-to-peer
3. **Upgrades**: Users pay to enhance their NFTs
4. **Scarcity**: Limited supply per chapter creates value

## 🔧 Development

### Requirements
- Clarinet CLI
- Stacks blockchain testnet/mainnet access

### Testing
```bash
clarinet test
```

### Local Development
```bash
clarinet console
```

## 📄 License

MIT License - Feel free to fork and modify!

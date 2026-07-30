# GIWA Tap — Instant On-Chain Tips & Micro-Payments

MVP for the **GASOK** application (Mass Adoption track). A single QR code or link lets anyone
send an instant, low-fee on-chain tip/payment on **GIWA Sepolia** (Ethereum L2) — no account,
no signup, no custody. Built for cafes, street vendors, creators, and event organizers who want
"tap to pay" simplicity with the transparency of on-chain settlement.

## What's in this folder

| File | Purpose |
|---|---|
| `GiwaTap.sol` | The on-chain contract. One function (`tap`) forwards ETH instantly to a recipient and logs sender, amount, optional message, and timestamp. Non-custodial — the contract never holds a balance between calls. |
| `GiwaTap.abi.json` | Compiled ABI (generated locally with `solc 0.8.24`, optimizer on, 200 runs). Compiles clean with zero errors/warnings. |
| `index.html` | The entire app frontend — one file, no build step. Generates a QR code / shareable link for any address, connects MetaMask, auto-adds/switches to GIWA Sepolia, sends tips, and shows a live history feed. |

## 1. Deploy the contract (2 minutes, no CLI needed)

1. Go to [Remix IDE](https://remix.ethereum.org).
2. Create a new file `GiwaTap.sol` and paste in the contents of `GiwaTap.sol` from this folder.
3. **Compile** tab → select compiler `0.8.24` (or any `0.8.x`) → Compile.
4. **Deploy & Run** tab → Environment: `Injected Provider - MetaMask`.
5. In MetaMask, make sure you're on **GIWA Sepolia**:
   - Chain ID: `91342`
   - RPC URL: `https://sepolia-rpc.giwa.io/`
   - Currency symbol: `ETH`
   - Block explorer: `https://sepolia-explorer.giwa.io`
   - (Fund your wallet first from the GIWA Sepolia faucet — linked from the docs/explorer site — since you need testnet ETH to deploy and to send tips.)
6. Click **Deploy**, confirm in MetaMask. Copy the deployed contract address from Remix.

## 2. Point the frontend at your deployed contract

Open `index.html`, find this line near the top of the `<script>` block:

```js
const CONTRACT_ADDRESS = "0x0000000000000000000000000000000000dEaD"; // <-- REPLACE after deploy
```

Replace it with your deployed address. That's it — no build step, no dependencies to install.

> Until you do this, the app still works end-to-end in a **fallback mode**: it sends a plain ETH
> transfer instead of calling the contract, so you can demo the QR/link/send flow immediately
> and wire in the contract (for on-chain messages + history) right after.

## 3. Run it

Any static file host works — GitHub Pages, Vercel, Netlify, or just open `index.html` locally.
For local testing:

```bash
python3 -m http.server 8080
# open http://localhost:8080/index.html
```

## How the demo flow works

1. **Receive tab** — a cafe/creator connects their wallet (or pastes an address), gets an instant
   QR code + shareable link (`?to=0xADDRESS`).
2. **Send tab** — whoever scans the QR lands with the recipient pre-filled, connects MetaMask
   (auto-prompted to add/switch to GIWA Sepolia if needed), enters an amount and optional
   message, and taps **Gönder**. Funds land in the recipient's wallet in the same transaction.
3. Every tip is logged on-chain (`Tipped` event) and shown in a live feed on both tabs — provable,
   permanent, and shareable payment history with zero backend/server required.

## Why this fits GASOK's Mass Adoption track

- **Real-world use case, zero learning curve**: scan → send → done. No wallet jargon exposed
  beyond the one MetaMask popup users already know from any dApp.
- **GIWA Wallet-compatible by design**: the app only depends on the standard `window.ethereum`
  / EIP-1193 provider interface, so it works with MetaMask today and the GIWA Wallet the moment
  it ships, without code changes.
- **Non-custodial & auditable**: the contract never custodies funds; every tip is a public event
  on GIWA Sepolia, viewable on the [explorer](https://sepolia-explorer.giwa.io).
- **Cheap to run at scale**: GIWA's L2 fees make micro-tips (a few cents) economically viable,
  which isn't true on L1 Ethereum.

## Roadmap (post-MVP, if selected)

- **Phase 2 (MVP → testnet users)**: add ENS-style memorable handles instead of raw addresses,
  static QR stickers for physical venues (cafes, markets), basic analytics dashboard for
  recipients (total received, top supporters).
- **Phase 3 (productize)**: GIWA Wallet in-app placement, batched/recurring tips (subscriptions),
  fiat on-ramp for first-time senders, merchant dashboard with CSV export for accounting.
- **Growth**: partner with a handful of Korea Blockchain Week vendors / creators for a live
  on-site pilot at demo day.

## Technical notes

- Contract compiled locally with `solc@0.8.24`: **0 errors, 0 warnings**, optimizer enabled
  (200 runs). Bytecode verified reproducible from `GiwaTap.sol` as committed here.
- Frontend tested headlessly (Playwright/Chromium) against the real `ethers@6.13.4` and
  `qrcodejs@1.0.0` packages: QR generation, shareable-link construction, and `?to=` deep-link
  pre-fill all verified working with zero console errors.
- No backend, no database, no API keys required to run the MVP — everything reads/writes
  directly against GIWA Sepolia.

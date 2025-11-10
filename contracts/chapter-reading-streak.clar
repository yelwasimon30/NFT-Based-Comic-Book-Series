(define-non-fungible-token streak-badge uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-no-streak (err u401))
(define-constant err-already-claimed-today (err u402))
(define-constant err-chapter-not-owned (err u403))
(define-constant err-reward-not-available (err u404))

(define-data-var next-badge-id uint u1)
(define-data-var blocks-per-day uint u144)
(define-data-var streak-reward-pool uint u0)

(define-map user-streaks
  principal
  {current-streak: uint, longest-streak: uint, last-read-block: uint, total-reads: uint}
)

(define-map streak-tiers
  uint
  {min-days: uint, stx-reward: uint, badge-uri: (string-ascii 128)}
)

(define-map claimed-rewards
  {user: principal, tier: uint}
  {claimed-at: uint, badge-id: uint}
)

(define-public (initialize-tiers)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set streak-tiers u1 {min-days: u7, stx-reward: u500000, badge-uri: "ipfs://bronze-streak"})
    (map-set streak-tiers u2 {min-days: u30, stx-reward: u2000000, badge-uri: "ipfs://silver-streak"})
    (map-set streak-tiers u3 {min-days: u90, stx-reward: u10000000, badge-uri: "ipfs://gold-streak"})
    (ok true)
  )
)

(define-public (record-reading (chapter-id uint))
  (let (
    (chapter-owner (unwrap! (contract-call? .NFT-Based-Comic-Book-Series get-chapter-owner chapter-id) err-chapter-not-owned))
    (user-data (default-to {current-streak: u0, longest-streak: u0, last-read-block: u0, total-reads: u0} 
                  (map-get? user-streaks tx-sender)))
    (blocks-since-last (- stacks-block-height (get last-read-block user-data)))
    (blocks-per-day-val (var-get blocks-per-day))
    (is-consecutive (and (> blocks-since-last u0) (<= blocks-since-last (* blocks-per-day-val u2))))
    (new-streak (if is-consecutive (+ (get current-streak user-data) u1) u1))
    (new-longest (if (> new-streak (get longest-streak user-data)) new-streak (get longest-streak user-data)))
  )
    (asserts! (is-eq tx-sender chapter-owner) err-chapter-not-owned)
    (asserts! (>= blocks-since-last blocks-per-day-val) err-already-claimed-today)
    (map-set user-streaks tx-sender {
      current-streak: new-streak,
      longest-streak: new-longest,
      last-read-block: stacks-block-height,
      total-reads: (+ (get total-reads user-data) u1)
    })
    (ok new-streak)
  )
)

(define-public (claim-streak-reward (tier uint))
  (let (
    (user-data (unwrap! (map-get? user-streaks tx-sender) err-no-streak))
    (tier-data (unwrap! (map-get? streak-tiers tier) err-reward-not-available))
    (already-claimed (map-get? claimed-rewards {user: tx-sender, tier: tier}))
    (badge-id (var-get next-badge-id))
  )
    (asserts! (is-none already-claimed) err-reward-not-available)
    (asserts! (>= (get longest-streak user-data) (get min-days tier-data)) err-no-streak)
    (try! (nft-mint? streak-badge badge-id tx-sender))
    (try! (as-contract (stx-transfer? (get stx-reward tier-data) tx-sender tx-sender)))
    (map-set claimed-rewards {user: tx-sender, tier: tier} {claimed-at: stacks-block-height, badge-id: badge-id})
    (var-set next-badge-id (+ badge-id u1))
    (ok badge-id)
  )
)

(define-read-only (get-user-streak (user principal))
  (map-get? user-streaks user)
)

(define-read-only (get-tier-info (tier uint))
  (map-get? streak-tiers tier)
)

(define-read-only (has-claimed-tier (user principal) (tier uint))
  (is-some (map-get? claimed-rewards {user: user, tier: tier}))
)

(define-non-fungible-token chapter-bundle uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-bundle-not-found (err u301))
(define-constant err-missing-chapters (err u302))
(define-constant err-bundle-already-claimed (err u303))
(define-constant err-invalid-bundle (err u304))

(define-data-var next-bundle-id uint u1)

(define-map bundle-metadata
  uint
  {
    name: (string-ascii 64),
    required-chapters: (list 20 uint),
    reward-uri: (string-ascii 128),
    upgrade-discount: uint,
    total-claimed: uint
  }
)

(define-map user-bundles
  {user: principal, bundle-id: uint}
  {claimed-at: uint, active: bool}
)

(define-public (create-bundle
  (name (string-ascii 64))
  (required-chapters (list 20 uint))
  (reward-uri (string-ascii 128))
  (upgrade-discount uint))
  (let ((bundle-id (var-get next-bundle-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> (len required-chapters) u0) err-invalid-bundle)
    (asserts! (<= upgrade-discount u100) err-invalid-bundle)
    (map-set bundle-metadata bundle-id {
      name: name,
      required-chapters: required-chapters,
      reward-uri: reward-uri,
      upgrade-discount: upgrade-discount,
      total-claimed: u0
    })
    (var-set next-bundle-id (+ bundle-id u1))
    (ok bundle-id)
  )
)

(define-public (claim-bundle (bundle-id uint))
  (let (
    (bundle (unwrap! (map-get? bundle-metadata bundle-id) err-bundle-not-found))
    (already-claimed (map-get? user-bundles {user: tx-sender, bundle-id: bundle-id}))
  )
    (asserts! (is-none already-claimed) err-bundle-already-claimed)
    (asserts! (check-chapters-owned (get required-chapters bundle)) err-missing-chapters)
    (try! (nft-mint? chapter-bundle bundle-id tx-sender))
    (map-set bundle-metadata bundle-id (merge bundle {
      total-claimed: (+ (get total-claimed bundle) u1)
    }))
    (map-set user-bundles {user: tx-sender, bundle-id: bundle-id} {
      claimed-at: stacks-block-height,
      active: true
    })
    (ok bundle-id)
  )
)

(define-read-only (get-bundle-info (bundle-id uint))
  (map-get? bundle-metadata bundle-id)
)

(define-read-only (has-claimed-bundle (user principal) (bundle-id uint))
  (is-some (map-get? user-bundles {user: user, bundle-id: bundle-id}))
)

(define-read-only (get-upgrade-discount (user principal) (bundle-id uint))
  (match (map-get? user-bundles {user: user, bundle-id: bundle-id})
    user-bundle (match (map-get? bundle-metadata bundle-id)
      bundle (some (get upgrade-discount bundle))
      none
    )
    none
  )
)

(define-private (check-chapters-owned (chapters (list 20 uint)))
  (is-eq (len chapters) (len (filter chapter-is-owned chapters)))
)

(define-private (chapter-is-owned (chapter-id uint))
  (is-some (contract-call? .NFT-Based-Comic-Book-Series get-chapter-owner chapter-id))
)
(define-non-fungible-token comic-chapter uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-chapter-not-found (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-chapter-already-minted (err u104))
(define-constant err-chapter-locked (err u105))
(define-constant err-invalid-upgrade (err u106))

(define-data-var next-chapter-id uint u1)
(define-data-var base-price uint u1000000)

(define-map chapter-data
  uint
  {
    title: (string-ascii 64),
    description: (string-ascii 256),
    image-uri: (string-ascii 128),
    price: uint,
    upgrade-level: uint,
    unlock-height: uint,
    max-supply: uint,
    current-supply: uint
  }
)

(define-map chapter-ownership
  {chapter-id: uint, owner: principal}
  {owned-at: uint, last-read: uint}
)

(define-map user-collections
  principal
  {chapters-owned: (list 100 uint), total-chapters: uint}
)

(define-public (create-chapter 
  (title (string-ascii 64))
  (description (string-ascii 256))
  (image-uri (string-ascii 128))
  (price uint)
  (unlock-delay uint)
  (max-supply uint))
  (let ((chapter-id (var-get next-chapter-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set chapter-data chapter-id {
      title: title,
      description: description,
      image-uri: image-uri,
      price: price,
      upgrade-level: u0,
      unlock-height: (+ stacks-block-height unlock-delay),
      max-supply: max-supply,
      current-supply: u0
    })
    (var-set next-chapter-id (+ chapter-id u1))
    (ok chapter-id)
  )
)

(define-public (mint-chapter (chapter-id uint))
  (let (
    (chapter (unwrap! (map-get? chapter-data chapter-id) err-chapter-not-found))
    (current-height stacks-block-height)
  )
    (asserts! (>= current-height (get unlock-height chapter)) err-chapter-locked)
    (asserts! (< (get current-supply chapter) (get max-supply chapter)) err-chapter-already-minted)
    (try! (stx-transfer? (get price chapter) tx-sender contract-owner))
    (try! (nft-mint? comic-chapter chapter-id tx-sender))
    
    (map-set chapter-data chapter-id (merge chapter {
      current-supply: (+ (get current-supply chapter) u1)
    }))
    
    (map-set chapter-ownership 
      {chapter-id: chapter-id, owner: tx-sender}
      {owned-at: current-height, last-read: u0}
    )
    
    (let ((user-data (default-to {chapters-owned: (list), total-chapters: u0} 
                        (map-get? user-collections tx-sender))))
      (map-set user-collections tx-sender {
        chapters-owned: (unwrap! (as-max-len? (append (get chapters-owned user-data) chapter-id) u100) err-chapter-not-found),
        total-chapters: (+ (get total-chapters user-data) u1)
      })
    )
    (ok chapter-id)
  )
)

(define-public (transfer-chapter (chapter-id uint) (recipient principal))
  (let ((current-owner (unwrap! (nft-get-owner? comic-chapter chapter-id) err-chapter-not-found)))
    (asserts! (is-eq tx-sender current-owner) err-not-token-owner)
    (try! (nft-transfer? comic-chapter chapter-id tx-sender recipient))
    
    (map-delete chapter-ownership {chapter-id: chapter-id, owner: tx-sender})
    (map-set chapter-ownership 
      {chapter-id: chapter-id, owner: recipient}
      {owned-at: stacks-block-height, last-read: u0}
    )
    
    (let (
      (sender-data (unwrap! (map-get? user-collections tx-sender) err-not-token-owner))
      (recipient-data (default-to {chapters-owned: (list), total-chapters: u0} 
                        (map-get? user-collections recipient)))
    )
      (map-set user-collections tx-sender {
        chapters-owned: (filter chapter-not-equal (get chapters-owned sender-data)),
        total-chapters: (- (get total-chapters sender-data) u1)
      })
      (map-set user-collections recipient {
        chapters-owned: (unwrap! (as-max-len? (append (get chapters-owned recipient-data) chapter-id) u100) err-chapter-not-found),
        total-chapters: (+ (get total-chapters recipient-data) u1)
      })
    )
    (ok true)
  )
)

(define-public (upgrade-chapter (chapter-id uint))
  (let (
    (chapter (unwrap! (map-get? chapter-data chapter-id) err-chapter-not-found))
    (current-owner (unwrap! (nft-get-owner? comic-chapter chapter-id) err-chapter-not-found))
    (upgrade-cost (* (get price chapter) (+ (get upgrade-level chapter) u1)))
  )
    (asserts! (is-eq tx-sender current-owner) err-not-token-owner)
    (asserts! (< (get upgrade-level chapter) u10) err-invalid-upgrade)
    (try! (stx-transfer? upgrade-cost tx-sender contract-owner))
    
    (map-set chapter-data chapter-id (merge chapter {
      upgrade-level: (+ (get upgrade-level chapter) u1),
      price: (+ (get price chapter) (/ upgrade-cost u2))
    }))
    (ok (get upgrade-level chapter))
  )
)

(define-public (read-chapter (chapter-id uint))
  (let ((current-owner (unwrap! (nft-get-owner? comic-chapter chapter-id) err-chapter-not-found)))
    (asserts! (is-eq tx-sender current-owner) err-not-token-owner)
    (map-set chapter-ownership 
      {chapter-id: chapter-id, owner: tx-sender}
      {owned-at: (default-to stacks-block-height 
                    (get owned-at (map-get? chapter-ownership {chapter-id: chapter-id, owner: tx-sender}))),
       last-read: stacks-block-height}
    )
    (ok true)
  )
)

(define-read-only (get-chapter-info (chapter-id uint))
  (map-get? chapter-data chapter-id)
)

(define-read-only (get-chapter-owner (chapter-id uint))
  (nft-get-owner? comic-chapter chapter-id)
)

(define-read-only (get-user-chapters (user principal))
  (map-get? user-collections user)
)

(define-read-only (is-chapter-unlocked (chapter-id uint))
  (match (map-get? chapter-data chapter-id)
    chapter (>= stacks-block-height (get unlock-height chapter))
    false
  )
)

(define-read-only (get-ownership-info (chapter-id uint) (owner principal))
  (map-get? chapter-ownership {chapter-id: chapter-id, owner: owner})
)

(define-read-only (get-next-chapter-id)
  (var-get next-chapter-id)
)

(define-read-only (get-base-price)
  (var-get base-price)
)

(define-private (chapter-not-equal (chapter-id uint))
  (not (is-eq chapter-id chapter-id))
)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-contributor (err u200))
(define-constant err-invalid-percentage (err u201))
(define-constant err-contributors-full (err u202))

(define-map chapter-contributors
  uint
  {
    contributors: (list 5 principal),
    percentages: (list 5 uint)
  }
)

(define-private (sum-percentages (percentages (list 5 uint)))
  (+ (default-to u0 (element-at percentages u0))
     (default-to u0 (element-at percentages u1))
     (default-to u0 (element-at percentages u2))
     (default-to u0 (element-at percentages u3))
     (default-to u0 (element-at percentages u4)))
)

(define-public (set-chapter-contributors 
  (chapter-id uint)
  (contributors (list 5 principal))
  (percentages (list 5 uint)))
  (let (
    (total-percent (sum-percentages percentages))
    (contributor-count (len contributors))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq contributor-count (len percentages)) err-invalid-contributor)
    (asserts! (is-eq total-percent u100) err-invalid-percentage)
    (asserts! (<= contributor-count u5) err-contributors-full)
    
    (map-set chapter-contributors chapter-id {
      contributors: contributors,
      percentages: percentages
    })
    (ok true)
  )
)

(define-public (distribute-chapter-payment (chapter-id uint) (total-amount uint))
  (match (map-get? chapter-contributors chapter-id)
    contributors-data (distribute-payments total-amount (get contributors contributors-data) (get percentages contributors-data))
    (stx-transfer? total-amount tx-sender contract-owner)
  )
)

(define-private (distribute-payments (amount uint) (contributors (list 5 principal)) (percentages (list 5 uint)))
  (let (
    (payment-1 (get-payment amount (element-at percentages u0)))
    (payment-2 (get-payment amount (element-at percentages u1)))
    (payment-3 (get-payment amount (element-at percentages u2)))
    (payment-4 (get-payment amount (element-at percentages u3)))
    (payment-5 (get-payment amount (element-at percentages u4)))
  )
    (and 
      (try! (pay-contributor (element-at contributors u0) payment-1))
      (try! (pay-contributor (element-at contributors u1) payment-2))
      (try! (pay-contributor (element-at contributors u2) payment-3))
      (try! (pay-contributor (element-at contributors u3) payment-4))
      (try! (pay-contributor (element-at contributors u4) payment-5))
    )
    (ok true)
  )
)

(define-private (get-payment (total uint) (percentage (optional uint)))
  (match percentage
    pct (/ (* total pct) u100)
    u0
  )
)

(define-private (pay-contributor (contributor (optional principal)) (amount uint))
  (match contributor
    addr (if (> amount u0)
           (stx-transfer? amount tx-sender addr)
           (ok true))
    (ok true)
  )
)

(define-read-only (get-chapter-contributors (chapter-id uint))
  (map-get? chapter-contributors chapter-id)
)

;; title: Gigdao
;; version: 1.0.0
;; summary: Freelancer DAO with reputation system and payment escrow
;; description: A decentralized platform for freelancers with built-in reputation tracking and secure payment escrow

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_GIG (err u101))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_GIG_NOT_ACTIVE (err u103))
(define-constant ERR_ALREADY_COMPLETED (err u104))
(define-constant ERR_NOT_FREELANCER (err u105))
(define-constant ERR_NOT_CLIENT (err u106))
(define-constant ERR_INVALID_RATING (err u107))
(define-constant ERR_ALREADY_RATED (err u108))
(define-constant ERR_DISPUTE_PERIOD_ACTIVE (err u109))

(define-data-var next-gig-id uint u1)
(define-data-var platform-fee-rate uint u250)
(define-data-var dispute-period uint u144)

(define-map gigs
  { gig-id: uint }
  {
    client: principal,
    freelancer: (optional principal),
    title: (string-ascii 100),
    description: (string-ascii 500),
    payment: uint,
    status: (string-ascii 20),
    created-at: uint,
    completed-at: (optional uint),
    disputed: bool
  }
)

(define-map freelancer-profiles
  { freelancer: principal }
  {
    total-gigs: uint,
    completed-gigs: uint,
    total-earnings: uint,
    average-rating: uint,
    rating-count: uint,
    reputation-score: uint
  }
)

(define-map client-profiles
  { client: principal }
  {
    total-gigs-posted: uint,
    total-spent: uint,
    average-rating: uint,
    rating-count: uint
  }
)

(define-map gig-applications
  { gig-id: uint, freelancer: principal }
  {
    proposal: (string-ascii 300),
    applied-at: uint
  }
)

(define-map gig-ratings
  { gig-id: uint, rater: principal }
  {
    rating: uint,
    review: (string-ascii 200),
    rated-at: uint
  }
)

(define-map escrow-balances
  { gig-id: uint }
  { amount: uint }
)

(define-public (create-gig (title (string-ascii 100)) (description (string-ascii 500)) (payment uint))
  (let
    (
      (gig-id (var-get next-gig-id))
      (current-block stacks-block-height)
    )
    (try! (stx-transfer? payment tx-sender (as-contract tx-sender)))
    (map-set gigs
      { gig-id: gig-id }
      {
        client: tx-sender,
        freelancer: none,
        title: title,
        description: description,
        payment: payment,
        status: "open",
        created-at: current-block,
        completed-at: none,
        disputed: false
      }
    )
    (map-set escrow-balances { gig-id: gig-id } { amount: payment })
    (map-set client-profiles
      { client: tx-sender }
      (merge
        (default-to
          { total-gigs-posted: u0, total-spent: u0, average-rating: u0, rating-count: u0 }
          (map-get? client-profiles { client: tx-sender })
        )
        { total-gigs-posted: (+ (get total-gigs-posted (default-to { total-gigs-posted: u0, total-spent: u0, average-rating: u0, rating-count: u0 } (map-get? client-profiles { client: tx-sender }))) u1) }
      )
    )
    (var-set next-gig-id (+ gig-id u1))
    (ok gig-id)
  )
)

(define-public (apply-to-gig (gig-id uint) (proposal (string-ascii 300)))
  (let
    (
      (gig (unwrap! (map-get? gigs { gig-id: gig-id }) ERR_INVALID_GIG))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq (get status gig) "open") ERR_GIG_NOT_ACTIVE)
    (map-set gig-applications
      { gig-id: gig-id, freelancer: tx-sender }
      {
        proposal: proposal,
        applied-at: current-block
      }
    )
    (ok true)
  )
)

(define-public (assign-freelancer (gig-id uint) (freelancer principal))
  (let
    (
      (gig (unwrap! (map-get? gigs { gig-id: gig-id }) ERR_INVALID_GIG))
    )
    (asserts! (is-eq (get client gig) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status gig) "open") ERR_GIG_NOT_ACTIVE)
    (map-set gigs
      { gig-id: gig-id }
      (merge gig {
        freelancer: (some freelancer),
        status: "assigned"
      })
    )
    (map-set freelancer-profiles
      { freelancer: freelancer }
      (merge
        (default-to
          { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
          (map-get? freelancer-profiles { freelancer: freelancer })
        )
        { total-gigs: (+ (get total-gigs (default-to { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 } (map-get? freelancer-profiles { freelancer: freelancer }))) u1) }
      )
    )
    (ok true)
  )
)

(define-public (complete-gig (gig-id uint))
  (let
    (
      (gig (unwrap! (map-get? gigs { gig-id: gig-id }) ERR_INVALID_GIG))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq (some tx-sender) (get freelancer gig)) ERR_NOT_FREELANCER)
    (asserts! (is-eq (get status gig) "assigned") ERR_GIG_NOT_ACTIVE)
    (map-set gigs
      { gig-id: gig-id }
      (merge gig {
        status: "completed",
        completed-at: (some current-block)
      })
    )
    (ok true)
  )
)

(define-public (release-payment (gig-id uint))
  (let
    (
      (gig (unwrap! (map-get? gigs { gig-id: gig-id }) ERR_INVALID_GIG))
      (escrow (unwrap! (map-get? escrow-balances { gig-id: gig-id }) ERR_INVALID_GIG))
      (freelancer (unwrap! (get freelancer gig) ERR_NOT_FREELANCER))
      (platform-fee (/ (* (get payment gig) (var-get platform-fee-rate)) u10000))
      (freelancer-payment (- (get payment gig) platform-fee))
      (current-block stacks-block-height)
      (completion-block (unwrap! (get completed-at gig) ERR_GIG_NOT_ACTIVE))
    )
    (asserts! (is-eq (get client gig) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status gig) "completed") ERR_GIG_NOT_ACTIVE)
    (asserts! (> current-block (+ completion-block (var-get dispute-period))) ERR_DISPUTE_PERIOD_ACTIVE)
    (try! (as-contract (stx-transfer? freelancer-payment tx-sender freelancer)))
    (try! (as-contract (stx-transfer? platform-fee tx-sender CONTRACT_OWNER)))
    (map-set gigs
      { gig-id: gig-id }
      (merge gig { status: "paid" })
    )
    (map-delete escrow-balances { gig-id: gig-id })
    (let
      (
        (freelancer-profile (default-to
          { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
          (map-get? freelancer-profiles { freelancer: freelancer })
        ))
      )
      (map-set freelancer-profiles
        { freelancer: freelancer }
        (merge freelancer-profile {
          completed-gigs: (+ (get completed-gigs freelancer-profile) u1),
          total-earnings: (+ (get total-earnings freelancer-profile) freelancer-payment),
          reputation-score: (+ (get reputation-score freelancer-profile) u10)
        })
      )
    )
    (ok true)
  )
)

(define-public (rate-user (gig-id uint) (rating uint) (review (string-ascii 200)))
  (let
    (
      (gig (unwrap! (map-get? gigs { gig-id: gig-id }) ERR_INVALID_GIG))
      (current-block stacks-block-height)
    )
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    (asserts! (is-eq (get status gig) "paid") ERR_GIG_NOT_ACTIVE)
    (asserts! (or (is-eq tx-sender (get client gig)) (is-eq (some tx-sender) (get freelancer gig))) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? gig-ratings { gig-id: gig-id, rater: tx-sender })) ERR_ALREADY_RATED)
    (map-set gig-ratings
      { gig-id: gig-id, rater: tx-sender }
      {
        rating: rating,
        review: review,
        rated-at: current-block
      }
    )
    (if (is-eq tx-sender (get client gig))
      (let
        (
          (freelancer (unwrap! (get freelancer gig) ERR_NOT_FREELANCER))
          (profile (default-to
            { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
            (map-get? freelancer-profiles { freelancer: freelancer })
          ))
          (new-count (+ (get rating-count profile) u1))
          (new-avg (/ (+ (* (get average-rating profile) (get rating-count profile)) rating) new-count))
        )
        (map-set freelancer-profiles
          { freelancer: freelancer }
          (merge profile {
            average-rating: new-avg,
            rating-count: new-count,
            reputation-score: (+ (get reputation-score profile) (* rating u2))
          })
        )
        (ok true)
      )
      (let
        (
          (client (get client gig))
          (profile (default-to
            { total-gigs-posted: u0, total-spent: u0, average-rating: u0, rating-count: u0 }
            (map-get? client-profiles { client: client })
          ))
          (new-count (+ (get rating-count profile) u1))
          (new-avg (/ (+ (* (get average-rating profile) (get rating-count profile)) rating) new-count))
        )
        (map-set client-profiles
          { client: client }
          (merge profile {
            average-rating: new-avg,
            rating-count: new-count,
            total-spent: (+ (get total-spent profile) (get payment gig))
          })
        )
        (ok true)
      )
    )
  )
)

(define-read-only (get-gig (gig-id uint))
  (map-get? gigs { gig-id: gig-id })
)

(define-read-only (get-freelancer-profile (freelancer principal))
  (map-get? freelancer-profiles { freelancer: freelancer })
)

(define-read-only (get-client-profile (client principal))
  (map-get? client-profiles { client: client })
)

(define-read-only (get-gig-application (gig-id uint) (freelancer principal))
  (map-get? gig-applications { gig-id: gig-id, freelancer: freelancer })
)

(define-read-only (get-gig-rating (gig-id uint) (rater principal))
  (map-get? gig-ratings { gig-id: gig-id, rater: rater })
)

(define-read-only (get-next-gig-id)
  (var-get next-gig-id)
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)
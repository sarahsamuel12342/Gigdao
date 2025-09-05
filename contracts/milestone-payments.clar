;; Milestone-Based Payment System
;; Enables clients to create gigs with multiple payment milestones for better project management

;; Error constants
(define-constant ERR_NOT_AUTHORIZED (err u300))
(define-constant ERR_MILESTONE_GIG_NOT_FOUND (err u301))
(define-constant ERR_INVALID_MILESTONE (err u302))
(define-constant ERR_MILESTONE_ALREADY_COMPLETED (err u303))
(define-constant ERR_MILESTONE_NOT_COMPLETED (err u304))
(define-constant ERR_INSUFFICIENT_FUNDS (err u305))
(define-constant ERR_INVALID_MILESTONE_DATA (err u306))
(define-constant ERR_GIG_ALREADY_HAS_MILESTONES (err u307))
(define-constant ERR_TOO_MANY_MILESTONES (err u308))
(define-constant ERR_PAYMENT_MISMATCH (err u309))

;; Data variables
(define-data-var next-milestone-gig-id uint u1)
(define-data-var max-milestones-per-gig uint u10)
(define-data-var total-milestone-gigs uint u0)
(define-data-var total-milestones-completed uint u0)

;; Milestone gigs - gigs structured with milestones
(define-map milestone-gigs
  { gig-id: uint }
  {
    client: principal,
    freelancer: (optional principal),
    title: (string-ascii 100),
    description: (string-ascii 500),
    total-payment: uint,
    milestone-count: uint,
    completed-milestones: uint,
    status: (string-ascii 20),
    created-at: uint,
    assigned-at: (optional uint),
    completed-at: (optional uint)
  }
)

;; Individual milestones within gigs
(define-map gig-milestones
  { gig-id: uint, milestone-index: uint }
  {
    description: (string-ascii 300),
    payment-amount: uint,
    due-date: (optional uint),
    completed: bool,
    completed-at: (optional uint),
    approved-by-client: bool,
    approval-deadline: (optional uint)
  }
)

;; Milestone payments held in escrow
(define-map milestone-escrow
  { gig-id: uint }
  { total-escrowed: uint, total-paid: uint }
)

;; Freelancer applications for milestone gigs
(define-map milestone-gig-applications
  { gig-id: uint, freelancer: principal }
  {
    proposal: (string-ascii 400),
    estimated-timeline: uint,
    milestone-approach: (string-ascii 300),
    applied-at: uint
  }
)

;; Milestone completion history
(define-map milestone-completions
  { gig-id: uint, milestone-index: uint }
  {
    completed-by: principal,
    submitted-at: uint,
    client-approved-at: (optional uint),
    payment-released-at: (optional uint),
    completion-notes: (string-ascii 200)
  }
)

;; Create a new milestone-based gig
(define-public (create-milestone-gig
  (title (string-ascii 100))
  (description (string-ascii 500))
  (milestone-descriptions (list 10 (string-ascii 300)))
  (milestone-payments (list 10 uint))
  (milestone-due-dates (list 10 (optional uint)))
)
  (let (
    (gig-id (var-get next-milestone-gig-id))
    (current-block stacks-block-height)
    (milestone-count (len milestone-descriptions))
    (total-payment (fold + milestone-payments u0))
  )
    ;; Validation
    (asserts! (and (> milestone-count u0) (<= milestone-count (var-get max-milestones-per-gig))) ERR_TOO_MANY_MILESTONES)
    (asserts! (is-eq milestone-count (len milestone-payments)) ERR_INVALID_MILESTONE_DATA)
    (asserts! (is-eq milestone-count (len milestone-due-dates)) ERR_INVALID_MILESTONE_DATA)
    (asserts! (> total-payment u0) ERR_INVALID_MILESTONE_DATA)
    
    ;; Transfer total payment to escrow
    (try! (stx-transfer? total-payment tx-sender (as-contract tx-sender)))
    
    ;; Create the milestone gig
    (map-set milestone-gigs
      { gig-id: gig-id }
      {
        client: tx-sender,
        freelancer: none,
        title: title,
        description: description,
        total-payment: total-payment,
        milestone-count: milestone-count,
        completed-milestones: u0,
        status: "open",
        created-at: current-block,
        assigned-at: none,
        completed-at: none
      }
    )
    
    ;; Set up escrow tracking
    (map-set milestone-escrow
      { gig-id: gig-id }
      { total-escrowed: total-payment, total-paid: u0 }
    )
    
    ;; Update counters
    (var-set next-milestone-gig-id (+ gig-id u1))
    (var-set total-milestone-gigs (+ (var-get total-milestone-gigs) u1))
    
    (ok gig-id)
  )
)

;; Add individual milestone to a gig
(define-public (add-milestone-to-gig
  (gig-id uint)
  (milestone-index uint)
  (description (string-ascii 300))
  (payment-amount uint)
  (due-date (optional uint))
)
  (let (
    (gig (unwrap! (map-get? milestone-gigs { gig-id: gig-id }) ERR_MILESTONE_GIG_NOT_FOUND))
  )
    (asserts! (is-eq (get client gig) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status gig) "open") ERR_NOT_AUTHORIZED)
    (asserts! (< milestone-index (get milestone-count gig)) ERR_INVALID_MILESTONE)
    
    (map-set gig-milestones
      { gig-id: gig-id, milestone-index: milestone-index }
      {
        description: description,
        payment-amount: payment-amount,
        due-date: due-date,
        completed: false,
        completed-at: none,
        approved-by-client: false,
        approval-deadline: none
      }
    )
    
    (ok true)
  )
)

;; Apply to a milestone gig
(define-public (apply-to-milestone-gig
  (gig-id uint)
  (proposal (string-ascii 400))
  (estimated-timeline uint)
  (milestone-approach (string-ascii 300))
)
  (let (
    (gig (unwrap! (map-get? milestone-gigs { gig-id: gig-id }) ERR_MILESTONE_GIG_NOT_FOUND))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq (get status gig) "open") ERR_NOT_AUTHORIZED)
    
    (map-set milestone-gig-applications
      { gig-id: gig-id, freelancer: tx-sender }
      {
        proposal: proposal,
        estimated-timeline: estimated-timeline,
        milestone-approach: milestone-approach,
        applied-at: current-block
      }
    )
    
    (ok true)
  )
)

;; Assign freelancer to milestone gig
(define-public (assign-freelancer-to-milestone-gig (gig-id uint) (freelancer principal))
  (let (
    (gig (unwrap! (map-get? milestone-gigs { gig-id: gig-id }) ERR_MILESTONE_GIG_NOT_FOUND))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq (get client gig) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status gig) "open") ERR_NOT_AUTHORIZED)
    
    (map-set milestone-gigs
      { gig-id: gig-id }
      (merge gig {
        freelancer: (some freelancer),
        status: "assigned",
        assigned-at: (some current-block)
      })
    )
    
    (ok true)
  )
)

;; Complete a milestone
(define-public (complete-milestone
  (gig-id uint)
  (milestone-index uint)
  (completion-notes (string-ascii 200))
)
  (let (
    (gig (unwrap! (map-get? milestone-gigs { gig-id: gig-id }) ERR_MILESTONE_GIG_NOT_FOUND))
    (milestone (unwrap! (map-get? gig-milestones { gig-id: gig-id, milestone-index: milestone-index }) ERR_INVALID_MILESTONE))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq (some tx-sender) (get freelancer gig)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status gig) "assigned") ERR_NOT_AUTHORIZED)
    (asserts! (not (get completed milestone)) ERR_MILESTONE_ALREADY_COMPLETED)
    
    ;; Mark milestone as completed
    (map-set gig-milestones
      { gig-id: gig-id, milestone-index: milestone-index }
      (merge milestone {
        completed: true,
        completed-at: (some current-block),
        approval-deadline: (some (+ current-block u144)) ;; 24 hour approval window
      })
    )
    
    ;; Record completion details
    (map-set milestone-completions
      { gig-id: gig-id, milestone-index: milestone-index }
      {
        completed-by: tx-sender,
        submitted-at: current-block,
        client-approved-at: none,
        payment-released-at: none,
        completion-notes: completion-notes
      }
    )
    
    (ok true)
  )
)

;; Approve milestone completion and release payment
(define-public (approve-milestone-completion (gig-id uint) (milestone-index uint))
  (let (
    (gig (unwrap! (map-get? milestone-gigs { gig-id: gig-id }) ERR_MILESTONE_GIG_NOT_FOUND))
    (milestone (unwrap! (map-get? gig-milestones { gig-id: gig-id, milestone-index: milestone-index }) ERR_INVALID_MILESTONE))
    (completion (unwrap! (map-get? milestone-completions { gig-id: gig-id, milestone-index: milestone-index }) ERR_MILESTONE_NOT_COMPLETED))
    (escrow (unwrap! (map-get? milestone-escrow { gig-id: gig-id }) ERR_MILESTONE_GIG_NOT_FOUND))
    (freelancer (unwrap! (get freelancer gig) ERR_NOT_AUTHORIZED))
    (current-block stacks-block-height)
    (payment-amount (get payment-amount milestone))
    (platform-fee (/ (* payment-amount u250) u10000)) ;; 2.5% platform fee
    (freelancer-payment (- payment-amount platform-fee))
  )
    (asserts! (is-eq (get client gig) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (get completed milestone) ERR_MILESTONE_NOT_COMPLETED)
    (asserts! (not (get approved-by-client milestone)) ERR_MILESTONE_ALREADY_COMPLETED)
    
    ;; Transfer payment to freelancer and platform fee
    (try! (as-contract (stx-transfer? freelancer-payment tx-sender freelancer)))
    ;; Platform fee handling - for now, keep it in contract (can be upgraded later)
    ;; (try! (as-contract (stx-transfer? platform-fee tx-sender CONTRACT_OWNER)))
    
    ;; Update milestone as approved
    (map-set gig-milestones
      { gig-id: gig-id, milestone-index: milestone-index }
      (merge milestone { approved-by-client: true })
    )
    
    ;; Update completion record
    (map-set milestone-completions
      { gig-id: gig-id, milestone-index: milestone-index }
      (merge completion {
        client-approved-at: (some current-block),
        payment-released-at: (some current-block)
      })
    )
    
    ;; Update escrow and gig progress
    (map-set milestone-escrow
      { gig-id: gig-id }
      (merge escrow { total-paid: (+ (get total-paid escrow) payment-amount) })
    )
    
    (let (
      (new-completed-count (+ (get completed-milestones gig) u1))
      (all-milestones-done (is-eq new-completed-count (get milestone-count gig)))
    )
      (map-set milestone-gigs
        { gig-id: gig-id }
        (merge gig {
          completed-milestones: new-completed-count,
          status: (if all-milestones-done "completed" "assigned"),
          completed-at: (if all-milestones-done (some current-block) none)
        })
      )
      
      ;; Update global counter
      (var-set total-milestones-completed (+ (var-get total-milestones-completed) u1))
      
      (ok { milestone-approved: true, gig-completed: all-milestones-done, payment-released: freelancer-payment })
    )
  )
)

;; Auto-approve milestone if client doesn't respond within deadline
(define-public (auto-approve-milestone (gig-id uint) (milestone-index uint))
  (let (
    (gig (unwrap! (map-get? milestone-gigs { gig-id: gig-id }) ERR_MILESTONE_GIG_NOT_FOUND))
    (milestone (unwrap! (map-get? gig-milestones { gig-id: gig-id, milestone-index: milestone-index }) ERR_INVALID_MILESTONE))
    (current-block stacks-block-height)
    (approval-deadline (unwrap! (get approval-deadline milestone) ERR_MILESTONE_NOT_COMPLETED))
  )
    (asserts! (get completed milestone) ERR_MILESTONE_NOT_COMPLETED)
    (asserts! (not (get approved-by-client milestone)) ERR_MILESTONE_ALREADY_COMPLETED)
    (asserts! (>= current-block approval-deadline) ERR_NOT_AUTHORIZED)
    
    ;; Auto-approve and trigger payment release
    (try! (as-contract (approve-milestone-completion gig-id milestone-index)))
    
    (ok true)
  )
)

;; Read-only functions

(define-read-only (get-milestone-gig (gig-id uint))
  (map-get? milestone-gigs { gig-id: gig-id })
)

(define-read-only (get-gig-milestone (gig-id uint) (milestone-index uint))
  (map-get? gig-milestones { gig-id: gig-id, milestone-index: milestone-index })
)

(define-read-only (get-milestone-escrow (gig-id uint))
  (map-get? milestone-escrow { gig-id: gig-id })
)

(define-read-only (get-milestone-gig-application (gig-id uint) (freelancer principal))
  (map-get? milestone-gig-applications { gig-id: gig-id, freelancer: freelancer })
)

(define-read-only (get-milestone-completion (gig-id uint) (milestone-index uint))
  (map-get? milestone-completions { gig-id: gig-id, milestone-index: milestone-index })
)

(define-read-only (get-gig-progress (gig-id uint))
  (match (map-get? milestone-gigs { gig-id: gig-id })
    gig (some {
          completed-milestones: (get completed-milestones gig),
          total-milestones: (get milestone-count gig),
          progress-percentage: (/ (* (get completed-milestones gig) u100) (get milestone-count gig)),
          status: (get status gig)
        })
    none
  )
)

(define-read-only (get-milestone-settings)
  {
    max-milestones-per-gig: (var-get max-milestones-per-gig),
    next-milestone-gig-id: (var-get next-milestone-gig-id),
    total-milestone-gigs: (var-get total-milestone-gigs),
    total-milestones-completed: (var-get total-milestones-completed)
  }
)

(define-read-only (is-milestone-overdue (gig-id uint) (milestone-index uint))
  (match (map-get? gig-milestones { gig-id: gig-id, milestone-index: milestone-index })
    milestone (match (get due-date milestone)
                due-date (and (not (get completed milestone)) (> stacks-block-height due-date))
                false)
    false
  )
)

;; Simple check for pending approval count
(define-read-only (count-pending-approvals (gig-id uint))
  (match (map-get? milestone-gigs { gig-id: gig-id })
    gig (ok (get milestone-count gig))
    ERR_MILESTONE_GIG_NOT_FOUND
  )
)

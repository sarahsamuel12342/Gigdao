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
(define-constant ERR_INVALID_TEMPLATE (err u110))
(define-constant ERR_TEMPLATE_NOT_ACTIVE (err u111))
(define-constant ERR_INSUFFICIENT_REPUTATION (err u112))
(define-constant ERR_INVALID_CATEGORY (err u113))
(define-constant ERR_TEMPLATE_LIMIT_REACHED (err u114))
(define-constant ERR_SKILL_NOT_FOUND (err u115))
(define-constant ERR_CHALLENGE_NOT_ACTIVE (err u116))
(define-constant ERR_ALREADY_VERIFIED (err u117))
(define-constant ERR_INSUFFICIENT_REVIEWERS (err u118))
(define-constant ERR_INVALID_VERIFICATION (err u119))
(define-constant ERR_CERTIFICATION_EXPIRED (err u120))
(define-constant ERR_ALREADY_REVIEWED (err u121))

(define-data-var next-gig-id uint u1)
(define-data-var platform-fee-rate uint u250)
(define-data-var dispute-period uint u144)
(define-data-var next-template-id uint u1)
(define-data-var max-templates-per-user uint u10)
(define-data-var min-reputation-for-templates uint u50)
(define-data-var next-skill-id uint u1)
(define-data-var next-challenge-id uint u1)
(define-data-var min-reviewers-for-verification uint u3)
(define-data-var certification-validity-period uint u52560)

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

(define-map gig-templates
  { template-id: uint }
  {
    creator: principal,
    category: (string-ascii 50),
    title-template: (string-ascii 100),
    description-template: (string-ascii 500),
    suggested-payment-min: uint,
    suggested-payment-max: uint,
    required-skills: (list 5 (string-ascii 30)),
    estimated-duration: uint,
    difficulty-level: uint,
    usage-count: uint,
    success-rate: uint,
    avg-completion-time: uint,
    created-at: uint,
    is-active: bool,
    tags: (list 10 (string-ascii 20))
  }
)

(define-map template-recommendations
  { user: principal, template-id: uint }
  {
    compatibility-score: uint,
    price-recommendation: uint,
    timeline-recommendation: uint,
    success-probability: uint,
    recommended-at: uint
  }
)

(define-map user-template-usage
  { user: principal, template-id: uint }
  {
    times-used: uint,
    success-rate: uint,
    avg-rating: uint,
    last-used: uint
  }
)

(define-map category-stats
  { category: (string-ascii 50) }
  {
    total-gigs: uint,
    avg-payment: uint,
    avg-completion-time: uint,
    success-rate: uint,
    top-skills: (list 5 (string-ascii 30))
  }
)

(define-map user-preferences
  { user: principal }
  {
    preferred-categories: (list 5 (string-ascii 50)),
    preferred-payment-range-min: uint,
    preferred-payment-range-max: uint,
    preferred-skills: (list 10 (string-ascii 30)),
    notification-settings: uint,
    template-count: uint
  }
)

(define-map skill-definitions
  { skill-id: uint }
  {
    name: (string-ascii 50),
    category: (string-ascii 30),
    description: (string-ascii 200),
    verification-type: (string-ascii 20),
    creator: principal,
    difficulty-level: uint,
    min-reputation-required: uint,
    created-at: uint,
    is-active: bool,
    total-verifications: uint
  }
)

(define-map skill-certifications
  { freelancer: principal, skill-id: uint }
  {
    verification-method: (string-ascii 20),
    certified-at: uint,
    expires-at: uint,
    proficiency-level: uint,
    verification-score: uint,
    reviewer-count: uint,
    is-active: bool
  }
)

(define-map skill-challenges
  { challenge-id: uint }
  {
    skill-id: uint,
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 300),
    requirements: (string-ascii 200),
    reward-points: uint,
    difficulty: uint,
    created-at: uint,
    deadline: uint,
    is-active: bool,
    participant-count: uint
  }
)

(define-map challenge-submissions
  { challenge-id: uint, participant: principal }
  {
    submission-data: (string-ascii 500),
    submitted-at: uint,
    status: (string-ascii 20),
    score: uint,
    reviewer-count: uint,
    verified: bool
  }
)

(define-map peer-reviews
  { skill-id: uint, candidate: principal, reviewer: principal }
  {
    review-score: uint,
    review-notes: (string-ascii 300),
    reviewed-at: uint,
    verification-type: (string-ascii 20)
  }
)

(define-map freelancer-skill-portfolio
  { freelancer: principal }
  {
    verified-skills: (list 20 uint),
    total-certifications: uint,
    portfolio-score: uint,
    last-updated: uint,
    skill-points: uint
  }
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

(define-public (create-gig-template 
  (category (string-ascii 50))
  (title-template (string-ascii 100))
  (description-template (string-ascii 500))
  (suggested-payment-min uint)
  (suggested-payment-max uint)
  (required-skills (list 5 (string-ascii 30)))
  (estimated-duration uint)
  (difficulty-level uint)
  (tags (list 10 (string-ascii 20))))
  (let
    (
      (template-id (var-get next-template-id))
      (current-block stacks-block-height)
      (user-profile (default-to 
        { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
        (map-get? freelancer-profiles { freelancer: tx-sender })))
      (user-prefs (default-to
        { preferred-categories: (list), preferred-payment-range-min: u0, preferred-payment-range-max: u0, preferred-skills: (list), notification-settings: u0, template-count: u0 }
        (map-get? user-preferences { user: tx-sender })))
    )
    (asserts! (>= (get reputation-score user-profile) (var-get min-reputation-for-templates)) ERR_INSUFFICIENT_REPUTATION)
    (asserts! (< (get template-count user-prefs) (var-get max-templates-per-user)) ERR_TEMPLATE_LIMIT_REACHED)
    (asserts! (and (>= difficulty-level u1) (<= difficulty-level u5)) ERR_INVALID_CATEGORY)
    (asserts! (<= suggested-payment-min suggested-payment-max) ERR_INVALID_GIG)
    (map-set gig-templates
      { template-id: template-id }
      {
        creator: tx-sender,
        category: category,
        title-template: title-template,
        description-template: description-template,
        suggested-payment-min: suggested-payment-min,
        suggested-payment-max: suggested-payment-max,
        required-skills: required-skills,
        estimated-duration: estimated-duration,
        difficulty-level: difficulty-level,
        usage-count: u0,
        success-rate: u100,
        avg-completion-time: estimated-duration,
        created-at: current-block,
        is-active: true,
        tags: tags
      }
    )
    (map-set user-preferences
      { user: tx-sender }
      (merge user-prefs { template-count: (+ (get template-count user-prefs) u1) })
    )
    (var-set next-template-id (+ template-id u1))
    (ok template-id)
  )
)

(define-public (create-gig-from-template (template-id uint) (custom-payment uint))
  (let
    (
      (template (unwrap! (map-get? gig-templates { template-id: template-id }) ERR_INVALID_TEMPLATE))
      (gig-id (var-get next-gig-id))
      (current-block stacks-block-height)
      (final-payment (if (and (>= custom-payment (get suggested-payment-min template)) 
                             (<= custom-payment (get suggested-payment-max template)))
                        custom-payment
                        (/ (+ (get suggested-payment-min template) (get suggested-payment-max template)) u2)))
    )
    (asserts! (get is-active template) ERR_TEMPLATE_NOT_ACTIVE)
    (try! (stx-transfer? final-payment tx-sender (as-contract tx-sender)))
    (map-set gigs
      { gig-id: gig-id }
      {
        client: tx-sender,
        freelancer: none,
        title: (get title-template template),
        description: (get description-template template),
        payment: final-payment,
        status: "open",
        created-at: current-block,
        completed-at: none,
        disputed: false
      }
    )
    (map-set escrow-balances { gig-id: gig-id } { amount: final-payment })
    (map-set user-template-usage
      { user: tx-sender, template-id: template-id }
      (merge
        (default-to
          { times-used: u0, success-rate: u100, avg-rating: u0, last-used: u0 }
          (map-get? user-template-usage { user: tx-sender, template-id: template-id })
        )
        { 
          times-used: (+ (get times-used (default-to { times-used: u0, success-rate: u100, avg-rating: u0, last-used: u0 } (map-get? user-template-usage { user: tx-sender, template-id: template-id }))) u1),
          last-used: current-block
        }
      )
    )
    (map-set gig-templates
      { template-id: template-id }
      (merge template { usage-count: (+ (get usage-count template) u1) })
    )
    (let
      (
        (client-profile (default-to
          { total-gigs-posted: u0, total-spent: u0, average-rating: u0, rating-count: u0 }
          (map-get? client-profiles { client: tx-sender })
        ))
      )
      (map-set client-profiles
        { client: tx-sender }
        (merge client-profile { total-gigs-posted: (+ (get total-gigs-posted client-profile) u1) })
      )
    )
    (var-set next-gig-id (+ gig-id u1))
    (ok gig-id)
  )
)

(define-public (generate-template-recommendations (user principal) (category (string-ascii 50)))
  (let
    (
      (user-profile (default-to 
        { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
        (map-get? freelancer-profiles { freelancer: user })))
      (user-prefs (default-to
        { preferred-categories: (list), preferred-payment-range-min: u0, preferred-payment-range-max: u1000000, preferred-skills: (list), notification-settings: u0, template-count: u0 }
        (map-get? user-preferences { user: user })))
      (current-block stacks-block-height)
      (category-data (default-to
        { total-gigs: u1, avg-payment: u100000, avg-completion-time: u100, success-rate: u80, top-skills: (list) }
        (map-get? category-stats { category: category })))
    )
    (let
      (
        (base-compatibility (+ (get reputation-score user-profile) (* (get completed-gigs user-profile) u5)))
        (payment-compatibility (if (and (>= (get avg-payment category-data) (get preferred-payment-range-min user-prefs))
                                       (<= (get avg-payment category-data) (get preferred-payment-range-max user-prefs)))
                                  u25 u10))
        (experience-bonus (if (> (* (get completed-gigs user-profile) u2) u30) u30 (* (get completed-gigs user-profile) u2)))
        (total-compatibility (+ base-compatibility payment-compatibility experience-bonus))
        (payment-choice (if (< (get avg-payment category-data) (get preferred-payment-range-max user-prefs)) 
                          (get avg-payment category-data) 
                          (get preferred-payment-range-max user-prefs)))
        (recommended-payment (if (> (get preferred-payment-range-min user-prefs) payment-choice) 
                               (get preferred-payment-range-min user-prefs) 
                               payment-choice))
        (timeline-estimate (+ (get avg-completion-time category-data) 
                             (if (> (get reputation-score user-profile) u100) u0 u20)))
        (temp-success (+ (get success-rate category-data) (/ (get reputation-score user-profile) u10)))
        (success-prob (if (> temp-success u100) u100 temp-success))
      )
      (map-set template-recommendations
        { user: user, template-id: u0 }
        {
          compatibility-score: total-compatibility,
          price-recommendation: recommended-payment,
          timeline-recommendation: timeline-estimate,
          success-probability: success-prob,
          recommended-at: current-block
        }
      )
      (ok {
        compatibility: total-compatibility,
        price: recommended-payment,
        timeline: timeline-estimate,
        success-rate: success-prob
      })
    )
  )
)

(define-public (update-category-stats (category (string-ascii 50)) (payment uint) (completion-time uint) (success bool))
  (let
    (
      (current-stats (default-to
        { total-gigs: u0, avg-payment: u0, avg-completion-time: u0, success-rate: u100, top-skills: (list) }
        (map-get? category-stats { category: category })))
      (new-total (+ (get total-gigs current-stats) u1))
      (new-avg-payment (/ (+ (* (get avg-payment current-stats) (get total-gigs current-stats)) payment) new-total))
      (new-avg-time (/ (+ (* (get avg-completion-time current-stats) (get total-gigs current-stats)) completion-time) new-total))
      (success-count (if success 
                       (+ (/ (* (get success-rate current-stats) (get total-gigs current-stats)) u100) u1)
                       (/ (* (get success-rate current-stats) (get total-gigs current-stats)) u100)))
      (new-success-rate (/ (* success-count u100) new-total))
    )
    (map-set category-stats
      { category: category }
      {
        total-gigs: new-total,
        avg-payment: new-avg-payment,
        avg-completion-time: new-avg-time,
        success-rate: new-success-rate,
        top-skills: (get top-skills current-stats)
      }
    )
    (ok true)
  )
)

(define-public (set-user-preferences 
  (preferred-categories (list 5 (string-ascii 50)))
  (payment-min uint)
  (payment-max uint)
  (preferred-skills (list 10 (string-ascii 30)))
  (notifications uint))
  (let
    (
      (current-prefs (default-to
        { preferred-categories: (list), preferred-payment-range-min: u0, preferred-payment-range-max: u0, preferred-skills: (list), notification-settings: u0, template-count: u0 }
        (map-get? user-preferences { user: tx-sender })))
    )
    (asserts! (<= payment-min payment-max) ERR_INVALID_GIG)
    (map-set user-preferences
      { user: tx-sender }
      (merge current-prefs {
        preferred-categories: preferred-categories,
        preferred-payment-range-min: payment-min,
        preferred-payment-range-max: payment-max,
        preferred-skills: preferred-skills,
        notification-settings: notifications
      })
    )
    (ok true)
  )
)

(define-public (toggle-template-status (template-id uint))
  (let
    (
      (template (unwrap! (map-get? gig-templates { template-id: template-id }) ERR_INVALID_TEMPLATE))
    )
    (asserts! (is-eq (get creator template) tx-sender) ERR_NOT_AUTHORIZED)
    (map-set gig-templates
      { template-id: template-id }
      (merge template { is-active: (not (get is-active template)) })
    )
    (ok (not (get is-active template)))
  )
)

(define-read-only (get-template (template-id uint))
  (map-get? gig-templates { template-id: template-id })
)

(define-read-only (get-template-recommendation (user principal) (template-id uint))
  (map-get? template-recommendations { user: user, template-id: template-id })
)

(define-read-only (get-user-template-usage (user principal) (template-id uint))
  (map-get? user-template-usage { user: user, template-id: template-id })
)

(define-read-only (get-category-stats (category (string-ascii 50)))
  (map-get? category-stats { category: category })
)

(define-read-only (get-user-preferences (user principal))
  (map-get? user-preferences { user: user })
)

(define-read-only (get-next-template-id)
  (var-get next-template-id)
)

(define-read-only (get-template-settings)
  {
    max-templates-per-user: (var-get max-templates-per-user),
    min-reputation-for-templates: (var-get min-reputation-for-templates)
  }
)

(define-public (create-skill-definition 
  (name (string-ascii 50))
  (category (string-ascii 30))
  (description (string-ascii 200))
  (verification-type (string-ascii 20))
  (difficulty-level uint)
  (min-reputation-required uint))
  (let
    (
      (skill-id (var-get next-skill-id))
      (current-block stacks-block-height)
      (creator-profile (default-to 
        { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
        (map-get? freelancer-profiles { freelancer: tx-sender })))
    )
    (asserts! (>= (get reputation-score creator-profile) u100) ERR_INSUFFICIENT_REPUTATION)
    (asserts! (and (>= difficulty-level u1) (<= difficulty-level u5)) ERR_INVALID_CATEGORY)
    (map-set skill-definitions
      { skill-id: skill-id }
      {
        name: name,
        category: category,
        description: description,
        verification-type: verification-type,
        creator: tx-sender,
        difficulty-level: difficulty-level,
        min-reputation-required: min-reputation-required,
        created-at: current-block,
        is-active: true,
        total-verifications: u0
      }
    )
    (var-set next-skill-id (+ skill-id u1))
    (ok skill-id)
  )
)

(define-public (create-skill-challenge
  (skill-id uint)
  (title (string-ascii 100))
  (description (string-ascii 300))
  (requirements (string-ascii 200))
  (reward-points uint)
  (difficulty uint)
  (duration-blocks uint))
  (let
    (
      (challenge-id (var-get next-challenge-id))
      (current-block stacks-block-height)
      (skill (unwrap! (map-get? skill-definitions { skill-id: skill-id }) ERR_SKILL_NOT_FOUND))
      (creator-profile (default-to 
        { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
        (map-get? freelancer-profiles { freelancer: tx-sender })))
    )
    (asserts! (get is-active skill) ERR_SKILL_NOT_FOUND)
    (asserts! (>= (get reputation-score creator-profile) u50) ERR_INSUFFICIENT_REPUTATION)
    (asserts! (and (>= difficulty u1) (<= difficulty u5)) ERR_INVALID_CATEGORY)
    (map-set skill-challenges
      { challenge-id: challenge-id }
      {
        skill-id: skill-id,
        creator: tx-sender,
        title: title,
        description: description,
        requirements: requirements,
        reward-points: reward-points,
        difficulty: difficulty,
        created-at: current-block,
        deadline: (+ current-block duration-blocks),
        is-active: true,
        participant-count: u0
      }
    )
    (var-set next-challenge-id (+ challenge-id u1))
    (ok challenge-id)
  )
)

(define-public (submit-challenge-solution 
  (challenge-id uint)
  (submission-data (string-ascii 500)))
  (let
    (
      (challenge (unwrap! (map-get? skill-challenges { challenge-id: challenge-id }) ERR_INVALID_GIG))
      (current-block stacks-block-height)
    )
    (asserts! (get is-active challenge) ERR_CHALLENGE_NOT_ACTIVE)
    (asserts! (< current-block (get deadline challenge)) ERR_CHALLENGE_NOT_ACTIVE)
    (asserts! (is-none (map-get? challenge-submissions { challenge-id: challenge-id, participant: tx-sender })) ERR_ALREADY_COMPLETED)
    (map-set challenge-submissions
      { challenge-id: challenge-id, participant: tx-sender }
      {
        submission-data: submission-data,
        submitted-at: current-block,
        status: "pending",
        score: u0,
        reviewer-count: u0,
        verified: false
      }
    )
    (map-set skill-challenges
      { challenge-id: challenge-id }
      (merge challenge { participant-count: (+ (get participant-count challenge) u1) })
    )
    (ok true)
  )
)

(define-public (review-challenge-submission
  (challenge-id uint)
  (participant principal)
  (score uint)
  (review-notes (string-ascii 300)))
  (let
    (
      (challenge (unwrap! (map-get? skill-challenges { challenge-id: challenge-id }) ERR_INVALID_GIG))
      (submission (unwrap! (map-get? challenge-submissions { challenge-id: challenge-id, participant: participant }) ERR_INVALID_GIG))
      (reviewer-profile (default-to 
        { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
        (map-get? freelancer-profiles { freelancer: tx-sender })))
      (current-block stacks-block-height)
    )
    (asserts! (not (is-eq tx-sender participant)) ERR_NOT_AUTHORIZED)
    (asserts! (>= (get reputation-score reviewer-profile) u50) ERR_INSUFFICIENT_REPUTATION)
    (asserts! (and (>= score u0) (<= score u100)) ERR_INVALID_RATING)
    (asserts! (is-none (map-get? peer-reviews { skill-id: (get skill-id challenge), candidate: participant, reviewer: tx-sender })) ERR_ALREADY_REVIEWED)
    (map-set peer-reviews
      { skill-id: (get skill-id challenge), candidate: participant, reviewer: tx-sender }
      {
        review-score: score,
        review-notes: review-notes,
        reviewed-at: current-block,
        verification-type: "challenge"
      }
    )
    (let
      (
        (new-reviewer-count (+ (get reviewer-count submission) u1))
        (new-score (/ (+ (* (get score submission) (get reviewer-count submission)) score) new-reviewer-count))
      )
      (map-set challenge-submissions
        { challenge-id: challenge-id, participant: participant }
        (merge submission {
          score: new-score,
          reviewer-count: new-reviewer-count,
          verified: (>= new-reviewer-count (var-get min-reviewers-for-verification))
        })
      )
    )
    (ok true)
  )
)

(define-public (verify-skill-through-peer-review
  (skill-id uint)
  (candidate principal))
  (let
    (
      (skill (unwrap! (map-get? skill-definitions { skill-id: skill-id }) ERR_SKILL_NOT_FOUND))
      (reviewer-profile (default-to 
        { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
        (map-get? freelancer-profiles { freelancer: tx-sender })))
      (candidate-profile (default-to 
        { total-gigs: u0, completed-gigs: u0, total-earnings: u0, average-rating: u0, rating-count: u0, reputation-score: u0 }
        (map-get? freelancer-profiles { freelancer: candidate })))
      (current-block stacks-block-height)
    )
    (asserts! (not (is-eq tx-sender candidate)) ERR_NOT_AUTHORIZED)
    (asserts! (>= (get reputation-score reviewer-profile) u100) ERR_INSUFFICIENT_REPUTATION)
    (asserts! (>= (get reputation-score candidate-profile) (get min-reputation-required skill)) ERR_INSUFFICIENT_REPUTATION)
    (asserts! (get is-active skill) ERR_SKILL_NOT_FOUND)
    (asserts! (is-none (map-get? skill-certifications { freelancer: candidate, skill-id: skill-id })) ERR_ALREADY_VERIFIED)
    (asserts! (is-none (map-get? peer-reviews { skill-id: skill-id, candidate: candidate, reviewer: tx-sender })) ERR_ALREADY_REVIEWED)
    (map-set peer-reviews
      { skill-id: skill-id, candidate: candidate, reviewer: tx-sender }
      {
        review-score: u75,
        review-notes: "Peer verification",
        reviewed-at: current-block,
        verification-type: "peer-review"
      }
    )
    (ok true)
  )
)

(define-public (issue-skill-certification
  (skill-id uint)
  (freelancer principal)
  (verification-method (string-ascii 20))
  (proficiency-level uint))
  (let
    (
      (skill (unwrap! (map-get? skill-definitions { skill-id: skill-id }) ERR_SKILL_NOT_FOUND))
      (current-block stacks-block-height)
      (expiry-block (+ current-block (var-get certification-validity-period)))
      (existing-cert (map-get? skill-certifications { freelancer: freelancer, skill-id: skill-id }))
    )
    (asserts! (get is-active skill) ERR_SKILL_NOT_FOUND)
    (asserts! (and (>= proficiency-level u1) (<= proficiency-level u5)) ERR_INVALID_CATEGORY)
    (asserts! (or (is-eq tx-sender (get creator skill)) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (is-none existing-cert) ERR_ALREADY_VERIFIED)
    (map-set skill-certifications
      { freelancer: freelancer, skill-id: skill-id }
      {
        verification-method: verification-method,
        certified-at: current-block,
        expires-at: expiry-block,
        proficiency-level: proficiency-level,
        verification-score: u85,
        reviewer-count: u1,
        is-active: true
      }
    )
    (map-set skill-definitions
      { skill-id: skill-id }
      (merge skill { total-verifications: (+ (get total-verifications skill) u1) })
    )
    (let
      (
        (portfolio (default-to
          { verified-skills: (list), total-certifications: u0, portfolio-score: u0, last-updated: u0, skill-points: u0 }
          (map-get? freelancer-skill-portfolio { freelancer: freelancer })))
        (current-skills (get verified-skills portfolio))
        (updated-skills (unwrap! (as-max-len? (append current-skills skill-id) u20) ERR_TEMPLATE_LIMIT_REACHED))
      )
      (map-set freelancer-skill-portfolio
        { freelancer: freelancer }
        {
          verified-skills: updated-skills,
          total-certifications: (+ (get total-certifications portfolio) u1),
          portfolio-score: (+ (get portfolio-score portfolio) (* proficiency-level u20)),
          last-updated: current-block,
          skill-points: (+ (get skill-points portfolio) (* (get difficulty-level skill) u10))
        }
      )
    )
    (ok true)
  )
)

(define-public (renew-skill-certification (skill-id uint))
  (let
    (
      (cert (unwrap! (map-get? skill-certifications { freelancer: tx-sender, skill-id: skill-id }) ERR_SKILL_NOT_FOUND))
      (current-block stacks-block-height)
      (new-expiry (+ current-block (var-get certification-validity-period)))
    )
    (asserts! (get is-active cert) ERR_CERTIFICATION_EXPIRED)
    (asserts! (> current-block (- (get expires-at cert) u1440)) ERR_INVALID_VERIFICATION)
    (map-set skill-certifications
      { freelancer: tx-sender, skill-id: skill-id }
      (merge cert { expires-at: new-expiry })
    )
    (ok true)
  )
)

(define-read-only (get-skill-definition (skill-id uint))
  (map-get? skill-definitions { skill-id: skill-id })
)

(define-read-only (get-skill-certification (freelancer principal) (skill-id uint))
  (map-get? skill-certifications { freelancer: freelancer, skill-id: skill-id })
)

(define-read-only (get-skill-challenge (challenge-id uint))
  (map-get? skill-challenges { challenge-id: challenge-id })
)

(define-read-only (get-challenge-submission (challenge-id uint) (participant principal))
  (map-get? challenge-submissions { challenge-id: challenge-id, participant: participant })
)

(define-read-only (get-peer-review (skill-id uint) (candidate principal) (reviewer principal))
  (map-get? peer-reviews { skill-id: skill-id, candidate: candidate, reviewer: reviewer })
)

(define-read-only (get-freelancer-skill-portfolio (freelancer principal))
  (map-get? freelancer-skill-portfolio { freelancer: freelancer })
)

(define-read-only (get-skill-verification-settings)
  {
    min-reviewers-for-verification: (var-get min-reviewers-for-verification),
    certification-validity-period: (var-get certification-validity-period),
    next-skill-id: (var-get next-skill-id),
    next-challenge-id: (var-get next-challenge-id)
  }
)



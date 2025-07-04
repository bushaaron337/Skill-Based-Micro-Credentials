(define-non-fungible-token skill-credential uint)

(define-data-var next-credential-id uint u1)
(define-data-var contract-owner principal tx-sender)

(define-map credentials
  uint
  {
    recipient: principal,
    skill-name: (string-ascii 50),
    issuer: principal,
    difficulty-level: uint,
    timestamp: uint,
    metadata-uri: (string-ascii 200)
  }
)

(define-map authorized-issuers principal bool)

(define-map user-credentials
  principal
  (list 100 uint)
)

(define-map skill-categories
  (string-ascii 30)
  {
    category-id: uint,
    min-difficulty: uint,
    max-difficulty: uint,
    active: bool
  }
)

(define-map issuer-stats
  principal
  {
    total-issued: uint,
    reputation-score: uint,
    verified: bool
  }
)

(define-map skill-requirements
  (string-ascii 50)
  {
    prerequisite-skills: (list 10 (string-ascii 50)),
    min-level: uint
  }
)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CREDENTIAL-NOT-FOUND (err u101))
(define-constant ERR-INVALID-DIFFICULTY (err u102))
(define-constant ERR-SKILL-NOT-FOUND (err u103))
(define-constant ERR-PREREQUISITES-NOT-MET (err u104))
(define-constant ERR-ALREADY-AUTHORIZED (err u105))
(define-constant ERR-NOT-OWNER (err u106))
(define-constant ERR-INVALID-RECIPIENT (err u107))
(define-constant ERR-CREDENTIAL-EXISTS (err u108))

(define-public (authorize-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-OWNER)
    (asserts! (is-none (map-get? authorized-issuers issuer)) ERR-ALREADY-AUTHORIZED)
    (map-set authorized-issuers issuer true)
    (map-set issuer-stats issuer {
      total-issued: u0,
      reputation-score: u100,
      verified: true
    })
    (ok true)
  )
)

(define-public (revoke-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-OWNER)
    (map-delete authorized-issuers issuer)
    (ok true)
  )
)

(define-public (create-skill-category (category-name (string-ascii 30)) (min-diff uint) (max-diff uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-OWNER)
    (asserts! (<= min-diff max-diff) ERR-INVALID-DIFFICULTY)
    (map-set skill-categories category-name {
      category-id: (var-get next-credential-id),
      min-difficulty: min-diff,
      max-difficulty: max-diff,
      active: true
    })
    (ok true)
  )
)

(define-public (set-skill-requirements (skill-name (string-ascii 50)) (prerequisites (list 10 (string-ascii 50))) (min-level uint))
  (begin
    (asserts! (is-authorized-issuer tx-sender) ERR-NOT-AUTHORIZED)
    (map-set skill-requirements skill-name {
      prerequisite-skills: prerequisites,
      min-level: min-level
    })
    (ok true)
  )
)

(define-public (issue-credential (recipient principal) (skill-name (string-ascii 50)) (difficulty uint) (metadata-uri (string-ascii 200)))
  (let
    (
      (credential-id (var-get next-credential-id))
      (current-user-creds (default-to (list) (map-get? user-credentials recipient)))
    )
    (asserts! (is-authorized-issuer tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq recipient tx-sender)) ERR-INVALID-RECIPIENT)
    (asserts! (and (>= difficulty u1) (<= difficulty u10)) ERR-INVALID-DIFFICULTY)
    (asserts! (check-prerequisites recipient skill-name difficulty) ERR-PREREQUISITES-NOT-MET)
    
    (try! (nft-mint? skill-credential credential-id recipient))
    
    (map-set credentials credential-id {
      recipient: recipient,
      skill-name: skill-name,
      issuer: tx-sender,
      difficulty-level: difficulty,
      timestamp: stacks-block-height,
      metadata-uri: metadata-uri
    })
    
    (map-set user-credentials recipient 
      (unwrap! (as-max-len? (append current-user-creds credential-id) u100) ERR-CREDENTIAL-EXISTS))
    
    (update-issuer-stats tx-sender)
    (var-set next-credential-id (+ credential-id u1))
    (ok credential-id)
  )
)

(define-public (transfer-credential (credential-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (try! (nft-transfer? skill-credential credential-id sender recipient))
    (update-credential-owner credential-id recipient)
    (ok true)
  )
)

(define-public (burn-credential (credential-id uint))
  (let
    (
      (credential (unwrap! (map-get? credentials credential-id) ERR-CREDENTIAL-NOT-FOUND))
      (owner (unwrap! (nft-get-owner? skill-credential credential-id) ERR-CREDENTIAL-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender owner) (is-eq tx-sender (get issuer credential))) ERR-NOT-AUTHORIZED)
    (try! (nft-burn? skill-credential credential-id owner))
    (map-delete credentials credential-id)
    (ok true)
  )
)

(define-public (verify-credential (credential-id uint))
  (let
    (
      (credential (unwrap! (map-get? credentials credential-id) ERR-CREDENTIAL-NOT-FOUND))
      (issuer-verified (default-to false (get verified (map-get? issuer-stats (get issuer credential)))))
    )
    (ok {
      valid: true,
      issuer-verified: issuer-verified,
      credential: credential
    })
  )
)

(define-private (is-authorized-issuer (issuer principal))
  (default-to false (map-get? authorized-issuers issuer))
)

(define-private (check-prerequisites (user principal) (skill-name (string-ascii 50)) (difficulty uint))
  (let
    (
      (requirements (map-get? skill-requirements skill-name))
      (user-creds (default-to (list) (map-get? user-credentials user)))
    )
    (match requirements
      reqs (check-user-skills user-creds (get prerequisite-skills reqs) (get min-level reqs))
      true
    )
  )
)

(define-private (check-user-skills (user-creds (list 100 uint)) (required-skills (list 10 (string-ascii 50))) (min-level uint))
  (if (is-eq (len required-skills) u0)
    true
    (has-required-skills user-creds required-skills min-level)
  )
)

(define-private (has-required-skills (user-creds (list 100 uint)) (required-skills (list 10 (string-ascii 50))) (min-level uint))
  (let
    (
      (skill-check (map check-single-skill required-skills))
    )
    (is-eq (len (filter is-skill-met skill-check)) (len required-skills))
  )
)

(define-private (check-single-skill (skill-name (string-ascii 50)))
  skill-name
)

(define-private (is-skill-met (skill-name (string-ascii 50)))
  true
)

(define-private (update-credential-owner (credential-id uint) (new-owner principal))
  (let
    (
      (credential (unwrap-panic (map-get? credentials credential-id)))
    )
    (map-set credentials credential-id
      (merge credential { recipient: new-owner })
    )
  )
)

(define-private (update-issuer-stats (issuer principal))
  (let
    (
      (current-stats (default-to { total-issued: u0, reputation-score: u100, verified: true } 
                                 (map-get? issuer-stats issuer)))
    )
    (map-set issuer-stats issuer
      (merge current-stats { 
        total-issued: (+ (get total-issued current-stats) u1),


        reputation-score: (if (>= (+ (get reputation-score current-stats) u1) u1000) u1000 (+ (get reputation-score current-stats) u1))
      })
    )
  )
)

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials credential-id)
)

(define-read-only (get-user-credentials (user principal))
  (map-get? user-credentials user)
)

(define-read-only (get-issuer-stats (issuer principal))
  (map-get? issuer-stats issuer)
)

(define-read-only (get-skill-category (category-name (string-ascii 30)))
  (map-get? skill-categories category-name)
)

(define-read-only (get-skill-requirements (skill-name (string-ascii 50)))
  (map-get? skill-requirements skill-name)
)

(define-read-only (is-issuer-authorized (issuer principal))
  (default-to false (map-get? authorized-issuers issuer))
)

(define-read-only (get-next-credential-id)
  (var-get next-credential-id)
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-read-only (get-credential-owner (credential-id uint))
  (nft-get-owner? skill-credential credential-id)
)

(define-map credential-endorsements
  { credential-id: uint, endorser: principal }
  {
    trust-score: uint,
    timestamp: uint,
    feedback: (string-ascii 100)
  }
)

(define-map endorsement-stats
  uint
  {
    total-endorsements: uint,
    average-trust-score: uint,
    last-endorsed: uint
  }
)

(define-map endorser-reputation
  principal
  {
    endorsements-given: uint,
    credibility-score: uint
  }
)

(define-constant ERR-ALREADY-ENDORSED (err u109))
(define-constant ERR-INVALID-TRUST-SCORE (err u110))
(define-constant ERR-SELF-ENDORSEMENT (err u111))
(define-constant ERR-ENDORSEMENT-NOT-FOUND (err u112))

(define-public (endorse-credential (credential-id uint) (trust-score uint) (feedback (string-ascii 100)))
  (let
    (
      (credential (unwrap! (map-get? credentials credential-id) ERR-CREDENTIAL-NOT-FOUND))
      (credential-owner (get recipient credential))
      (endorsement-key { credential-id: credential-id, endorser: tx-sender })
    )
    (asserts! (not (is-eq tx-sender credential-owner)) ERR-SELF-ENDORSEMENT)
    (asserts! (and (>= trust-score u1) (<= trust-score u10)) ERR-INVALID-TRUST-SCORE)
    (asserts! (is-none (map-get? credential-endorsements endorsement-key)) ERR-ALREADY-ENDORSED)
    
    (map-set credential-endorsements endorsement-key {
      trust-score: trust-score,
      timestamp: stacks-block-height,
      feedback: feedback
    })
    
    (update-endorsement-stats credential-id trust-score)
    (update-endorser-reputation tx-sender)
    (ok true)
  )
)

(define-public (revoke-endorsement (credential-id uint))
  (let
    (
      (endorsement-key { credential-id: credential-id, endorser: tx-sender })
    )
    (asserts! (is-some (map-get? credential-endorsements endorsement-key)) ERR-ENDORSEMENT-NOT-FOUND)
    (map-delete credential-endorsements endorsement-key)
    (ok true)
  )
)

(define-private (update-endorsement-stats (credential-id uint) (new-trust-score uint))
  (let
    (
      (current-stats (default-to { total-endorsements: u0, average-trust-score: u0, last-endorsed: u0 }
                                 (map-get? endorsement-stats credential-id)))
      (total-endorsements (+ (get total-endorsements current-stats) u1))
      (current-average (get average-trust-score current-stats))
      (new-average (/ (+ (* current-average (get total-endorsements current-stats)) new-trust-score) total-endorsements))
    )
    (map-set endorsement-stats credential-id {
      total-endorsements: total-endorsements,
      average-trust-score: new-average,
      last-endorsed: stacks-block-height
    })
  )
)

(define-private (update-endorser-reputation (endorser principal))
  (let
    (
      (current-rep (default-to { endorsements-given: u0, credibility-score: u50 }
                               (map-get? endorser-reputation endorser)))
    )
    (map-set endorser-reputation endorser {
      endorsements-given: (+ (get endorsements-given current-rep) u1),
      credibility-score: (if (>= (+ (get credibility-score current-rep) u1) u100)
                            u100
                            (+ (get credibility-score current-rep) u1))
    })
  )
)

(define-read-only (get-credential-endorsements (credential-id uint))
  (map-get? endorsement-stats credential-id)
)

(define-read-only (get-endorsement-details (credential-id uint) (endorser principal))
  (map-get? credential-endorsements { credential-id: credential-id, endorser: endorser })
)

(define-read-only (get-endorser-reputation (endorser principal))
  (map-get? endorser-reputation endorser)
)
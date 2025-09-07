(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_VOTING_ACTIVE (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_NOT_RESIDENT (err u106))
(define-constant ERR_ALREADY_RESIDENT (err u107))
(define-constant ERR_PROPOSAL_NOT_PASSED (err u108))
(define-constant ERR_BUDGET_EXCEEDED (err u109))
(define-constant ERR_INVALID_CATEGORY (err u110))
(define-constant ERR_BUDGET_NOT_SET (err u111))

(define-constant ERR_NOT_EMERGENCY_RESPONDER (err u112))
(define-constant ERR_EMERGENCY_FUND_DEPLETED (err u113))
(define-constant ERR_EMERGENCY_COOLDOWN_ACTIVE (err u114))
(define-constant ERR_AMOUNT_EXCEEDS_LIMIT (err u115))

(define-constant ERR_ASSET_NOT_FOUND (err u116))
(define-constant ERR_INVALID_ASSET_STATUS (err u117))
(define-constant ERR_ASSET_ALREADY_EXISTS (err u118))

(define-data-var asset-counter uint u0)

(define-data-var emergency-fund-balance uint u0)
(define-data-var emergency-deployment-counter uint u0)
(define-data-var last-emergency-deployment uint u0)
(define-data-var emergency-cooldown-period uint u144)
(define-data-var max-emergency-deployment uint u50000)


(define-data-var proposal-counter uint u0)
(define-data-var treasury-balance uint u0)

(define-map residents principal bool)
(define-map resident-voting-power principal uint)

(define-map proposals
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    amount-requested: uint,
    votes-for: uint,
    votes-against: uint,
    voting-end-height: uint,
    executed: bool,
    proposal-type: (string-ascii 20)
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voting-power: uint }
)

(define-map service-providers
  uint
  {
    name: (string-ascii 100),
    service-type: (string-ascii 50),
    provider-address: principal,
    monthly-cost: uint,
    active: bool
  }
)

(define-data-var service-provider-counter uint u0)

(define-public (register-resident)
  (begin
    (asserts! (is-none (map-get? residents tx-sender)) ERR_ALREADY_RESIDENT)
    (map-set residents tx-sender true)
    (map-set resident-voting-power tx-sender u1)
    (ok true)
  )
)

(define-public (deposit-to-treasury (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set treasury-balance (+ (var-get treasury-balance) amount))
    (ok true)
  )
)

(define-public (create-proposal 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (amount-requested uint)
  (proposal-type (string-ascii 20))
  (voting-duration uint)
)
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (voting-end (+ stacks-block-height voting-duration))
    )
    (asserts! (default-to false (map-get? residents tx-sender)) ERR_NOT_RESIDENT)
    (map-set proposals proposal-id
      {
        title: title,
        description: description,
        proposer: tx-sender,
        amount-requested: amount-requested,
        votes-for: u0,
        votes-against: u0,
        voting-end-height: voting-end,
        executed: false,
        proposal-type: proposal-type
      }
    )
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
      (voter-power (default-to u0 (map-get? resident-voting-power tx-sender)))
      (vote-key { proposal-id: proposal-id, voter: tx-sender })
    )
    (asserts! (default-to false (map-get? residents tx-sender)) ERR_NOT_RESIDENT)
    (asserts! (is-none (map-get? votes vote-key)) ERR_ALREADY_VOTED)
    (asserts! (< stacks-block-height (get voting-end-height proposal)) ERR_VOTING_ENDED)
    
    (map-set votes vote-key { vote: vote-for, voting-power: voter-power })
    
    (if vote-for
      (map-set proposals proposal-id
        (merge proposal { votes-for: (+ (get votes-for proposal) voter-power) })
      )
      (map-set proposals proposal-id
        (merge proposal { votes-against: (+ (get votes-against proposal) voter-power) })
      )
    )
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
      (current-treasury (var-get treasury-balance))
    )
    (asserts! (>= stacks-block-height (get voting-end-height proposal)) ERR_VOTING_ACTIVE)
    (asserts! (not (get executed proposal)) ERR_PROPOSAL_NOT_PASSED)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR_PROPOSAL_NOT_PASSED)
    (asserts! (>= current-treasury (get amount-requested proposal)) ERR_INSUFFICIENT_FUNDS)
    
    (try! (as-contract (stx-transfer? (get amount-requested proposal) tx-sender (get proposer proposal))))
    (var-set treasury-balance (- current-treasury (get amount-requested proposal)))
    (map-set proposals proposal-id (merge proposal { executed: true }))
    (ok true)
  )
)

(define-public (add-service-provider 
  (name (string-ascii 100))
  (service-type (string-ascii 50))
  (provider-address principal)
  (monthly-cost uint)
)
  (let
    (
      (provider-id (+ (var-get service-provider-counter) u1))
    )
    (asserts! (default-to false (map-get? residents tx-sender)) ERR_NOT_RESIDENT)
    (map-set service-providers provider-id
      {
        name: name,
        service-type: service-type,
        provider-address: provider-address,
        monthly-cost: monthly-cost,
        active: true
      }
    )
    (var-set service-provider-counter provider-id)
    (ok provider-id)
  )
)

(define-public (pay-service-provider (provider-id uint))
  (let
    (
      (provider (unwrap! (map-get? service-providers provider-id) ERR_PROPOSAL_NOT_FOUND))
      (current-treasury (var-get treasury-balance))
      (monthly-cost (get monthly-cost provider))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (get active provider) ERR_PROPOSAL_NOT_FOUND)
    (asserts! (>= current-treasury monthly-cost) ERR_INSUFFICIENT_FUNDS)
    
    (try! (as-contract (stx-transfer? monthly-cost tx-sender (get provider-address provider))))
    (var-set treasury-balance (- current-treasury monthly-cost))
    (ok true)
  )
)

(define-public (deactivate-service-provider (provider-id uint))
  (let
    (
      (provider (unwrap! (map-get? service-providers provider-id) ERR_PROPOSAL_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set service-providers provider-id (merge provider { active: false }))
    (ok true)
  )
)

(define-public (increase-voting-power (resident principal) (additional-power uint))
  (let
    (
      (current-power (default-to u0 (map-get? resident-voting-power resident)))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (default-to false (map-get? residents resident)) ERR_NOT_RESIDENT)
    (map-set resident-voting-power resident (+ current-power additional-power))
    (ok true)
  )
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-treasury-balance)
  (var-get treasury-balance)
)

(define-read-only (get-resident-status (resident principal))
  (default-to false (map-get? residents resident))
)

(define-read-only (get-voting-power (resident principal))
  (default-to u0 (map-get? resident-voting-power resident))
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-service-provider (provider-id uint))
  (map-get? service-providers provider-id)
)

(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)

(define-read-only (get-service-provider-count)
  (var-get service-provider-counter)
)

(define-read-only (is-proposal-passed (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (> (get votes-for proposal) (get votes-against proposal))
    false
  )
)

(define-map budget-allocations
  (string-ascii 20)
  {
    allocated-amount: uint,
    spent-amount: uint,
    active: bool
  }
)

(define-public (set-budget-allocation 
  (category (string-ascii 20))
  (amount uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= amount (var-get treasury-balance)) ERR_INSUFFICIENT_FUNDS)
    (map-set budget-allocations category
      {
        allocated-amount: amount,
        spent-amount: u0,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (execute-proposal-with-budget 
  (proposal-id uint)
  (budget-category (string-ascii 20))
)
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
      (budget (unwrap! (map-get? budget-allocations budget-category) ERR_BUDGET_NOT_SET))
      (current-treasury (var-get treasury-balance))
      (requested-amount (get amount-requested proposal))
      (available-budget (- (get allocated-amount budget) (get spent-amount budget)))
    )
    (asserts! (>= stacks-block-height (get voting-end-height proposal)) ERR_VOTING_ACTIVE)
    (asserts! (not (get executed proposal)) ERR_PROPOSAL_NOT_PASSED)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR_PROPOSAL_NOT_PASSED)
    (asserts! (>= current-treasury requested-amount) ERR_INSUFFICIENT_FUNDS)
    (asserts! (>= available-budget requested-amount) ERR_BUDGET_EXCEEDED)
    (asserts! (get active budget) ERR_INVALID_CATEGORY)
    
    (try! (as-contract (stx-transfer? requested-amount tx-sender (get proposer proposal))))
    (var-set treasury-balance (- current-treasury requested-amount))
    (map-set proposals proposal-id (merge proposal { executed: true }))
    (map-set budget-allocations budget-category
      (merge budget { spent-amount: (+ (get spent-amount budget) requested-amount) })
    )
    (ok true)
  )
)

(define-public (deactivate-budget-category (category (string-ascii 20)))
  (let
    (
      (budget (unwrap! (map-get? budget-allocations category) ERR_BUDGET_NOT_SET))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set budget-allocations category (merge budget { active: false }))
    (ok true)
  )
)

(define-read-only (get-budget-allocation (category (string-ascii 20)))
  (map-get? budget-allocations category)
)

(define-read-only (get-available-budget (category (string-ascii 20)))
  (match (map-get? budget-allocations category)
    budget (some (- (get allocated-amount budget) (get spent-amount budget)))
    none
  )
)

(define-read-only (get-budget-utilization (category (string-ascii 20)))
  (match (map-get? budget-allocations category)
    budget 
      (if (> (get allocated-amount budget) u0)
        (some (/ (* (get spent-amount budget) u100) (get allocated-amount budget)))
        (some u0)
      )
    none
  )
)


(define-map emergency-responders principal bool)

(define-map emergency-deployments
  uint
  {
    responder: principal,
    amount: uint,
    reason: (string-ascii 200),
    deployment-height: uint,
    emergency-type: (string-ascii 50)
  }
)

(define-public (authorize-emergency-responder (responder principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set emergency-responders responder true)
    (ok true)
  )
)

(define-public (revoke-emergency-responder (responder principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-delete emergency-responders responder)
    (ok true)
  )
)

(define-public (fund-emergency-reserve (amount uint))
  (begin
    (asserts! (default-to false (map-get? residents tx-sender)) ERR_NOT_RESIDENT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set emergency-fund-balance (+ (var-get emergency-fund-balance) amount))
    (ok true)
  )
)

(define-public (deploy-emergency-funds 
  (amount uint)
  (reason (string-ascii 200))
  (emergency-type (string-ascii 50))
)
  (let
    (
      (deployment-id (+ (var-get emergency-deployment-counter) u1))
      (current-fund (var-get emergency-fund-balance))
      (last-deployment (var-get last-emergency-deployment))
      (cooldown-blocks (var-get emergency-cooldown-period))
      (max-amount (var-get max-emergency-deployment))
    )
    (asserts! (default-to false (map-get? emergency-responders tx-sender)) ERR_NOT_EMERGENCY_RESPONDER)
    (asserts! (>= current-fund amount) ERR_EMERGENCY_FUND_DEPLETED)
    (asserts! (<= amount max-amount) ERR_AMOUNT_EXCEEDS_LIMIT)
    (asserts! (>= stacks-block-height (+ last-deployment cooldown-blocks)) ERR_EMERGENCY_COOLDOWN_ACTIVE)
    
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (var-set emergency-fund-balance (- current-fund amount))
    (var-set last-emergency-deployment stacks-block-height)
    (var-set emergency-deployment-counter deployment-id)
    
    (map-set emergency-deployments deployment-id
      {
        responder: tx-sender,
        amount: amount,
        reason: reason,
        deployment-height: stacks-block-height,
        emergency-type: emergency-type
      }
    )
    (ok deployment-id)
  )
)

(define-read-only (get-emergency-fund-balance)
  (var-get emergency-fund-balance)
)

(define-read-only (is-emergency-responder (responder principal))
  (default-to false (map-get? emergency-responders responder))
)

(define-read-only (get-emergency-deployment (deployment-id uint))
  (map-get? emergency-deployments deployment-id)
)

(define-read-only (get-emergency-deployment-count)
  (var-get emergency-deployment-counter)
)



(define-map community-assets
  uint
  {
    name: (string-ascii 100),
    asset-type: (string-ascii 30),
    current-value: uint,
    acquisition-date: uint,
    location: (string-ascii 100),
    status: (string-ascii 20),
    manager: principal,
    last-maintenance: uint
  }
)

(define-map asset-history
  { asset-id: uint, record-id: uint }
  {
    action: (string-ascii 50),
    old-value: uint,
    new-value: uint,
    timestamp: uint,
    updated-by: principal
  }
)

(define-data-var history-counter uint u0)

(define-public (register-community-asset
  (name (string-ascii 100))
  (asset-type (string-ascii 30))
  (initial-value uint)
  (location (string-ascii 100))
  (manager principal)
)
  (let
    ((asset-id (+ (var-get asset-counter) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set community-assets asset-id
      {
        name: name,
        asset-type: asset-type,
        current-value: initial-value,
        acquisition-date: stacks-block-height,
        location: location,
        status: "active",
        manager: manager,
        last-maintenance: stacks-block-height
      }
    )
    (var-set asset-counter asset-id)
    (ok asset-id)
  )
)

(define-public (update-asset-value (asset-id uint) (new-value uint))
  (let
    (
      (asset (unwrap! (map-get? community-assets asset-id) ERR_ASSET_NOT_FOUND))
      (history-id (+ (var-get history-counter) u1))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get manager asset))) ERR_NOT_AUTHORIZED)
    (map-set asset-history { asset-id: asset-id, record-id: history-id }
      {
        action: "value-update",
        old-value: (get current-value asset),
        new-value: new-value,
        timestamp: stacks-block-height,
        updated-by: tx-sender
      }
    )
    (map-set community-assets asset-id (merge asset { current-value: new-value }))
    (var-set history-counter history-id)
    (ok true)
  )
)

(define-read-only (get-community-asset (asset-id uint))
  (map-get? community-assets asset-id)
)

(define-read-only (get-total-asset-value)
  (fold calculate-total-value (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0)
)

(define-read-only (get-asset-count)
  (var-get asset-counter)
)

(define-private (calculate-total-value (asset-id uint) (total uint))
  (match (map-get? community-assets asset-id)
    asset (+ total (get current-value asset))
    total
  )
)
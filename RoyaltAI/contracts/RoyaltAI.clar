;; AI-NFT-Royalty-Distribution
;; A smart contract for managing AI-generated NFTs with royalty distribution

(define-non-fungible-token ai-nft uint)

;; Data structures
(define-map nft-metadata
  { token-id: uint }
  {
    creator: principal,
    title: (string-utf8 100),
    royalty-percentage: uint,
    contributors: (list 5 principal),
    contributor-shares: (list 5 uint)
  }
)

(define-map royalty-balances
  { address: principal }
  { balance: uint }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant max-royalty-percentage u30) ;; 30%
(define-constant platform-fee-percentage u5) ;; 5%
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-token (err u101))
(define-constant err-invalid-royalty (err u102))
(define-constant err-invalid-contributors (err u103))
(define-constant err-contract-paused (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-invalid-shares (err u106))

;; Variables
(define-data-var last-token-id uint u0)
(define-data-var platform-address principal contract-owner)
(define-data-var paused bool false)
(define-data-var current-adjustment-factor uint u100)
(define-data-var current-total-shares uint u100)

;; Check if principal is the owner of the token
(define-private (is-owner? (token-id uint) (address principal))
  (is-eq address (unwrap! (nft-get-owner? ai-nft token-id) false))
)

;; Add to royalty balance
(define-private (add-to-royalty-balance (address principal) (amount uint))
  (let
    (
      (current-balance (default-to { balance: u0 } (map-get? royalty-balances { address: address })))
      (new-balance (+ (get balance current-balance) amount))
    )
    (map-set royalty-balances
      { address: address }
      { balance: new-balance }
    )
  )
)

;; Process royalty distribution for a single contributor
(define-private (process-contributor-royalty 
                  (contributor principal) 
                  (share uint) 
                  (total-shares uint) 
                  (amount uint))
  (if (> total-shares u0)
    (let
      (
        (contributor-amount (/ (* amount share) total-shares))
      )
      (add-to-royalty-balance contributor contributor-amount)
    )
    false
  )
)

;; Process royalty distribution - completely non-recursive implementation
(define-private (process-royalty-distribution (token-id uint) (royalty-amount uint))
  (let
    (
      (metadata (unwrap! (map-get? nft-metadata { token-id: token-id }) err-invalid-token))
      (creator (get creator metadata))
      (contributors (get contributors metadata))
      (contributor-shares (get contributor-shares metadata))
      (total-shares (fold + contributor-shares u0))
      (contributors-count (len contributors))
    )
    ;; If no contributors, all royalties go to creator
    (if (is-eq contributors-count u0)
      (begin
        (add-to-royalty-balance creator royalty-amount)
        (ok true)
      )
      ;; Otherwise distribute according to shares
      (let
        (
          (creator-in-list (is-some (index-of contributors creator)))
          (creator-amount (if creator-in-list u0 (/ (* royalty-amount u50) u100)))
          (contributor-amount (- royalty-amount creator-amount))
        )
        (begin
          ;; Add creator's share if not in contributors list
          (if creator-in-list
            true
            (add-to-royalty-balance creator creator-amount)
          )
          
          ;; Process individual contributors - no recursion, just handle each possible index
          (if (>= contributors-count u1)
            (process-contributor-royalty 
              (unwrap-panic (element-at contributors u0))
              (unwrap-panic (element-at contributor-shares u0))
              total-shares
              contributor-amount)
            true)
          
          (if (>= contributors-count u2)
            (process-contributor-royalty 
              (unwrap-panic (element-at contributors u1))
              (unwrap-panic (element-at contributor-shares u1))
              total-shares
              contributor-amount)
            true)
          
          (if (>= contributors-count u3)
            (process-contributor-royalty 
              (unwrap-panic (element-at contributors u2))
              (unwrap-panic (element-at contributor-shares u2))
              total-shares
              contributor-amount)
            true)
          
          (if (>= contributors-count u4)
            (process-contributor-royalty 
              (unwrap-panic (element-at contributors u3))
              (unwrap-panic (element-at contributor-shares u3))
              total-shares
              contributor-amount)
            true)
          
          (if (>= contributors-count u5)
            (process-contributor-royalty 
              (unwrap-panic (element-at contributors u4))
              (unwrap-panic (element-at contributor-shares u4))
              total-shares
              contributor-amount)
            true)
          
          (ok true)
        )
      )
    )
  )
)

;; Helper functions for performance calculation
(define-private (get-period (data {
  period: uint,
  sales-volume: uint,
  contributor-performance: (list 5 uint)
}))
  (get period data)
)

(define-private (get-sales-volume (data {
  period: uint,
  sales-volume: uint,
  contributor-performance: (list 5 uint)
}))
  (get sales-volume data)
)

(define-private (get-weight (period uint))
  (- u1000 (* (- block-height period) u10))
)

(define-private (weight-by-recency (period uint) (volume uint))
  (* volume (get-weight period))
)

;; Adjust share based on performance factor (using global variable)
(define-private (adjust-share-with-factor (share uint))
  (+ share (/ (* share (- (var-get current-adjustment-factor) u100)) u100))
)

;; Normalize share against total (using global variable)
(define-private (normalize-share (share uint))
  (/ (* share u100) (var-get current-total-shares))
)

;; Calculate performance score from historical data
(define-private (calculate-performance-score
    (performance-data (list 10 {
      period: uint,
      sales-volume: uint,
      contributor-performance: (list 5 uint)
    })))
  (let
    (
      (periods (map get-period performance-data))
      (volumes (map get-sales-volume performance-data))
      (weighted-sum (fold + (map weight-by-recency periods volumes) u0))
      (total-weight (fold + (map get-weight periods) u0))
    )
    (if (> total-weight u0)
      (/ weighted-sum total-weight)
      u100) ;; Default score if no data
  )
)

;; Optimize shares based on performance
(define-private (optimize-shares
    (shares (list 5 uint))
    (performance-score uint))
  (begin
    ;; Set the adjustment factor in the global variable
    (var-set current-adjustment-factor (/ performance-score u100))
    
    (let
      (
        (adjusted-shares (map adjust-share-with-factor shares))
        (total-adjusted (fold + adjusted-shares u0))
      )
      (if (> total-adjusted u0)
        (begin
          (var-set current-total-shares total-adjusted)
          (map normalize-share adjusted-shares)
        )
        shares) ;; Return original shares if adjustment fails
    )
  )
)

;; Mint a new AI-NFT
(define-public (mint-ai-nft
    (creator principal)
    (title (string-utf8 100))
    (royalty-percentage uint)
    (contributors (list 5 principal))
    (contributor-shares (list 5 uint)))
  (let
    (
      (token-id (+ (var-get last-token-id) u1))
    )
    (asserts! (or (is-eq tx-sender creator) (is-eq tx-sender contract-owner)) err-not-authorized)
    (asserts! (not (var-get paused)) err-contract-paused)
    (asserts! (<= royalty-percentage max-royalty-percentage) err-invalid-royalty)
    (asserts! (is-eq (len contributors) (len contributor-shares)) err-invalid-contributors)
    
    ;; Mint the NFT
    (try! (nft-mint? ai-nft token-id creator))
    
    ;; Store metadata
    (map-set nft-metadata
      { token-id: token-id }
      {
        creator: creator,
        title: title,
        royalty-percentage: royalty-percentage,
        contributors: contributors,
        contributor-shares: contributor-shares
      }
    )
    
    ;; Update last token ID
    (var-set last-token-id token-id)
    
    (ok token-id)
  )
)

;; Transfer NFT with royalty payment
(define-public (transfer-with-royalty
    (token-id uint)
    (sender principal)
    (recipient principal)
    (price uint))
  (let
    (
      (metadata (unwrap! (map-get? nft-metadata { token-id: token-id }) err-invalid-token))
      (royalty-amount (/ (* price (get royalty-percentage metadata)) u100))
      (platform-fee (/ (* price platform-fee-percentage) u100))
      (seller-amount (- price (+ royalty-amount platform-fee)))
    )
    (asserts! (is-owner? token-id sender) err-not-authorized)
    (asserts! (not (var-get paused)) err-contract-paused)
    
    ;; Transfer NFT
    (try! (nft-transfer? ai-nft token-id sender recipient))
    
    ;; Pay platform fee
    (try! (stx-transfer? platform-fee tx-sender (var-get platform-address)))
    
    ;; Pay seller
    (try! (stx-transfer? seller-amount tx-sender sender))
    
    ;; Process royalty distribution
    (try! (process-royalty-distribution token-id royalty-amount))
    
    (ok true)
  )
)

;; Get NFT metadata
(define-read-only (get-nft-metadata (token-id uint))
  (map-get? nft-metadata { token-id: token-id })
)

;; Get royalty balance
(define-read-only (get-royalty-balance (address principal))
  (default-to { balance: u0 } (map-get? royalty-balances { address: address }))
)

;; Set platform address
(define-public (set-platform-address (new-address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (var-set platform-address new-address)
    (ok true)
  )
)

;; Set paused state
(define-public (set-paused (new-paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (var-set paused new-paused)
    (ok true)
  )
)

;; Withdraw royalty balance
(define-public (withdraw-royalties)
  (let
    (
      (balance-data (default-to { balance: u0 } (map-get? royalty-balances { address: tx-sender })))
      (balance (get balance balance-data))
    )
    (asserts! (> balance u0) err-insufficient-balance)
    (map-set royalty-balances
      { address: tx-sender }
      { balance: u0 }
    )
    (try! (as-contract (stx-transfer? balance contract-owner tx-sender)))
    (ok balance)
  )
)



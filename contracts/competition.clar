;; Competition Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-competition-not-found (err u101))
(define-constant err-competition-ended (err u102))

;; Data Variables
(define-data-var last-competition-id uint u0)

;; Define the structure of a competition
(define-map competitions
  { competition-id: uint }
  {
    name: (string-ascii 64),
    start-block: uint,
    end-block: uint,
    stake-amount: uint,
    prize-pool: uint,
    participants: (list 50 principal)
  }
)

;; Create a new competition
(define-public (create-competition (name (string-ascii 64)) (duration uint) (stake-amount uint))
  (let
    (
      (competition-id (+ (var-get last-competition-id) u1))
      (start-block block-height)
      (end-block (+ block-height duration))
    )
    (map-set competitions
      { competition-id: competition-id }
      {
        name: name,
        start-block: start-block,
        end-block: end-block,
        stake-amount: stake-amount,
        prize-pool: u0,
        participants: (list)
      }
    )
    (var-set last-competition-id competition-id)
    (ok competition-id)
  )
)

;; Join a competition
(define-public (join-competition (competition-id uint))
  (let
    (
      (competition (unwrap! (map-get? competitions { competition-id: competition-id }) err-competition-not-found))
      (stake-amount (get stake-amount competition))
    )
    (asserts! (< block-height (get end-block competition)) err-competition-ended)
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    (map-set competitions
      { competition-id: competition-id }
      (merge competition {
        prize-pool: (+ (get prize-pool competition) stake-amount),
        participants: (unwrap-panic (as-max-len? (append (get participants competition) tx-sender) u50))
      })
    )
    (ok true)
  )
)

;; End competition and distribute rewards (simplified)
(define-public (end-competition (competition-id uint))
  (let
    (
      (competition (unwrap! (map-get? competitions { competition-id: competition-id }) err-competition-not-found))
      (prize-pool (get prize-pool competition))
      (participants (get participants competition))
      (participant-count (len participants))
    )
    (asserts! (>= block-height (get end-block competition)) err-competition-ended)
    (asserts! (> participant-count u0) err-competition-ended)
    (let
      (
        (winner (unwrap-panic (element-at participants (mod block-height participant-count))))
        (prize prize-pool)
      )
      (try! (as-contract (stx-transfer? prize tx-sender winner)))
      (ok true)
    )
  )
)

;; Get competition details
(define-read-only (get-competition (competition-id uint))
  (map-get? competitions { competition-id: competition-id })
)


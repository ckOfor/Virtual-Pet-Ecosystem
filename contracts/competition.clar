;; Simple Virtual Pet and Competition Contract

;; Constants
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))

;; Data Variables
(define-data-var last-pet-id uint u0)
(define-data-var last-competition-id uint u0)

;; Define the structure of a pet
(define-map pets
  { pet-id: uint }
  {
    owner: principal,
    dna: (string-ascii 64),
    name: (string-ascii 64),
    birth-block: uint
  }
)

;; Define the structure of a competition
(define-map competitions
  { competition-id: uint }
  {
    name: (string-ascii 64),
    end-block: uint,
    participants: (list 50 principal)
  }
)

;; Mint a new pet
(define-public (mint-pet (name (string-ascii 64)))
  (let
    (
      (pet-id (+ (var-get last-pet-id) u1))
      (dna (concat (slice? (to-ascii (var-get last-pet-id)) u0 u32)
                   (slice? (to-ascii block-height) u0 u32)))
    )
    (map-set pets
      { pet-id: pet-id }
      {
        owner: tx-sender,
        dna: dna,
        name: name,
        birth-block: block-height
      }
    )
    (var-set last-pet-id pet-id)
    (ok pet-id)
  )
)

;; Create a new competition
(define-public (create-competition (name (string-ascii 64)) (duration uint))
  (let
    (
      (competition-id (+ (var-get last-competition-id) u1))
      (end-block (+ block-height duration))
    )
    (map-set competitions
      { competition-id: competition-id }
      {
        name: name,
        end-block: end-block,
        participants: (list)
      }
    )
    (var-set last-competition-id competition-id)
    (ok competition-id)
  )
)

;; Join a competition
(define-public (join-competition (competition-id uint) (pet-id uint))
  (let
    (
      (competition (unwrap! (map-get? competitions { competition-id: competition-id }) err-not-found))
      (pet (unwrap! (map-get? pets { pet-id: pet-id }) err-not-found))
    )
    (asserts! (is-eq (get owner pet) tx-sender) err-unauthorized)
    (asserts! (< block-height (get end-block competition)) err-unauthorized)
    (ok (map-set competitions
      { competition-id: competition-id }
      (merge competition {
        participants: (unwrap-panic (as-max-len? (append (get participants competition) tx-sender) u50))
      })))
  )
)

;; Get pet details
(define-read-only (get-pet (pet-id uint))
  (map-get? pets { pet-id: pet-id })
)

;; Get competition details
(define-read-only (get-competition (competition-id uint))
  (map-get? competitions { competition-id: competition-id })
)


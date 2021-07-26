.segment "HEADER"
  .byte "NES"
  .byte $1A ; "end of file", mora tu biti
  .byte $02 ; 2 * 16KB PRG ROM
  .byte $01 ; 1 * 8KB CHR ROM
  .byte %00000000 ; mapper i mirroring (iNES flags 6)
  .byte $00 ; mapper (iNES flags 7)
  .byte $00 ; PRG RAM veličina, (iNES flags 8)
  .byte $00 ; TV sustav (iNES flags 9)
  .byte $00 ; TV sustav, prisutnost PRG RAM (iNES flags 10)
  .byte $00, $00, $00, $00, $00 ; treba biti popunjeno s 0

.segment "ZEROPAGE"
gumbi: .res 1 ; vrijednost gumba pritisnutih na kontroleru
statusGumb: .res 1 ; 0 ako nije pritisnut nikakav gumb, 1 ako je pritisnut neki gumb
SELposition: .res 1 ; pozicija "miša", tj. kontrolera na ekranu
naRubu: .res 1 ; samo 0, 1 ili 2... ako se pokazivač nalazi na lijevom rubu ploče: 1, ako se nalazi na desnom: 2
;;; mem. lokacija 04 ovo ispod
rand_l: .res 1
temp_ran: .res 1
Gtimer: .res 1 ; timer koji se kod svakog NMI-a inkrementira
;;; mem. lokacija 07 ovo ispod
brojnik: .res 1 ; služi kao i pokazatelj MANJEG bajta labele za pozadinu
nazivnik: .res 1 ; služi kao i pokazatelj VEĆEG bajta labele za pozadinu
factor1: .res 1
factor2: .res 1 ; služi kao i privremeni brojač za mine i privremena varijabla općenito
;;; mem. lokacija 0B ovo ispod
visinaPloce: .res 1
duljinaPloce: .res 1
MinebrojacGen: .res 1 ; brojač kolko put budu se mine generirale (kolko mina je na polju) (2. korak) i koliko mina okružuje polje (3. korak)
pocetakPloce: .res 1 ; lokacija (po PPU nametable adresiranju) 1. polja ploče

.segment "STARTUP" ; inicijalizacija
RESET:
  SEI ; privremeno isključi interrupte
  CLD ; isključi decimalni način

  ; isključi interrupte za zvuk
  LDX #$40
  STX $4017

  ; inicijaliziraj stog
  LDX #$FF
  TXS

  INX ; X je bio $FF, sad ga inkrementiramo i sad je $00, što nam i treba

  ; očisti PPU registre
  STX $2000
  STX $2001

  STX $4010 ; isključi PCM

  ; čekamo "vertical blanking interval"
:
  BIT $2002
  BPL :-

  TXA ; stavi X u A jer je X $00 a to nam i treba

CLEARMEM:
  STA $0000, X
  STA $0100, X
  STA $0300, X
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  LDA #$FF
  STA $0200, X ; ovo isto čistimo, ali mora biti različito od $00 jer bi inače sprite-ovi bili na ekranu ($FF je izvan ekrana)
  LDA #$00
  INX
  BNE CLEARMEM

  ; čekamo "vertical blanking interval"
:
  BIT $2002
  BPL :-

  ; inicijalizacija OAM DMA
  LDA #$02
  STA $4014

  ; inicijalizacija za učitavanje paleta (palete su spremljene u PPU RAM od adrese $3F00)
  LDA $2002
  LDA #$3F ; učitavamo MSB u $2006
  STA $2006
  LDA #$00 ; učitavamo LSB u $2006
  STA $2006

  LDX #$00 ; čistimo X

UcitajPalete:
  LDA _palete, X
  STA $2007 ; spremamo palete u $2007 (PPUDATA)... nakon pisanja se automatski povećava za 1 ($3F00 -> $3F01 -> $3F02 -> ...)
  INX
  CPX #$20 ; vrtjet će se 32 puta ($20) jer imamo 32 bajta paleta
  BNE UcitajPalete

  LDX #$00 ; čistimo X

UcitajSpriteove:
  LDA _spriteovi, X
  STA $0200, X ; spremamo sprite-ove direktno u RAM
  INX
  CPX #$8 ; koliko puta će se odvrtjeti (4*[broj sprite-ova])
  BNE UcitajSpriteove

  ; inicijalizacija za učitavanje pozadine (pozadina je spremljena u PPU RAM od adrese $2000)
  LDA $2002
  LDA #$20
  STA $2006 ; učitavamo MSB u $2006
  LDA #$00
  STA $2006 ; učitavamo LSB u $2006

  LDA #<_pozadina ; učitaj manji bajt labele _pozadina i spremi ga
  STA brojnik
  LDA #>_pozadina ; učitaj veći bajt labele _pozadina i spremi ga
  STA nazivnik

  LDX #$00 ; čistimo X
  LDY #$00 ; čistimo Y

UcitajPozadinu: ; učitavamo i pozadinu i atribut(iv)nu tablicu -> sve to zajedno se zove "Nametable"
  LDA (brojnik), Y ; učitaj ono što se nalazi u: [brojnik][brojnik+1 (brojnik+1 = nazivnik)] -> to je zapravo labela _pozadina.. svemu tome dodaj još ono što se nalazi u Y
  STA $2007 ; spremamo palete u $2007 (PPUDATA)... nakon pisanja se automatski povećava za 1 ($2000 -> $2001 -> $2002 -> ...)
  INY
  CPY #$00 ; odvrti 255 puta
  BNE UcitajPozadinu

  INC nazivnik ; povećavamo veći bajt labele _pozadina da možemo opet prevrtjeti još 255 puta
  INX
  CPX #$04 ; ukupno će se 4 puta izvrtjeti ovo gore jer je veličina Nametable-a (pozadina + atributi) $400.
  BNE UcitajPozadinu

  CLI ; ponovno uključi interrupte

  LDA #%10010000 ; inicijalizacija PPU-a (PPUCTRL) (uključi NMI, pozadina se nalazi na 2. djelu tablice uzorka (počevši od adrese $1000) a sprite-ovi se nalaze na 1. djelu)
  STA $2000
  JSR Inic_pozadine

  JMP VRTI

.segment "CODE"
VRTI:
Kontroler:
  JSR CitajKontroler ; skoči na subrutinu da pročitamo kontroler
  LDA gumbi ; učitaj koji su gumbi pritisnuti u akumulator
  AND #%00001000 ; je li "Up" pritisnuto?
  BEQ :+ ; ako je "Up" pritisnuto, skoči na GlavniIzbornikPomakni
  LDX #$00 ; spremamo da poslije znamo "na čemu smo" (GlavniIzbornikPomakni)
  JMP GlavniIzbornikPomakni
:
  LDA gumbi
  AND #%00000100 ; je li "Down" pritisnuto?
  BEQ :+
  LDX #$01 ; spremamo da poslije znamo "na čemu smo" (GlavniIzbornikPomakni)
  JMP GlavniIzbornikPomakni

:
  LDX #$00
  STX statusGumb ; čistimo zastavicu pritisnutog gumba

  LDA gumbi
  AND #%00010000 ; je li "Start" pritisnuto?
  BEQ :+
  JMP PokreniIgru
:

KontrolerGotovo:
  JMP VRTI

NMI:
  PHA ; spremamo akumulator u stog jer se desio prekid (NMI)

  INC Gtimer ; povećaj timer koji služi za generiranje nasumičnih brojeva
  LDA #$02 ; kopiraj sprite podatke s $0200
  STA $4014

  PLA ; vadimo akumulator iz stoga,
  RTI ; i vraćamo se gdje smo bili

PokreniIgru:
  LDA $0200
  .include "./ploca.asm"

CitajKontroler:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
:
  LDA $4016
  LSR A ; bit0 -> Carry
  ROL gumbi ; bit0 <- Carry
  DEX
  BNE :-

  RTS

GlavniIzbornikPomakni:
  LDA statusGumb
  BEQ PDa ; ako je 0, (zastavica "zero" je jednaka 0), odnosno ako nije nikakav gumb pritisnut, skoči na PDa (PomakniDa [potvrdno])
  JMP KontrolerGotovo

PDa:
  LDA $0200 ; učitaj Y koordinatu 1. sprite-a
  CPX #$01 ; ako je X jednak 0, stisnuto je "Up", a ako je X jednak 1, stisnuto je "Down"... X=0 -> Carry=0; X=1 -> Carry=1
  BNE :+

  ; ako si ovdje, znači da je kliknut gumb "Down", tj. pomakni izbornik prema dolje
  SBC #$F0 ; inače bi dodali $10, ali nam je Carry postavljeni pa koristimo oduzimanje te oduzmemo $F0 jer dođe na isto oduzimamo li $F0 ili dodajemo $10 zbog overflow-a
  CMP #$BF ; $CF je izvan onoga što se može odabrati pa se napravi "wrap" i dođi na $8F ("početničko")
  BNE GlavniIzbornikSpremi
  LDA #$8F
  JMP GlavniIzbornikSpremi

: ; ako si ovdje, znači da je kliknut gumb "Up", tj. pomakni izbornik prema gore
  ADC #$F0 ; objašnjenje ovoga gore
  CMP #$7F ; $7F je izvan onoga što se može odabrati pa se napravi "wrap" i dođi na $BF ("prilagođeno")
  BNE GlavniIzbornikSpremi
  LDA #$AF
GlavniIzbornikSpremi:
  STA $0200
  STA $0204 ; spremi u 1. i 2. sprite

  JSR SpritePoX
  INC statusGumb
  JMP KontrolerGotovo

SpritePoX: ; pomakni sprite po X poziciji na onu gdje se nalaze slova (da bude uz slova)
  CMP #$8F ; "početničko"
  BNE :+
  LDA #$50
  LDX #$A8
  JSR SpremiXPoz
  RTS
:
  CMP #$9F ; "srednje"
  BNE :+
  LDA #$60
  LDX #$98
  JSR SpremiXPoz
  RTS
:
  LDA #$60
  LDX #$90
  JSR SpremiXPoz
  RTS

SpremiXPoz:
  STA $0203
  STX $0207 ; spremi X poziciju na lijevi i desni sprite
  RTS

Funkcije:
  .include "./funkcije.asm"

Inic_pozadine:
  LDA #%00011110 ; inicijalizacija PPU-a (PPUMASK) (omogući sprite-ove i pozadinu)
  STA $2001
  LDA #$00 ; inicijalizacija PPU-a (PPUSCROLL) (isključujemo skrolanje)
  STA $2005
  STA $2005
  RTS

_palete:
  .incbin "./datoteke/boje.pal"
  .byte $2D,$16,$27,$30, $2D,$1A,$30,$27, $2D,$16,$30,$27, $2D,$0F,$36,$17  ; sprite paleta

_spriteovi:
  .byte $8F, $00, $00, $50 ; Y pozicija, broj sprite-a, atributi, X pozicija
  .byte $8F, $00, %01000000, $A8

_pozadina:
  .incbin "./datoteke/pocetniZasl.nam"

; _pozadina i _atributi moraju biti jedan pored drugoga (prvo _pozadina pa _atributi).. dakle tu ništa pisati

_atributi:
  .byte %00000000

.segment "VECTORS"
  .word NMI
  .word RESET

.segment "CHARS"
  .incbin "./datoteke/novo.chr"

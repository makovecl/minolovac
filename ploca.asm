; početak generiranja ploče
  CMP #$8F ; kliknuto na "početničko"
  BNE :+
  LDA #$5
  STA visinaPloce
  STA duljinaPloce
  LDA #$5
  STA MinebrojacGen ; koliko će biti mina na ploči
  JMP PrikaziPlocu
:
  CMP #$9F ; kliknuto na "srednje"
  BNE :+
  LDA #$F
  STA duljinaPloce
  STA visinaPloce
  LDA #$1E
  STA MinebrojacGen
  JMP PrikaziPlocu
:
  CMP #$AF ; kliknuto na "teško"
  LDA #$14
  STA duljinaPloce
  LDA #$C
  STA visinaPloce
  LDA #$20
  STA MinebrojacGen

; tu nista pisati, treba skociti na PrikaziPlocu

PrikaziPlocu:
  LDA #$00
  STA $2001 ; moramo ovo očistiti da možemo učitati pozadinu

  LDA $2002
  LDA #$20
  STA $2006 ; učitavamo MSB u $2006
  LDA #$00
  STA $2006 ; učitavamo LSB u $2006

  LDA #<_ploca ; učitaj manji bajt labele _ploca i spremi ga
  STA brojnik
  LDA #>_ploca ; učitaj veći bajt labele _ploca i spremi ga
  STA nazivnik

  LDX #$00 ; čistimo X
  LDY #$00 ; čistimo Y

PlocaUcitaj: ; učitavamo i pozadinu i atribut(iv)nu tablicu -> sve to zajedno se zove "Nametable"
  LDA (brojnik), Y ; učitaj ono što se nalazi u: [brojnik][brojnik+1 (brojnik+1 = nazivnik)] -> to je zapravo labela _pozadina.. svemu tome dodaj još ono što se nalazi u Y
  STA $2007 ; spremamo palete u $2007 (PPUDATA)... nakon pisanja se automatski povećava za 1 ($2000 -> $2001 -> $2002 -> ...)
  INY
  CPY #$00 ; odvrti 255 puta
  BNE PlocaUcitaj

  INC nazivnik ; povećavamo veći bajt labele _ploca da možemo opet prevrtjeti još 255 puta
  INX
  CPX #$04 ; ukupno će se 4 puta izvrtjeti ovo gore jer je veličina Nametable-a (pozadina + atributi) $400.
  BNE PlocaUcitaj

  ; dovde smo učitali "mine", "vrijeme" i crtu, ovdje ispod učitavamo ploču prema zadanim parametrima (duljina, visina..)

  LDA #$20 ; duljina ekrana
  SEC
  SBC duljinaPloce ; oduzimamo duljinu ekrana od duljine ploče, da znamo centrirati na ekran
  STA brojnik
  LDA #$2
  STA nazivnik
  JSR Division

  LDA brojnik
  STA factor2 ; spremamo broj tile-a gdje se nalazi 1. lokacija da poslije možemo pomnožiti s 8 i spremiti sprite
  LDA #$E0 ; broj početnog tile-a, tj. direktno ispod crte "čistam" lijevo na ekranu (da možemo zbrojiti s factor2)
  CLC
  ADC brojnik ; napokon dobijemo poziciju, tj. memorijsku lokaciju kamo se treba spremiti 1. lokacija ploče
  STA pocetakPloce ; spremamo da poslije znamo

  TAX ; privremeno spremamo A u X, tj. poziciju od prijašnjih linija u X

  LDA #$20
  STA factor1 ; privremeno spremamo to tu jer budemo poslije zbrajali
  STX factor2 ; isto i tu spremamo privremeno

  LDA $2002 ; čistimo "address latch"
  LDA factor1
  STA $2006
  STX $2006

  LDX #$00 ; čistimo X
  LDY #$00 ; čistimo Y

CrtajPolja:
  INY
  LDA #$4C ; predstavlja "praznu kućicu", tj. tile broj $4C
  STA $2007

  CPY duljinaPloce
  BNE CrtajPolja

  INX

  LDA factor2
  CLC
  ADC #$20
  BCC :+
  INC factor1

:
  STA factor2

  LDA $2002
  LDA factor1
  STA $2006
  LDA factor2
  STA $2006
  LDY #$00

  CPX visinaPloce
  BNE CrtajPolja

  JSR Inic_pozadine

  ; ovdje ispod postavljamo sprite-ove
  LDA #$37 ; Y poziciju sprite-ova moramo oduzeti za 1 jer se sprite ne prikazuje na 1. liniji
  STA $0200
  LDA #$01
  STA $0201
  STA naRubu ; budući da ispod postavljamo da se pokazivač nalazi na 1. mjestu, znači da je na rubu
  LDA #$00
  STA $0202
  STA SELposition ; "resetiramo" gdje se nalazi pokazivač jer se uvijek nalazi na 1. mjestu (počinje od 0)

  LDA #$FF
  STA $0204 ; u ova 4 retka brišemo 2. sprite (desnu strelicu) od početnog zaslona
  STA $0205
  STA $0206
  STA $0207

  LDA #$8
  STA factor1
  JSR Mnozenje ; factor2 je vec inicijaliziran, a to je broj tile-a

  LDA factor1
  STA $0203

VRTIPLOCA:
Kontrol: ; objašnjeno u glavnoj "VRTI" rutini
  JSR CitajKontroler
  LDA gumbi
  AND #%00001000 ; je li "Up" pritisnuto?
  BEQ :+ ; ako je "Up" pritisnuto, skoči na PomakniPokazivacGore
  LDY #$0 ; spremamo da znamo "na čemu smo"
  JMP PomakniPokazivacGoreDolje

:
  LDA gumbi
  AND #%00000100 ; je li "Down" pritisnuto?
  BEQ :+
  LDY #$1 ; spremamo da znamo "na čemu smo"
  JMP PomakniPokazivacGoreDolje

:
  LDA gumbi
  AND #%00000010 ; je li "Left" pritisnuto?
  BEQ :+
  LDY #$0 ; spremamo da znamo "na čemu smo"
  JMP PomakniPokazivacLijevoDesno

:
  LDA gumbi
  AND #%00000001 ; je li "Right" pritisnuto
  BEQ :+
  LDY #$1 ; spremamo da znamo "na čemu smo"
  JMP PomakniPokazivacLijevoDesno

:
  LDA gumbi
  AND #%10000000 ; je li "A" pritisnuto
  BEQ :+
  LDX #$00 ; da znamo "na čemu smo"
  JMP PoljePritisnuto

:
  LDA gumbi
  AND #%01000000 ; je li "B" pritisnuto
  BEQ :+
  LDX #$01 ; da znamo "na čemu smo"
  JMP PoljePritisnuto

:
  LDX #$00
  STX statusGumb ; čistimo zastavicu pritisnutog gumba

KontrolGotovo:
  JMP VRTIPLOCA

UcitajZaPomicanje:
  LDA $0200, X
  RTS

PomakniPokazivacGoreDolje:
  LDA statusGumb
  BEQ :+
  JMP KontrolGotovo

  : LDX #$00 ; spremamo 0 jer sprite ima 4 "atributa" i onaj 1. (počinjemo od 0, znači 0.) je Y pozicija
  JSR UcitajZaPomicanje ; ovo u A sprema samo trenutnu poziciju sprite-a
  CPY #$0 ; usporedi Y s nulom; ako je istina, tj. ako je prisitnuto gore oduzmi 8... u suprotnom oduzmi $F8, tj. dodaj $8 (na isto dođe zbog overflow-a)
  BEQ :++ ; dakle ako je Y jednak 0 (pritisnuto gore), skoči na sljedeću labelu

  SBC #$F8
  PHA ; u stog privremeno spremamo A jer će nam A služiti da saznamo gdje se nalazi pokazivač
  LDA SELposition ; učitaj trenutnu poziciju pokazivača
  CLC ; postavi carry jer ćemo oduzimati
  ADC duljinaPloce ; oduzmi od trenutne pozicije duljinu ploče (pomaknuto je dolje, zbrajamo za duljinu ploče)

  TAY ; spremamo A na sigurno mjesto
  STY brojnik ; poslije ćemo dijeliti polje s ukupnim brojem polja
  LDA visinaPloce
  STA factor1
  LDA duljinaPloce
  STA factor2
  JSR Mnozenje ; koristit ćemo broj ukupan broj polja ploče kod dijeljenja
  LDA factor1
  STA nazivnik
  JSR Division ; ovdje dijelimo
  LDA brojnik
  CMP #$0 ; ako je polje unutar ploče, rezultat dijeljenja uvijek će biti 0
  BEQ :+
  JMP KontrolGotovo

  : TYA

  STA SELposition ; spremi
  STA factor2 ; bitno za Provjera
  PLA ; dobavi iz stoga ono što smo prije spremili (Y poziciju sprite-a koju ćemo spremiti)

  JSR Provjera ; ovdje si gotov
  JMP SpremiKontrol

  ; od tud ispod je ako je stisnuto Up
  : LDA SELposition
  SEC ; postavimo Carry da se "normalno" oduzme
  SBC duljinaPloce
  BCS :+
  JMP KontrolGotovo ; ako "dide" van z memorije, tj. "oko" memorije, znači da smo u 1. retku i da smo gotovi
  :
  JSR UcitajZaPomicanje ; koristili smo A kod usporedbe i potrebno je opet učitati lokaciju
  SEC
  SBC #$08 ; pomakni pokazivač gore, tj. oduzmi 8
  TAY ; u Y privremeno spremamo A jer će nam A služiti da saznamo gdje se nalazi pokazivač
  LDA SELposition ; učitaj trenutnu poziciju pokazivača
  SEC ; očisti carry jer ćemo zbrajati
  SBC duljinaPloce ; dodaj duljinu ploče trenutnoj poziciji (pomaknuto je dolje, dodajemo za duljinu ploče)
  STA SELposition ; spremi
  STA factor2
  TYA ; dobavi iz Y ono što smo prije spremili (Y poziciju sprite-a koju ćemo spremiti)

  JSR Provjera ; gotovo
  JMP SpremiKontrol

PomakniPokazivacLijevoDesno:
  LDA statusGumb
  BEQ :+
  JMP KontrolGotovo ; ove 3 linije služe da se izbjegne "držanje" gumba, tj. da se to izvrši samo jednom po pritisku

  : LDX #$03 ; spremamo 3 jer sprite ima 4 "atributa" i onaj 4. (počinjemo od 0, znači 3.) je X pozicija
  JSR UcitajZaPomicanje ; ovo u A sprema samo trenutnu poziciju sprite-a
  CPY #$0 ; usporedi Y s nulom; ako je istina, tj. ako je prisitnuto lijevo oduzmi 8... u suprotnom oduzmi $F8, tj. dodaj $8 (na isto dođe zbog overflow-a)
  BEQ :+ ; dakle ako je Y jednak 0 (pritisnuto lijevo), skoči na sljedeću labelu

  INY ; inkrementiraj Y (nakon inkrementacije, Y je 2)
  CPY naRubu ; usporedi Y s naRubu (ako je jednako, tj. naRubu je 2, znači da smo na desnom rubu i izvršavanje je gotovo)
  BEQ KontrolGotovo
  SEC ; usporedba je "zmrdala" carry, pa ga moramo opet postaviti jer oduzimamo
  SBC #$F8
  TAY ; spremi A u Y da mozemo SELposition prebaciti u factor2 radi provjere
  INC SELposition ; povećaj brojač za 1 jer je pomaknuto udesno, tj. za 1 više
  LDA SELposition
  STA factor2
  TYA ; pribavi A iz Y da se vratimo u prvobitno stanje

  JSR Provjera ; ovdje si gotov
  JMP SpremiKontrol

  : INY ; inkrementiraj Y (nakon inkrementacije, Y je 1)
  CPY naRubu ; usporedi Y s naRubu (ako je jednako, tj. naRubu je 1, znači da smo na lijevom rubu i izvršavanje je gotovo)
  BNE :+
  JMP KontrolGotovo
  :
  SEC ; usporedba je "zmrdala" carry, pa ga moramo opet postaviti jer oduzimamo
  SBC #$08 ; pomakni pokazivač ulijevo, tj. oduzmi 8
  TAY ; spremi A u Y da možemo SELposition prebaciti u factor2 radi provjere
  DEC SELposition ; smanji brojač za 1
  LDA SELposition
  STA factor2
  TYA

  JSR Provjera

; TU NIŠTA PISATI, TREBA SKOČITI NA SPREMIKONTROL

SpremiKontrol:
  LDX $0F
  TYA ; dohvaćamo prije-spremljene "varijable"

  STA $0200, X ; u A je spremljena pozicija sprite-a a u X broj "atributa" sprite-a (ili 0 ili 3; Y ili X)
  INC statusGumb
  JMP KontrolGotovo

PoljePritisnuto:
  .include "./polja.asm"

_ploca:
  .incbin "./datoteke/prazna_ploca.nam"

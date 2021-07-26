Random: ; koristi A, temp_ran, Gtimer, rand_l
; NIJE MOJE; http://forums.nesdev.com/viewtopic.php?t=491
  ; returns a random number in A
  ; See "linear-congruential random number generator" for more.
  ; rand = (rand * 5 + 0x3611) & 0xffff;
  ; return (rand >> 8) & 0xff;
  LDA Gtimer      ; multiply by 5
  STA temp_ran
  LDA rand_l
  ASL A           ; rand = rand * 4 + rand
  ROL temp_ran
  ASL A
  ROL temp_ran
  CLC
  ADC rand_l
  PHA
  LDA temp_ran
  ADC Gtimer
  STA Gtimer
  PLA               ; rand = rand + 0x3611
  CLC
  ADC #$11
  STA rand_l
  LDA Gtimer
  ADC #$36
  STA Gtimer
  RTS               ; return high 8 bits

Division: ; koristi A, X, brojnik
; NIJE MOJE; http://6502org.wikidot.com/software-math-intdiv
  LDA #0
  LDX #8
  ASL brojnik
: ROL A
  CMP nazivnik
  BCC :+
  SBC nazivnik
: ROL brojnik
  DEX
  BNE :--
  RTS
   ; brojnik = rezultat; A = ostatak

Mnozenje: ; koristi A, X
; NIJE MOJE; https://www.lysator.liu.se/~nisse/misc/6502-mul.html
  LDA #0
  LDX #$8
  LSR factor1
:
  BCC :+
  CLC
  ADC factor2
:
  ROR A
  ROR factor1
  DEX
  BNE :--
  STA factor2
  RTS
   ; factor2 = veći bitovi; factor1 = niži bitovi

Provjera: ; provjeravamo (samo ovdje, do prve labele) ako smo na lijevom rubu ploče
  STX $0F
  TAY ; u ove 2 linije spremamo X u $0F i A u Y da poslije možemo to dobaviti jer ćemo u ovom dijelu (provjeri) koristiti te "varijable"

  LDA #$0
  STA naRubu ; resetiramo ako smo naRubu jer po "defolu" nismo

  LDA factor2
  STA brojnik ; u brojnik spremi trenutnu poziciju pokazivača
  LDA duljinaPloce
  STA nazivnik ; u nazivnik spremi duljinu ploče
  JSR Division ; podijeli i u brojnik dobij rezultat dijeljenja, a u A ostatak

  CMP #$0 ; ako je ostatak pri dijeljenju 0, znači da smo na rubu ploče
  BNE :+ ; ako nismo na rubu ploče, tj. ako ostatak pri dijeljenju nije 0, skoči na sljedeću labelu (desni rub ploče)
  LDA #$1
  STA naRubu
  RTS

: ; DESNI rub ploče
  LDA factor2
  CLC
  ADC #$1 ; dodajemo 1 jer ćemo opet dijeliti i provjeravati ostatak i ako prije nije bilo na lijevom rubu i ako dodamo 1 onda je možda na desnom rubu
  STA brojnik
  JSR Division ; nazivnik je već od prije definiran (duljinaPloce)
  CMP #$0 ; ako je ostatak 0, na rubu smo ploče
  BEQ :+
  RTS
  : LDA #$2
  STA naRubu

  RTS

CitajPolje:
; ULAZ: A kao broj polja ; IZLAZ: A kao vrijednost tog polja na ploči
  STA brojnik
  LDA #$2
  STA nazivnik
  JSR Division
  ; u ovom trenutku A=[broj polja]%2, brojnik=[broj polja]/2
  CMP #$0 ; ako je ostatak pri dijeljenju 0, učitat ćeš prva 4 bita
  BEQ :+
  LDA brojnik
  TAY
  LDA #%00001111
  AND $10, Y
  RTS

: LDA brojnik ; ucitavamo prva 4 bita
  TAY ; u Y spremi mem. lokaciju polja (to je spremljeno u "brojnik")
  LDA #%11110000
  AND $10, Y
  LSR A
  LSR A
  LSR A
  LSR A
  RTS

ZapisiPolje:
; ULAZ: A kao broj polja, X kao što se upisuje u polje
  TAY
  TXA
  PHA
  TYA ; želimo u stog staviti vrijednost X pa te 4 naredbe nam služe za to
  ; u ovom trenutku A=broj polja, X=što se upisuje, Y=A, stog=što se upisuje
  STA brojnik
  TXA
  TAY ; u Y spremamo vrijednost X da se ne pogubi jer ćemo dijeliti a ne postoji TXY pa moramo TXA i TAY
  LDA #$2
  STA nazivnik
  JSR Division
  ; u ovom trenutku brojnik=[broj polja]/2; A=[broj polja]%2; Y=što se upisuje; X=neko smeće (nije korisno jer Division koristi X)
  TAX ; prebacujemo A u X jer će nam A služiti za shiftanje bitova ulijevo
  CPX #$0 ; budući da X već ima vrijednost A, možemo samo usporediti X ..... ispitamo je li ostatak pri dijeljenju 0 ili 1 (ako ćemo koristiti prva 4 bitova u memoriji ili zadnja 4)
  BEQ Zadnja4 ; ako je ostatak pri dijeljenju 0, spremil buš zadnja 4 bitova
  TYA ; u Zadnja4 smo već prebacili Y u A ali što ako je ostatak 1? moramo onda tu naknadno prebaciti
  JMP Spremi

Zadnja4:
  TYA ; u Y je što se upisuje i prebaci u A da možemo shiftati
  ASL A
  ASL A
  ASL A
  ASL A ; pomakni/shiftaj ulijevo tih 4 bitova

; TU NIŠTA PISATI, TREBA ITI NA SPREMI

Spremi:
  ; u ovom trenutku A=ono što se završno upisuje (shiftani ili neshiftani bitovi); brojnik=mem. lokacija kam se upisuje; Y=ono što se upisuje (nemodificirano); X=[broj polja]%2
  CPX #$0 ; opet ispitamo ostatak pri dijeljenju (ako mijenjamo "lijevi" ili "desni" dio 8bitnog polja memorije)
  BEQ ObrisiZadnja4
  TAX
  LDA #%11110000 ; da ne obrišemo već prije zapisana polja, radit ćemo AND pa zato tak definiramo to

ObrisiNeZapisi:
  LDY brojnik ; u Y spremi mem. lokaciju kamo želimo zapisati
  AND $10, Y ; napravi AND akumulatora i kamo želimo zapisati (da u A dobimo kako izgleda to 8bitno polje ako su prva/zadnja 4 bitova nule) i da napokon moremo napraviti OR
  STA $10, Y ; spremamo A gdjegod jer ćemo poslije trebati to a u međuvremenu će nam se A pogubiti
  JMP ZavrsnoSpremi

ObrisiZadnja4:
  TAX
  LDA #%00001111 ; da ne obrišemo već prije zapisana polja, radit ćemo AND
  JMP ObrisiNeZapisi

ZavrsnoSpremi:
  ; u ovom trentku A=kako izgleda to 8bitno polje ako su prva/zadnja 4 bitova nule, X=ono što se završno upisuje (shiftani ili neshiftani bitovi), Y=mem. lokacija kam se upisuje
  TXA
  ORA $10, Y ; napokon napravi taj OR (da dobimo kako bi to 8bitno polje izgledalo s prijespremljenim vrijednostima i sada s novom vrijednošću)
  STA $10, Y ; spremi "tam de si ga našel"

  PLA ; iz stoga uzmi A, tj. ono što je na ulazu bilo X (ono što se upisuje)
  TAX ; prebaci u X da možemo to ponovno koristiti ako želimo
  RTS

DobijLokacijuPolja:
; ULAZ: A kao broj polja ; IZLAZ: factor1 kao LSB polja, factor2 kao MSB polja
  STA brojnik
  LDA duljinaPloce
  STA nazivnik
  JSR Division ; u brojnik dobijemo broj retka na kojem se nalazi odabrano a u A ostatak
  TAX ; spremamo ostatak u X da se ne pogubi
  LDA #$20 ; 1. nazivna tablica počinje od $2000
  STA factor1
  LDA pocetakPloce
  STA factor2 ; na kraju bude MSB factor1 a LSB factor2 ($00E0 je najlijevija pločica odmah ispod crte (ispod "vrijeme" i "mine"))
  LDY #$00 ; brojač postavljamo na 0
  :
  CPY brojnik
  BEQ ToJeTajRed
  LDA #$20 ; dodat ćemo $20 jer je to red ispod
  CLC ; čistimo carry jer ćemo dodavati
  ADC factor2
  BCC :+ ; ako je dodano, spremi i povećaj brojač, inače (...)
  INC factor1 ; (...) povećaj MSB za 1 jer smo isli npr. $00E0->$0100 (da ne povećamo factor1 bilo bi $00E0->$0000)
  : STA factor2
  INY
  JMP :--

ToJeTajRed:
  TXA ; u X smo spremili broj "stupca" gdje se nalazi polje
  CLC
  ADC factor2 ; dodajemo broj "stupca" mem. lokaciji da dobijemo konačnu lokaciju polja na ekranu
  STA factor2

  RTS

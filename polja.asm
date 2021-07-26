LDA statusGumb
BEQ :+
JMP KontrolGotovo ; ove 3 linije služe za sprječavanje "držanja" gumba, tj. da se gumb na kontroleru može samo jednom pritisnuti

: CPX #$01
BNE :+ ; ako X nije jednak 1, pritisnuto je A pa idi na dio koji se odnosi za polje (...)
JMP ManipulirajZastavicama ; (...) u suprotnom idi na dio koji se odnosi na manipuliranje zastavicama

: LDA #$0
CMP MinebrojacGen
BNE :+ ; ako MinebrojacGen nije jednak 0, izgeneriraj ploču
JMP AktivirajPolje ; ako si ovdje, onda nisi skočio na generiranje pa si sad gotov i skoči van s toga

: .include "generator.asm"

AktivirajPolje:
  LDA SELposition
  JSR DobijLokacijuPolja

  LDA #$00
  STA $2001 ; moramo ovo očistiti da možemo učitati pozadinu
  LDA $2002
  LDA factor1
  STA $2006 ; učitavamo MSB u $2006
  LDA factor2
  STA $2006 ; učitavamo LSB u $2006
  LDA $2007
  LDA $2007 ; čitamo što se nalazi na ekranu na trenutnom polju

  CMP #$4A
  BEQ :+ ; ako se nalaziš gdje je zastavica, ne radi ništa

  LDA factor1
  STA $2006 ; učitavamo MSB u $2006
  LDA factor2
  STA $2006 ; učitavamo LSB u $2006

  LDA SELposition
  JSR CitajPolje
  CLC
  ADC #$1F ; dodajemo $1F jer je pozadinske pločice za označavanje mine počinju od $1F
  STA $2007

  : JSR Inic_pozadine
  INC statusGumb

  LDA SELposition
  JSR CitajPolje
  CMP #$9
  BEQ IgraGotovaMina

  JMP KontrolGotovo

ManipulirajZastavicama:
  LDA SELposition
  JSR DobijLokacijuPolja

  LDA $2002
  LDA factor1
  STA $2006 ; učitavamo MSB u $2006
  LDA factor2
  STA $2006 ; učitavamo LSB u $2006
  LDA $2007
  LDA $2007 ; moramo 2 put učitati $2007

  CMP #$4C
  BNE :+ ; ako je pritisnuto da želimo staviti zastavicu na neko polje koje NIJE "prazno", idi na anonimnu labelu

  LDA #$4A
  TAX ; spremi u X
  JMP :++
  :
  CMP #$4A
  BNE :++ ; ako je pritisnuto da želimo staviti zastavicu na neko polje koje NIJE "zastavica", idi na anonimnu labelu, tj. gotov si

  LDA #$4C
  TAX ; spremi u X

  :
  LDA $2002
  LDA factor1
  STA $2006 ; učitavamo MSB u $2006
  LDA factor2
  STA $2006 ; učitavamo LSB u $2006
  TXA
  STA $2007

  : JSR Inic_pozadine

  INC statusGumb
  JMP KontrolGotovo

IgraGotovaMina:
  
  JMP KontrolGotovo

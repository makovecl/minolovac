;---1. KORAK---;
InicijalizirajPlocu:
  LDA visinaPloce
  STA factor1
  LDA duljinaPloce
  STA factor2
  JSR Mnozenje ; koristit ćemo broj polja ploče poslije kod izračuna

  LDA factor1
  LDX #$A
  JSR ZapisiPolje ; zapisujemo kraj ploče

Pisanje:
  LDA SELposition
  LDX #$F ; u X spremamo $F jer je to "sigurno polje", tj. oznaka da se na tom polju ne smiju nalaziti mine
  JSR ZapisiPolje ; označi inicijalno, kliknuto polje kao "sigurno"... (već smo na 1/9 svih okružujućih polja, jupi)

GoreLijevo:
  LDA naRubu
  CMP #$1
  BEQ GoreIznad ; ako je na lijevom rubu, znaci da "gore lijevo" ne postoji, pa skoci na "gore iznad"
  ; ;;;;;
  LDA SELposition
  CLC ; ocistimo Carry kaj se oduzme za 1 više (trenutna pozicija - duljina ploce - 1 [gore lijevo a ne gore iznad])
  SBC duljinaPloce
  BCC GoreIznad ; ako je carry clear, skoci na GoreIznad (nemoj to zapisivati jer je to polje izvan ploče jer si napravio overflow)
  JSR ZapisiPolje ; X je već definiran, nema potrebe ponov(n)o ga definirati

GoreIznad:
  LDA SELposition
  SEC ; postavimo Carry da se "normalno" oduzme (oduzima se za duljinu polja -> dobije se polje iznad odabranog)
  SBC duljinaPloce
  BCC GoreDesno ; ako "dide" van z memorije, tj. "oko" memorije, nemoj zapisivati
  JSR ZapisiPolje

GoreDesno:
  LDA naRubu
  CMP #$2
  BEQ PLijevo ; ako je na desnom rubu, znaci da "gore desno" ne postoji pa skoci na "lijevo"
  ; ;;;;;
  LDA SELposition
  ADC #$1 ; trenutnoj poziciji dodajemo 1 (znaci udesno) i oduzmemo normalno kao "gore iznad" i dobijemo gore desno
  SEC
  SBC duljinaPloce
  BCC PLijevo ; ako je doslo izvan ploce, skoci na "lijevo"
  JSR ZapisiPolje

PLijevo: ; (Ploca Lijevo)
  LDA naRubu
  CMP #$1
  BEQ PDesno ; na lijevom rubu polje lijevo ne postoji
  ; ;;;;;
  LDA SELposition
  SEC
  SBC #$1
  BCC PDesno ; ako je doslo izvan ploce, skoci na "desno"
  JSR ZapisiPolje
  JMP PDesno ; moramo skočiti na PDesno jer je tu subrutina koju trenutno ne trebamo

JesmoLiIzvanMemorijeDijeljenje: ; ovaj dio koda koristimo nekoliko puta u ovih sljedećih redaka pa je bolje da samo pozovemo tu rutinu nego da uvijek pišemo te linije
  TAY ; spremi lokaciju polja (gdje je "sigurno") u Y da se ne pogubi (u dijeljenju koristimo A)
  STA brojnik ; trenutno je u A spremljena lokacija polja za koju želimo saznati je li izvan ploče
  LDA factor1 ; ovdje je spremljen ukupan broj polja na ploči (prije smo to pomnožili)
  STA nazivnik
  JSR Division ; podijeli koje-god-već-polje s ukupnim brojem polja na ploči
  LDA brojnik
  CMP #$0 ; ako smo unutar ploče, rezultat dijeljenja (mem. lokacija "brojnik") će uvijek biti 0 (0 cijela nešto)
  RTS

PribaviApaZapisiXiOndaZapisi: ; isto kao ovo gore, koristimo više puta pa da ne trošimo memoriju napravimo subrutinu
  TYA ; u Y smo spremili A od prije jer smo A koristili za dijeljenje
  LDX #$F ; opet definiramo da je X "sigurno polje" jer smo to koristili za dijeljenje
  JSR ZapisiPolje
  RTS

PDesno:
  LDA naRubu
  CMP #$2
  BEQ DoljeLijevo ; ako je na desnom rubu, skoci na DoljeLijevo
  ; ;;;;;
  LDA SELposition
  CLC
  ADC #$1 ; normalno dodaj 1 polju jer je desno (za 1 više)
  JSR JesmoLiIzvanMemorijeDijeljenje
  BNE DoljeLijevo ; ako rezultat nije 0, skoci na DoljeLijevo jer je izvan memorije, tj. izvan polja
  JSR PribaviApaZapisiXiOndaZapisi

DoljeLijevo:
  LDA naRubu
  CMP #$1
  BEQ DoljeIspod ; ako smo na lijevom rubu, dolje-lijevo ne postoji
  ; ;;;;;
  LDA SELposition
  CLC
  ADC duljinaPloce
  ADC #$FF ; smanjujemo trenutnu lokaciju za 1 (dodajemo $FF [ako dodajemo $0 dobimo taj broj ako dodajemo $FF trebamo dobiti za jedan manje.. kak bi ga inace dobili]) jer smo prije dobili "dolje-ispod", a ako smanjimo za 1 dobijemo "dolje-lijevo"
  JSR JesmoLiIzvanMemorijeDijeljenje
  BNE DoljeIspod ; u subrutini smo napravili usporedbu (vidi tu subrutinu) i ako nije jednako 0, skoci na sljedece jer je izvan memorije, tj. izvan polja
  JSR PribaviApaZapisiXiOndaZapisi

DoljeIspod:
  LDA SELposition
  CLC
  ADC duljinaPloce
  JSR JesmoLiIzvanMemorijeDijeljenje
  BNE DoljeDesno ; u subrutini smo napravili usporedbu (vidi tu subrutinu) i ako nije jednako 0, skoci na sljedece jer je izvan memorije, tj. izvan polja
  JSR PribaviApaZapisiXiOndaZapisi

DoljeDesno:
  LDA naRubu
  CMP #$2
  BEQ :+ ; dolje-desno ne postoji ako smo na desnom rubu pa smo gotovi sa svim susjednim poljima
  ; ;;;;;
  LDA SELposition
  SEC
  ADC duljinaPloce ; postavili smo carry prije jer želimo dodati za 1 više (inače bi bilo dolje-ispod a ako dodamo za 1 više je dolje-desno)
  JSR JesmoLiIzvanMemorijeDijeljenje
  BNE :+ ; u subrutini smo napravili usporedbu (vidi tu subrutinu) i ako nije jednako 0, skoci na sljedece jer je izvan memorije, tj. izvan polja
  JSR PribaviApaZapisiXiOndaZapisi

; TU NIŠTA PISATI, TREBA ITI NA ANONIMNU LABELU
;---2. KORAK---;
:
  LDA #$FF
  STA factor2 ; resetiramo brojac (u factor2 spremamo koliko mina smo izgenerirali zasad)

Izminiraj:
  JSR Random ; generiramo nasumični broj koji dobimo u A
  JSR JesmoLiIzvanMemorijeDijeljenje ; gledamo je li A izvan ploče
  BNE Izminiraj ; ako je broj iznad veličine polja, opet izgeneriraj neki novi broj

  TYA ; u Y smo prije spremili A i sada ga pribavimo nazad, znači u A je sad (poslije ove naredbe) spremljen nasumični broj
  STA $0F
  JSR CitajPolje
  CMP #$0
  BNE Izminiraj ; ako je polje u koje želiš pisati nešto različito od nule znači da se nešto nalazi na tom polju i opet izgeneriraj neko novo polje

  INC factor2 ; povećaj brojač
  LDA factor2
  CMP MinebrojacGen
  BNE :+ ; ako usporedba od prije nije jednaka (a to i želimo jer to znači da još imamo mine za generiranje) nastavi s "miniranjem"
  JMP :++ ; ako je jednaka (ako prije nisi skočio znači da je jednako i ne možemo više generirati mine) skoči na 3. korak
:
  LDA $0F ; u Y smo prije spremili A i sada ga pribavimo nazad, znači u A je sad (poslije ove naredbe) spremljen nasumični broj
  LDX #$9
  JSR ZapisiPolje
  JMP Izminiraj

;---3. KORAK---;
:
  LDA #$FF ; odma ćemo inkrementirati brojač, a mora početi od 0 pa stavimo na $FF
  STA factor2
SeciSePoPloci:
  LDA #$00
  STA MinebrojacGen ; postavljamo brojač mina na 0

  INC factor2
  JSR Provjera ; provjeri jesmo li na rubu ploče
  LDA factor2 ; u A učitaj brojač jer nam A služi za subrutinu CitajPolje
  JSR CitajPolje
  CMP #$9
  BEQ SeciSePoPloci ; ako je na tom polju mina, povećaj brojač, tj. skoči na SeciSePoPloci

  ;LDA factor2 ; ponovno učitaj brojač, tj. polje jer se u A trenutno nalazi sadržaj pročitanog polja
  ;JSR CitajPolje
  CMP #$A
  BNE :+
  JMP AktivirajPolje ; ako smo došli do kraja ploče, tj. ako si pročitao "A", skoči van s generiranja i gotovi smo
:
  ; ovo ispod učitava gornju lijevu poziciju
  LDA naRubu
  CMP #$1
  BEQ GoreIznadCitaj ; ako je na lijevom rubu, znaci da "gore lijevo" ne postoji, pa skoci na "gore iznad"
  ; ;;;;;
  LDA factor2
  CLC ; ocistimo Carry kaj se oduzme za 1 više (trenutna pozicija - duljina ploce - 1 [gore lijevo a ne gore iznad])
  SBC duljinaPloce
  BCC GoreIznadCitaj ; ako je carry clear, skoci na GoreIznad (nemoj to zapisivati jer je to polje izvan ploče jer si napravio overflow)
  JSR CitajPolje
  CMP #$09
  BNE GoreIznadCitaj
  INC MinebrojacGen

GoreIznadCitaj:
  LDA factor2
  SEC ; postavimo Carry da se "normalno" oduzme (oduzima se za duljinu polja -> dobije se polje iznad odabranog)
  SBC duljinaPloce
  BCC GoreDesnoCitaj ; ako "dide" van z memorije, tj. "oko" memorije, nemoj zapisivati
  JSR CitajPolje
  CMP #$09
  BNE GoreDesnoCitaj
  INC MinebrojacGen

GoreDesnoCitaj:
  LDA naRubu
  CMP #$2
  BEQ PLijevoCitaj ; ako je na desnom rubu, znaci da "gore desno" ne postoji pa skoci na "lijevo"
  ; ;;;;;
  LDA factor2
  ADC #$1 ; trenutnoj poziciji dodajemo 1 (znaci udesno) i oduzmemo normalno kao "gore iznad" i dobijemo gore desno
  SEC
  SBC duljinaPloce
  BCC PLijevoCitaj ; ako je doslo izvan ploce, skoci na "lijevo"
  JSR CitajPolje
  CMP #$09
  BNE PLijevoCitaj
  INC MinebrojacGen

PLijevoCitaj: ; (Ploca Lijevo)
  LDA naRubu
  CMP #$1
  BEQ PDesnoCitaj ; na lijevom rubu polje lijevo ne postoji
  ; ;;;;;
  LDA factor2
  SEC
  SBC #$1
  BCC PDesnoCitaj ; ako je doslo izvan ploce, skoci na "desno"
  JSR CitajPolje
  CMP #$09
  BNE PDesnoCitaj
  INC MinebrojacGen

PDesnoCitaj:
  LDA naRubu
  CMP #$2
  BEQ DoljeLijevoCitaj ; ako je na desnom rubu, skoci na DoljeLijevo
  ; ;;;;;
  LDA factor2
  CLC
  ADC #$1 ; normalno dodaj 1 polju jer je desno (za 1 više)
  JSR JesmoLiIzvanMemorijeDijeljenje
  BNE DoljeLijevoCitaj ; ako rezultat nije 0, skoci na DoljeLijevo jer je izvan memorije, tj. izvan polja
  TYA ; vraćamo A jer smo ga u JesmoLiIzvanMemorijeDijeljenje spremili u Y
  JSR CitajPolje
  CMP #$09
  BNE DoljeLijevoCitaj
  INC MinebrojacGen

DoljeLijevoCitaj:
  LDA naRubu
  CMP #$1
  BEQ DoljeIspodCitaj ; ako smo na lijevom rubu, dolje-lijevo ne postoji
  ; ;;;;;
  LDA factor2
  CLC
  ADC duljinaPloce
  ADC #$FF ; smanjujemo trenutnu lokaciju za 1 (dodajemo $FF [ako dodajemo $0 dobimo taj broj ako dodajemo $FF trebamo dobiti za jedan manje.. kak bi ga inace dobili]) jer smo prije dobili "dolje-ispod", a ako smanjimo za 1 dobijemo "dolje-lijevo"
  JSR JesmoLiIzvanMemorijeDijeljenje
  BNE DoljeIspodCitaj ; u subrutini smo napravili usporedbu (vidi tu subrutinu) i ako nije jednako 0, skoci na sljedece jer je izvan memorije, tj. izvan polja
  TYA
  JSR CitajPolje
  CMP #$09
  BNE DoljeIspodCitaj
  INC MinebrojacGen

DoljeIspodCitaj:
  LDA factor2
  CLC
  ADC duljinaPloce
  JSR JesmoLiIzvanMemorijeDijeljenje
  BNE DoljeDesnoCitaj ; u subrutini smo napravili usporedbu (vidi tu subrutinu) i ako nije jednako 0, skoci na sljedece jer je izvan memorije, tj. izvan polja
  TYA
  JSR CitajPolje
  CMP #$09
  BNE DoljeDesnoCitaj
  INC MinebrojacGen

DoljeDesnoCitaj:
  LDA naRubu
  CMP #$2
  BEQ TreciKorakKraj ; dolje-desno ne postoji ako smo na desnom rubu pa smo gotovi sa svim susjednim poljima
  ; ;;;;;
  LDA factor2
  SEC
  ADC duljinaPloce ; postavili smo carry prije jer želimo dodati za 1 više (inače bi bilo dolje-ispod a ako dodamo za 1 više je dolje-desno)
  JSR JesmoLiIzvanMemorijeDijeljenje
  BNE TreciKorakKraj ; u subrutini smo napravili usporedbu (vidi tu subrutinu) i ako nije jednako 0, skoci na sljedece jer je izvan memorije, tj. izvan polja
  TYA
  JSR CitajPolje
  CMP #$09
  BNE TreciKorakKraj
  INC MinebrojacGen

TreciKorakKraj:
  LDX MinebrojacGen
  LDA factor2
  JSR ZapisiPolje

  JMP SeciSePoPloci

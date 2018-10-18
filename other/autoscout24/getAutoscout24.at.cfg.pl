# debug options for the developer;

$G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{lwp}      = 'lwp';
$G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{httpTiny} = 'httpTiny';
$G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{wwwMech}  = 'wwwMech';

$G_DATA->{downloadMethod} = $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{wwwMech};

$G_DATA->{sendMail}                           = 1;
$G_DATA->{G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC} = 8 * 60;

$G_DATA->{silentHours}->{from} = 20;
$G_DATA->{silentHours}->{till} = 06;

# FIXME: debug
$G_DATA->{mailRecipients} = [ '"Sanyi" <berczi.sandor@gmail.com>' ];
$G_DATA->{mailRecipients} = [ '"Sanyi" <berczi.sandor@gmail.com>', '"Tillatilla1966" <tillatilla.1966@gmail.com>' ];

# ************************************************************
# ************************************************************
# Autoscout
# ************************************************************
{

  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_TALALATI_LISTA} = '//div[contains(concat(" ", @class, " "), " cl-list-element cl-list-element-gap ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_TITLE}          = './/h2[contains(concat(" ", @class, " "), " cldt-summary-makemodel ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_TITLE2}         = './/h2[contains(concat(" ", @class, " "), " cldt-summary-version ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_DESC}           = './/h3[contains(concat(" ", @class, " "), " cldt-summary-subheadline ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_LINK}           = './/div[contains(concat(" ", @class, " "), " cldt-summary-titles ")]/a/@href';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_PRICE}          = './/span[contains(concat(" ", @class, " "), " cldt-price ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_FEATURES}       = './/div[contains(concat(" ", @class, " "), " cldt-summary-vehicle-data ")]/ul/li';
  $G_DATA->{AUTOSCOUT}->{textToDelete}
    = 'Weitere Informationen zum offiziellen Kraftstoffverbrauch und den offiziellen spezifischen CO2-Emissionen neuer Personenkraftwagen können dem "Leitfaden über den Kraftstoffverbrauch, die CO2-Emissionen und den Stromverbrauch neuer Personenkraftwagen" entnommen werden, der an allen Verkaufsstellen und bei der Deutschen Automobil Treuhand GmbH unter www.dat.at unentgeltlich erhältlich ist.';

  # mmvmk0=9&mmvco=1&fregfrom=2013&fregto=2015&pricefrom=0&priceto=8000&fuel=B&kmfrom=10000&powertype=kw&atype=C&ustate=N%2CU&sort=standard&desc=0

  # ustate=N%2CU&     N,U: nem balesetes; A: balesetes;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{pricefrom} = 500;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{priceto}   = 6000;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{sort}      = 'age';
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{desc}      = 0;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{cy}        = 'A,D';    # A: Austria; D: Germany
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{offer}
    = 'D,J,O,S,U';    # D: Vorführfahrzeug, J: Jahreswagen, N: Neu, O: Oldtimer, S: Tageszulassung, U: Gebraucht
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{mmvco}     = 1;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{powertype} = 'kw';
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{atype}     = 'C';
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{ustate}    = 'A,N,U';      #  A: balesetes; N,U: nem balesetes;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{page}      = "VVPAGEVV";
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{size}      = 20;           # size per page

  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Audi}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Citroen}->{maxAge}    = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Fiat}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Ford}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Honda}->{maxAge}      = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Hyundai}->{maxAge}    = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Opel}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{SEAT}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Skoda}->{maxAge}      = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Toyota}->{maxAge}     = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Volkswagen}->{maxAge} = 11;

  $G_DATA->{AUTOSCOUT}->{makers}->{"Audi"}              = 9;
  $G_DATA->{AUTOSCOUT}->{makers}->{"BMW"}               = 13;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Ford"}              = 29;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Mercedes-Benz"}     = 47;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Opel"}              = 54;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Volkswagen"}        = 74;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Abarth"}            = 16396;
  $G_DATA->{AUTOSCOUT}->{makers}->{"AC"}                = 14979;
  $G_DATA->{AUTOSCOUT}->{makers}->{"ACM"}               = 16429;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Acura"}             = 16356;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Aixam"}             = 16352;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Alfa Romeo"}        = 6;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Alpina"}            = 14;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Amphicar"}          = 51545;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Ariel"}             = 16419;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Artega"}            = 16427;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Aspid"}             = 16431;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Aston Martin"}      = 8;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Austin"}            = 15643;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Autobianchi"}       = 15644;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Auverland"}         = 16437;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Baic"}              = 51774;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Bedford"}           = 16400;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Bellier"}           = 16416;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Bentley"}           = 11;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Bollore"}           = 16418;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Borgward"}          = 16424;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Brilliance"}        = 16367;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Bugatti"}           = 15;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Buick"}             = 16;
  $G_DATA->{AUTOSCOUT}->{makers}->{"BYD"}               = 16379;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Cadillac"}          = 17;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Caravans-Wohnm"}    = 15672;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Casalini"}          = 16407;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Caterham"}          = 16335;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Changhe"}           = 16401;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Chatenet"}          = 16357;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Chery"}             = 16384;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Chevrolet"}         = 19;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Chrysler"}          = 20;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Citroen"}           = 21;
  $G_DATA->{AUTOSCOUT}->{makers}->{"CityEL"}            = 16411;
  $G_DATA->{AUTOSCOUT}->{makers}->{"CMC"}               = 16406;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Corvette"}          = 16380;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Courb"}             = 51558;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Dacia"}             = 16360;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Daewoo"}            = 22;
  $G_DATA->{AUTOSCOUT}->{makers}->{"DAF"}               = 16333;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Daihatsu"}          = 23;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Daimler"}           = 16397;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Dangel"}            = 16434;
  $G_DATA->{AUTOSCOUT}->{makers}->{"De la Chapelle"}    = 16423;
  $G_DATA->{AUTOSCOUT}->{makers}->{"De Tomaso"}         = 51779;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Derways"}           = 16391;
  $G_DATA->{AUTOSCOUT}->{makers}->{"DFSK"}              = 51773;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Dodge"}             = 2152;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Donkervoort"}       = 16339;
  $G_DATA->{AUTOSCOUT}->{makers}->{"DR Motor"}          = 16383;
  $G_DATA->{AUTOSCOUT}->{makers}->{"DS Automobiles"}    = 16415;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Dutton"}            = 51552;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Estrima"}           = 16436;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Ferrari"}           = 27;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Fiat"}              = 28;
  $G_DATA->{AUTOSCOUT}->{makers}->{"FISKER"}            = 51543;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Gac Gonow"}         = 51542;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Galloper"}          = 16337;
  $G_DATA->{AUTOSCOUT}->{makers}->{"GAZ"}               = 16386;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Geely"}             = 16392;
  $G_DATA->{AUTOSCOUT}->{makers}->{"GEM"}               = 16403;
  $G_DATA->{AUTOSCOUT}->{makers}->{"GEMBALLA"}          = 51540;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Giotti Victoria"}   = 16421;
  $G_DATA->{AUTOSCOUT}->{makers}->{"GMC"}               = 2153;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Great Wall"}        = 16382;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Grecav"}            = 16409;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Haima"}             = 51512;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Hamann"}            = 51534;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Honda"}             = 31;
  $G_DATA->{AUTOSCOUT}->{makers}->{"HUMMER"}            = 15674;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Hurtan"}            = 51767;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Hyundai"}           = 33;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Infiniti"}          = 16355;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Innocenti"}         = 15629;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Iso Rivolta"}       = 16402;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Isuzu"}             = 35;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Iveco"}             = 14882;
  $G_DATA->{AUTOSCOUT}->{makers}->{"IZH"}               = 16387;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Jaguar"}            = 37;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Jeep"}              = 38;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Karabag"}           = 16417;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Kia"}               = 39;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Koenigsegg"}        = 51781;
  $G_DATA->{AUTOSCOUT}->{makers}->{"KTM"}               = 50060;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Lada"}              = 40;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Lamborghini"}       = 41;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Lancia"}            = 42;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Land Rover"}        = 15641;
  $G_DATA->{AUTOSCOUT}->{makers}->{"LDV"}               = 16426;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Lexus"}             = 43;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Lifan"}             = 16393;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Ligier"}            = 16353;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Lincoln"}           = 14890;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Lotus"}             = 44;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Mahindra"}          = 16359;
  $G_DATA->{AUTOSCOUT}->{makers}->{"MAN"}               = 51780;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Mansory"}           = 16435;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Martin Motors"}     = 16410;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Maserati"}          = 45;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Maybach"}           = 16348;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Mazda"}             = 46;
  $G_DATA->{AUTOSCOUT}->{makers}->{"McLaren"}           = 51519;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Melex"}             = 16399;
  $G_DATA->{AUTOSCOUT}->{makers}->{"MG"}                = 48;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Microcar"}          = 16361;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Minauto"}           = 51766;
  $G_DATA->{AUTOSCOUT}->{makers}->{"MINI"}              = 16338;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Mitsubishi"}        = 50;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Mitsuoka"}          = 51782;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Morgan"}            = 51;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Moskvich"}          = 16388;
  $G_DATA->{AUTOSCOUT}->{makers}->{"MP Lafer"}          = 51554;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Nissan"}            = 52;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Oldsmobile"}        = 53;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Oldtimer"}          = 15670;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Pagani"}            = 16341;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Panther Westwinds"} = 51553;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Peugeot"}           = 55;
  $G_DATA->{AUTOSCOUT}->{makers}->{"PGO"}               = 50083;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Piaggio"}           = 16350;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Plymouth"}          = 51770;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Pontiac"}           = 56;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Porsche"}           = 57;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Proton"}            = 15636;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Puch"}              = 51768;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Qoros"}             = 16412;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Qvale"}             = 16425;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Reliant"}           = 16398;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Renault"}           = 60;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Rolls-Royce"}       = 61;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Rover"}             = 62;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Ruf"}               = 51536;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Saab"}              = 63;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Santana"}           = 16369;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Savel"}             = 16405;
  $G_DATA->{AUTOSCOUT}->{makers}->{"SDG"}               = 51771;
  $G_DATA->{AUTOSCOUT}->{makers}->{"SEAT"}              = 64;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Skoda"}             = 65;
  $G_DATA->{AUTOSCOUT}->{makers}->{"smart"}             = 15525;
  $G_DATA->{AUTOSCOUT}->{makers}->{"SpeedArt"}          = 51538;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Spyker"}            = 16377;
  $G_DATA->{AUTOSCOUT}->{makers}->{"SsangYong"}         = 66;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Subaru"}            = 67;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Suzuki"}            = 68;
  $G_DATA->{AUTOSCOUT}->{makers}->{"TagAZ"}             = 16395;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Talbot"}            = 51551;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Tasso"}             = 16404;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Tata"}              = 16327;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Tazzari EV"}        = 51557;
  $G_DATA->{AUTOSCOUT}->{makers}->{"TECHART"}           = 51535;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Tesla"}             = 51520;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Town Life"}         = 16420;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Toyota"}            = 70;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Trabant"}           = 15633;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Trailer-Anhaenger"} = 16326;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Triumph"}           = 2120;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Trucks-Lkw"}        = 16253;
  $G_DATA->{AUTOSCOUT}->{makers}->{"TVR"}               = 71;
  $G_DATA->{AUTOSCOUT}->{makers}->{"UAZ"}               = 16389;
  $G_DATA->{AUTOSCOUT}->{makers}->{"VAZ"}               = 16385;
  $G_DATA->{AUTOSCOUT}->{makers}->{"VEM"}               = 16422;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Volvo"}             = 73;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Vortex"}            = 51514;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Wallys"}            = 51776;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Wartburg"}          = 16336;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Westfield"}         = 51513;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Wiesmann"}          = 16351;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Zastava"}           = 16408;
  $G_DATA->{AUTOSCOUT}->{makers}->{"ZAZ"}               = 16394;
  $G_DATA->{AUTOSCOUT}->{makers}->{"Sonstige"}          = 16328;
}

# WillDasHaben
{
  # FIXME
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_TALALATI_LISTA} = '//div[contains(concat(" ", @class, " "), " cl-list-element cl-list-element-gap ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_TITLE}          = './/h2[contains(concat(" ", @class, " "), " cldt-summary-makemodel ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_TITLE2}         = './/h2[contains(concat(" ", @class, " "), " cldt-summary-version ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_DESC}           = './/h3[contains(concat(" ", @class, " "), " cldt-summary-subheadline ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_LINK}           = './/div[contains(concat(" ", @class, " "), " cldt-summary-titles ")]/a/@href';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_PRICE}          = './/span[contains(concat(" ", @class, " "), " cldt-price ")]';
  $G_DATA->{AUTOSCOUT}->{XPATHS}->{XPATH_FEATURES}       = './/div[contains(concat(" ", @class, " "), " cldt-summary-vehicle-data ")]/ul/li';
  $G_DATA->{AUTOSCOUT}->{textToDelete}
    = 'Weitere Informationen zum offiziellen Kraftstoffverbrauch und den offiziellen spezifischen CO2-Emissionen neuer Personenkraftwagen können dem "Leitfaden über den Kraftstoffverbrauch, die CO2-Emissionen und den Stromverbrauch neuer Personenkraftwagen" entnommen werden, der an allen Verkaufsstellen und bei der Deutschen Automobil Treuhand GmbH unter www.dat.at unentgeltlich erhältlich ist.';

  # mmvmk0=9&mmvco=1&fregfrom=2013&fregto=2015&pricefrom=0&priceto=8000&fuel=B&kmfrom=10000&powertype=kw&atype=C&ustate=N%2CU&sort=standard&desc=0

  # https://www.willhaben.at/iad/gebrauchtwagen/auto/gebrauchtwagenboerse?CAR_MODEL/MAKE=1005&PRICE_TO=12340&YEAR_MODEL_FROM=2011
  # https://www.willhaben.at/iad/gebrauchtwagen/auto/gebrauchtwagenboerse?
  # CAR_MODEL/MAKE=1005&PRICE_FROM=12340&PRICE_TO=12340&YEAR_MODEL_FROM=2011

  # ustate=N%2CU&     N,U: nem balesetes; A: balesetes;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{pricefrom} = 500;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{priceto}   = 6000;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{sort}      = 'age';
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{desc}      = 0;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{cy}        = 'A,D';    # A: Austria; D: Germany
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{offer}
    = 'D,J,O,S,U';    # D: Vorführfahrzeug, J: Jahreswagen, N: Neu, O: Oldtimer, S: Tageszulassung, U: Gebraucht
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{mmvco}     = 1;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{powertype} = 'kw';
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{atype}     = 'C';
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{ustate}    = 'A,N,U';      #  A: balesetes; N,U: nem balesetes;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{page}      = "VVPAGEVV";
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{defaults}->{size}      = 20;           # size per page

  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Audi}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Citroen}->{maxAge}    = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Fiat}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Ford}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Honda}->{maxAge}      = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Hyundai}->{maxAge}    = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Opel}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{SEAT}->{maxAge}       = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Skoda}->{maxAge}      = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Toyota}->{maxAge}     = 11;
  $G_DATA->{AUTOSCOUT}->{searchConfig}->{mmvmk0}->{Volkswagen}->{maxAge} = 11;


  $G_DATA->{WillDasHaben}->{makers}->{"Alfa Romeo"}         = 1000;
  $G_DATA->{WillDasHaben}->{makers}->{"Caterham"}           = 10001;
  $G_DATA->{WillDasHaben}->{makers}->{"Tata"}               = 10002;
  $G_DATA->{WillDasHaben}->{makers}->{"Mahindra"}           = 10003;
  $G_DATA->{WillDasHaben}->{makers}->{"Abarth"}             = 10004;
  $G_DATA->{WillDasHaben}->{makers}->{"KTM"}                = 10005;
  $G_DATA->{WillDasHaben}->{makers}->{"Think"}              = 10007;
  $G_DATA->{WillDasHaben}->{makers}->{"Tesla"}              = 10008;
  $G_DATA->{WillDasHaben}->{makers}->{"Infiniti"}           = 10009;
  $G_DATA->{WillDasHaben}->{makers}->{"Tazzari"}            = 10010;
  $G_DATA->{WillDasHaben}->{makers}->{"Aixam"}              = 10012;
  $G_DATA->{WillDasHaben}->{makers}->{"Microcar"}           = 10013;
  $G_DATA->{WillDasHaben}->{makers}->{"Ligier"}             = 10014;
  $G_DATA->{WillDasHaben}->{makers}->{"Triumph"}            = 10015;
  $G_DATA->{WillDasHaben}->{makers}->{"Graf Carello"}       = 10016;
  $G_DATA->{WillDasHaben}->{makers}->{"Casalini"}           = 10017;
  $G_DATA->{WillDasHaben}->{makers}->{"Corvette"}           = 10018;
  $G_DATA->{WillDasHaben}->{makers}->{"DS Automobiles"}     = 10019;
  $G_DATA->{WillDasHaben}->{makers}->{"Aston Martin"}       = 1002;
  $G_DATA->{WillDasHaben}->{makers}->{"McLaren"}            = 10020;
  $G_DATA->{WillDasHaben}->{makers}->{"Audi"}               = 1003;
  $G_DATA->{WillDasHaben}->{makers}->{"Bentley"}            = 1004;
  $G_DATA->{WillDasHaben}->{makers}->{"BMW"}                = 1005;
  $G_DATA->{WillDasHaben}->{makers}->{"Buick"}              = 1006;
  $G_DATA->{WillDasHaben}->{makers}->{"Cadillac"}           = 1007;
  $G_DATA->{WillDasHaben}->{makers}->{"Chevrolet"}          = 1008;
  $G_DATA->{WillDasHaben}->{makers}->{"Chrysler"}           = 1009;
  $G_DATA->{WillDasHaben}->{makers}->{"Citroën"}            = 1010;
  $G_DATA->{WillDasHaben}->{makers}->{"Dacia"}              = 1011;
  $G_DATA->{WillDasHaben}->{makers}->{"Chevrolet / Daewoo"} = 1012;
  $G_DATA->{WillDasHaben}->{makers}->{"Daihatsu"}           = 1013;
  $G_DATA->{WillDasHaben}->{makers}->{"Dodge"}              = 1014;
  $G_DATA->{WillDasHaben}->{makers}->{"Ferrari"}            = 1015;
  $G_DATA->{WillDasHaben}->{makers}->{"Fiat"}               = 1016;
  $G_DATA->{WillDasHaben}->{makers}->{"Ford"}               = 1017;
  $G_DATA->{WillDasHaben}->{makers}->{"Honda"}              = 1018;
  $G_DATA->{WillDasHaben}->{makers}->{"Hummer"}             = 1019;
  $G_DATA->{WillDasHaben}->{makers}->{"Hyundai"}            = 1020;
  $G_DATA->{WillDasHaben}->{makers}->{"Isuzu"}              = 1021;
  $G_DATA->{WillDasHaben}->{makers}->{"IVECO"}              = 1022;
  $G_DATA->{WillDasHaben}->{makers}->{"Jaguar"}             = 1023;
  $G_DATA->{WillDasHaben}->{makers}->{"Jeep"}               = 1024;
  $G_DATA->{WillDasHaben}->{makers}->{"KIA"}                = 1025;
  $G_DATA->{WillDasHaben}->{makers}->{"Lada"}               = 1026;
  $G_DATA->{WillDasHaben}->{makers}->{"Lamborghini"}        = 1027;
  $G_DATA->{WillDasHaben}->{makers}->{"Lancia"}             = 1028;
  $G_DATA->{WillDasHaben}->{makers}->{"Land Rover"}         = 1029;
  $G_DATA->{WillDasHaben}->{makers}->{"Lexus"}              = 1030;
  $G_DATA->{WillDasHaben}->{makers}->{"Lincoln"}            = 1031;
  $G_DATA->{WillDasHaben}->{makers}->{"Lotus"}              = 1032;
  $G_DATA->{WillDasHaben}->{makers}->{"Maserati"}           = 1033;
  $G_DATA->{WillDasHaben}->{makers}->{"Maybach"}            = 1034;
  $G_DATA->{WillDasHaben}->{makers}->{"Mazda"}              = 1035;
  $G_DATA->{WillDasHaben}->{makers}->{"Mercedes-Benz"}      = 1036;
  $G_DATA->{WillDasHaben}->{makers}->{"Mercury"}            = 1037;
  $G_DATA->{WillDasHaben}->{makers}->{"MG"}                 = 1038;
  $G_DATA->{WillDasHaben}->{makers}->{"MINI"}               = 1039;
  $G_DATA->{WillDasHaben}->{makers}->{"Mitsubishi"}         = 1040;
  $G_DATA->{WillDasHaben}->{makers}->{"Morgan"}             = 1041;
  $G_DATA->{WillDasHaben}->{makers}->{"Nissan"}             = 1042;
  $G_DATA->{WillDasHaben}->{makers}->{"Opel"}               = 1043;
  $G_DATA->{WillDasHaben}->{makers}->{"Peugeot"}            = 1045;
  $G_DATA->{WillDasHaben}->{makers}->{"Pontiac"}            = 1047;
  $G_DATA->{WillDasHaben}->{makers}->{"Porsche"}            = 1048;
  $G_DATA->{WillDasHaben}->{makers}->{"Puch"}               = 1049;
  $G_DATA->{WillDasHaben}->{makers}->{"Renault"}            = 1051;
  $G_DATA->{WillDasHaben}->{makers}->{"Rolls-Royce"}        = 1052;
  $G_DATA->{WillDasHaben}->{makers}->{"Rover"}              = 1053;
  $G_DATA->{WillDasHaben}->{makers}->{"Saab"}               = 1054;
  $G_DATA->{WillDasHaben}->{makers}->{"Seat"}               = 1056;
  $G_DATA->{WillDasHaben}->{makers}->{"Skoda"}              = 1057;
  $G_DATA->{WillDasHaben}->{makers}->{"Smart"}              = 1058;
  $G_DATA->{WillDasHaben}->{makers}->{"SsangYong"}          = 1059;
  $G_DATA->{WillDasHaben}->{makers}->{"Subaru"}             = 1060;
  $G_DATA->{WillDasHaben}->{makers}->{"Suzuki"}             = 1061;
  $G_DATA->{WillDasHaben}->{makers}->{"Toyota"}             = 1062;
  $G_DATA->{WillDasHaben}->{makers}->{"Volvo"}              = 1064;
  $G_DATA->{WillDasHaben}->{makers}->{"VW"}                 = 1065;
  $G_DATA->{WillDasHaben}->{makers}->{"Wiesmann"}           = 1066;
  $G_DATA->{WillDasHaben}->{makers}->{"British Leyland"}    = 1069;
  $G_DATA->{WillDasHaben}->{makers}->{"Talbot"}             = 1073;
  $G_DATA->{WillDasHaben}->{makers}->{"Austin"}             = 1734;
  $G_DATA->{WillDasHaben}->{makers}->{"Sonstige"}           = 9999;
}

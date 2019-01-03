# debug options for the developer;

my $default_maxAge = 11;

my $default_price_from = 500;
my $default_price_to   = 6000;
my $default_year_from  = 2011;

$G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{lwp}      = 'lwp';
$G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{httpTiny} = 'httpTiny';
$G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{wwwMech}  = 'wwwMech';

$G_DATA->{downloadMethod} = $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{wwwMech};

$G_DATA->{mail}->{sendMail}                   = 1;
$G_DATA->{mail}->{itemsInAMailMax}            = 1000;
$G_DATA->{G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC} = 8 * 60;

$G_DATA->{silentHours}->{from} = 20;
$G_DATA->{silentHours}->{till} = 06;

$G_DATA->{mailRecipientsDebug} = [ '"Sanyi" <berczi.sandor@gmail.com>' ];
$G_DATA->{mailRecipients} = [ '"Sanyi" <berczi.sandor@gmail.com>', '"Tillatilla1966" <tillatilla.1966@gmail.com>' ];

# FIXME: debug
# $G_DATA->{G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC} = 100;
# $G_DATA->{sendMail}       = 1;
# $G_DATA->{mailRecipients} = [ '"Sanyi" <berczi.sandor@gmail.com>' ];
# $default_price_from       = 550;
# $default_price_to         = 550;                                       # FIXME

# WillHaben
{
  $G_DATA->{sites}->{willHaben}->{searchUrlRoot} = 'https://www.willhaben.at/iad/gebrauchtwagen/auto/gebrauchtwagenboerse?';

  #  '//*[@id="main_nagyoldal_felcserelve"]//div[contains(concat(" ", @class, " "), " talalati_lista ")]';
  # list: //*[@id="resultlist"]

  # item: //*[@id="resultlist"]/article[2]
  #   item: <article itemscope="" itemtype="http://schema.org/Product" class="search-result-entry  ">

  # title: //*[@id="resultlist"]/article[2]/section[class="content-section"]/div[1]
  #resultlist > article:nth-child(5) > section.content-section > div.header.w-brk > a > span

  $G_DATA->{sites}->{willHaben}->{XPATHS}->{XPATH_TALALATI_LISTA} = '//div[@id="resultlist"]/article[@itemtype="http://schema.org/Product"]';
  $G_DATA->{sites}->{willHaben}->{XPATHS}->{XPATH_TITLE}          = './section[contains(@class, "content-section")]//span[@itemprop="name"]';
  $G_DATA->{sites}->{willHaben}->{XPATHS}->{XPATH_TITLE2}         = undef;
  $G_DATA->{sites}->{willHaben}->{XPATHS}->{XPATH_LINK}  = './section[contains(@class, "content-section")]//div[contains(@class, "header")]/a/@href';
  $G_DATA->{sites}->{willHaben}->{XPATHS}->{XPATH_PRICE} = './section[contains(@class, "content-section")]//span[@class="pull-right"]';
  $G_DATA->{sites}->{willHaben}->{XPATHS}->{XPATH_DESC}  = './section[contains(@class, "content-section")]//div[@itemprop="description"]';
  $G_DATA->{sites}->{willHaben}->{XPATHS}->{XPATH_FEATURES} = '';
  $G_DATA->{sites}->{willHaben}->{textToDelete} = '';

  #  https://www.willhaben.at/iad/gebrauchtwagen/auto/gebrauchtwagenboerse?YEAR_MODEL_FROM=2011&CAR_MODEL/MAKE=1005&PRICE_TO=12340&page=6&view=
  # https://www.willhaben.at/iad/gebrauchtwagen/auto/gebrauchtwagenboerse?CAR_MODEL/MAKE=1005&PRICE_TO=12340&YEAR_MODEL_FROM=2011
  # https://www.willhaben.at/iad/gebrauchtwagen/auto/gebrauchtwagenboerse?
  # CAR_MODEL/MAKE=1005&PRICE_FROM=12340&PRICE_TO=12340&YEAR_MODEL_FROM=2011

  # PRICE_FROM=2000
  # &PRICE_TO=17499.99
  # &MOTOR_CONDITION=20%3B30%3B40
  # &YEAR_MODEL_FROM=2011
  # &sort=1
  # &CAR_MODEL/MAKE=1005
  # &rows=100
  # &periode=0

  my $makerString_willhaben = 'CAR_MODEL/MAKE';
  $G_DATA->{sites}->{willHaben}->{makerString} = $makerString_willhaben;

  # ustate=N%2CU&     N,U: nem balesetes; A: balesetes;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{PRICE_FROM}      = $default_price_from;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{PRICE_TO}        = $default_price_to;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{MOTOR_CONDITION} = '20%3B30%3B40';

  # $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{YEAR_MODEL_FROM} = $default_year_from;

  $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{rows} = 100;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{sort} = 1;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{page} = "VVPAGEVV";

  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Audi}->{maxAge}    = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Citroen}->{maxAge} = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Fiat}->{maxAge}    = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Ford}->{maxAge}    = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Honda}->{maxAge}   = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Hyundai}->{maxAge} = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Mazda}->{maxAge}   = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Nissan}->{maxAge}  = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Opel}->{maxAge}    = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Seat}->{maxAge}    = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Skoda}->{maxAge}   = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{Toyota}->{maxAge}  = $default_maxAge;
  $G_DATA->{sites}->{willHaben}->{searchConfig}->{$makerString_willhaben}->{VW}->{maxAge}      = $default_maxAge;

  $G_DATA->{sites}->{willHaben}->{makers}->{"Abarth"}             = 10004;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Aixam"}              = 10012;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Alfa Romeo"}         = 1000;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Aston Martin"}       = 1002;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Audi"}               = 1003;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Austin"}             = 1734;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Bentley"}            = 1004;
  $G_DATA->{sites}->{willHaben}->{makers}->{"BMW"}                = 1005;
  $G_DATA->{sites}->{willHaben}->{makers}->{"British Leyland"}    = 1069;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Buick"}              = 1006;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Cadillac"}           = 1007;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Casalini"}           = 10017;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Caterham"}           = 10001;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Chevrolet / Daewoo"} = 1012;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Chevrolet"}          = 1008;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Chrysler"}           = 1009;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Citroen"}            = 1010;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Corvette"}           = 10018;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Dacia"}              = 1011;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Daihatsu"}           = 1013;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Dodge"}              = 1014;
  $G_DATA->{sites}->{willHaben}->{makers}->{"DS Automobiles"}     = 10019;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Ferrari"}            = 1015;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Fiat"}               = 1016;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Ford"}               = 1017;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Graf Carello"}       = 10016;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Honda"}              = 1018;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Hummer"}             = 1019;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Hyundai"}            = 1020;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Infiniti"}           = 10009;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Isuzu"}              = 1021;
  $G_DATA->{sites}->{willHaben}->{makers}->{"IVECO"}              = 1022;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Jaguar"}             = 1023;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Jeep"}               = 1024;
  $G_DATA->{sites}->{willHaben}->{makers}->{"KIA"}                = 1025;
  $G_DATA->{sites}->{willHaben}->{makers}->{"KTM"}                = 10005;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Lada"}               = 1026;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Lamborghini"}        = 1027;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Lancia"}             = 1028;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Land Rover"}         = 1029;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Lexus"}              = 1030;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Ligier"}             = 10014;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Lincoln"}            = 1031;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Lotus"}              = 1032;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Mahindra"}           = 10003;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Maserati"}           = 1033;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Maybach"}            = 1034;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Mazda"}              = 1035;
  $G_DATA->{sites}->{willHaben}->{makers}->{"McLaren"}            = 10020;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Mercedes-Benz"}      = 1036;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Mercury"}            = 1037;
  $G_DATA->{sites}->{willHaben}->{makers}->{"MG"}                 = 1038;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Microcar"}           = 10013;
  $G_DATA->{sites}->{willHaben}->{makers}->{"MINI"}               = 1039;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Mitsubishi"}         = 1040;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Morgan"}             = 1041;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Nissan"}             = 1042;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Opel"}               = 1043;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Peugeot"}            = 1045;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Pontiac"}            = 1047;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Porsche"}            = 1048;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Puch"}               = 1049;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Renault"}            = 1051;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Rolls-Royce"}        = 1052;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Rover"}              = 1053;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Saab"}               = 1054;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Seat"}               = 1056;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Skoda"}              = 1057;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Smart"}              = 1058;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Sonstige"}           = 9999;
  $G_DATA->{sites}->{willHaben}->{makers}->{"SsangYong"}          = 1059;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Subaru"}             = 1060;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Suzuki"}             = 1061;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Talbot"}             = 1073;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Tata"}               = 10002;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Tazzari"}            = 10010;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Tesla"}              = 10008;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Think"}              = 10007;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Toyota"}             = 1062;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Triumph"}            = 10015;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Volvo"}              = 1064;
  $G_DATA->{sites}->{willHaben}->{makers}->{"VW"}                 = 1065;
  $G_DATA->{sites}->{willHaben}->{makers}->{"Wiesmann"}           = 1066;
}

# ************************************************************
# ************************************************************
# Autoscout
# ************************************************************
{

# https://www.autoscout24.at/ergebnisse?priceto=6000&desc=0&powertype=kw&size=20&page=2&fregfrom=2008&mmm=29%7C%7C&pricetype=public&cy=A&cy=D&mmvco=1&pricefrom=500&offer=D&offer=J&offer=O&offer=S&offer=U&sort=age&ustate=A&ustate=N&ustate=U&atype=C

  $G_DATA->{sites}->{autoScout24}->{XPATHS}->{XPATH_TALALATI_LISTA}
    = '//div[contains(concat(" ", @class, " "), " cl-list-element cl-list-element-gap ")]';
  $G_DATA->{sites}->{autoScout24}->{XPATHS}->{XPATH_TITLE}    = './/h2[contains(concat(" ", @class, " "), " cldt-summary-makemodel ")]';
  $G_DATA->{sites}->{autoScout24}->{XPATHS}->{XPATH_TITLE2}   = './/h2[contains(concat(" ", @class, " "), " cldt-summary-version ")]';
  $G_DATA->{sites}->{autoScout24}->{XPATHS}->{XPATH_DESC}     = './/h2[contains(concat(" ", @class, " "), " cldt-summary-version ")]';
  $G_DATA->{sites}->{autoScout24}->{XPATHS}->{XPATH_LINK}     = './/div[contains(concat(" ", @class, " "), " cldt-summary-titles ")]/a/@href';
  $G_DATA->{sites}->{autoScout24}->{XPATHS}->{XPATH_PRICE}    = './/span[contains(concat(" ", @class, " "), " cldt-price ")]';
  $G_DATA->{sites}->{autoScout24}->{XPATHS}->{XPATH_FEATURES} = './/div[contains(concat(" ", @class, " "), " cldt-summary-vehicle-data ")]/ul/li';
  $G_DATA->{sites}->{autoScout24}->{textToDelete}
    = 'Weitere Informationen zum offiziellen Kraftstoffverbrauch und den offiziellen spezifischen CO2-Emissionen neuer Personenkraftwagen können dem "Leitfaden über den Kraftstoffverbrauch, die CO2-Emissionen und den Stromverbrauch neuer Personenkraftwagen" entnommen werden, der an allen Verkaufsstellen und bei der Deutschen Automobil Treuhand GmbH unter www.dat.at unentgeltlich erhältlich ist.';
  $G_DATA->{sites}->{autoScout24}->{textToDelete}
    = 'Weitere Informationen zum offiziellen Kraftstoffverbrauch und den offiziellen spezifischen CO2-Emissionen neuer Personenkraftwagen konnen dem "Leitfaden uber den Kraftstoffverbrauch, die CO2-Emissionen und den Stromverbrauch neuer Personenkraftwagen" entnommen werden, der an allen Verkaufsstellen und bei der Deutschen Automobil Treuhand GmbH unter www.dat.at unentgeltlich erhaltlich ist.';

  # mmvmk0=9&mmvco=1&fregfrom=2013&fregto=2015&pricefrom=0&priceto=8000&fuel=B&kmfrom=10000&powertype=kw&atype=C&ustate=N%2CU&sort=standard&desc=0

  # ustate=N%2CU&     N,U: nem balesetes; A: balesetes;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{pricefrom} = 500;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{priceto}   = 6000;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{sort}      = 'age';
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{desc}      = 0;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{cy}        = 'A,D';    # A: Austria; D: Germany
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{offer}
    = 'D,J,O,S,U';    # D: Vorführfahrzeug, J: Jahreswagen, N: Neu, O: Oldtimer, S: Tageszulassung, U: Gebraucht
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{mmvco}     = 1;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{powertype} = 'kw';
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{atype}     = 'C';
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{ustate}    = 'A,N,U';      #  A: balesetes; N,U: nem balesetes;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{page}      = "VVPAGEVV";
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{size}      = 20;           # size per page

  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Audi}->{maxAge}       = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Citroen}->{maxAge}    = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Fiat}->{maxAge}       = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Ford}->{maxAge}       = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Honda}->{maxAge}      = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Hyundai}->{maxAge}    = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Opel}->{maxAge}       = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{SEAT}->{maxAge}       = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Skoda}->{maxAge}      = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Toyota}->{maxAge}     = $default_maxAge;
  $G_DATA->{sites}->{autoScout24}->{searchConfig}->{mmvmk0}->{Volkswagen}->{maxAge} = $default_maxAge;

  $G_DATA->{sites}->{autoScout24}->{makers}->{"Audi"}              = 9;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"BMW"}               = 13;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Ford"}              = 29;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Mercedes-Benz"}     = 47;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Opel"}              = 54;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Volkswagen"}        = 74;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Abarth"}            = 16396;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"AC"}                = 14979;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"ACM"}               = 16429;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Acura"}             = 16356;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Aixam"}             = 16352;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Alfa Romeo"}        = 6;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Alpina"}            = 14;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Amphicar"}          = 51545;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Ariel"}             = 16419;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Artega"}            = 16427;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Aspid"}             = 16431;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Aston Martin"}      = 8;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Austin"}            = 15643;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Autobianchi"}       = 15644;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Auverland"}         = 16437;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Baic"}              = 51774;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Bedford"}           = 16400;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Bellier"}           = 16416;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Bentley"}           = 11;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Bollore"}           = 16418;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Borgward"}          = 16424;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Brilliance"}        = 16367;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Bugatti"}           = 15;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Buick"}             = 16;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"BYD"}               = 16379;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Cadillac"}          = 17;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Caravans-Wohnm"}    = 15672;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Casalini"}          = 16407;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Caterham"}          = 16335;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Changhe"}           = 16401;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Chatenet"}          = 16357;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Chery"}             = 16384;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Chevrolet"}         = 19;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Chrysler"}          = 20;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Citroen"}           = 21;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"CityEL"}            = 16411;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"CMC"}               = 16406;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Corvette"}          = 16380;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Courb"}             = 51558;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Dacia"}             = 16360;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Daewoo"}            = 22;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"DAF"}               = 16333;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Daihatsu"}          = 23;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Daimler"}           = 16397;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Dangel"}            = 16434;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"De la Chapelle"}    = 16423;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"De Tomaso"}         = 51779;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Derways"}           = 16391;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"DFSK"}              = 51773;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Dodge"}             = 2152;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Donkervoort"}       = 16339;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"DR Motor"}          = 16383;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"DS Automobiles"}    = 16415;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Dutton"}            = 51552;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Estrima"}           = 16436;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Ferrari"}           = 27;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Fiat"}              = 28;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"FISKER"}            = 51543;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Gac Gonow"}         = 51542;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Galloper"}          = 16337;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"GAZ"}               = 16386;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Geely"}             = 16392;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"GEM"}               = 16403;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"GEMBALLA"}          = 51540;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Giotti Victoria"}   = 16421;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"GMC"}               = 2153;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Great Wall"}        = 16382;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Grecav"}            = 16409;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Haima"}             = 51512;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Hamann"}            = 51534;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Honda"}             = 31;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"HUMMER"}            = 15674;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Hurtan"}            = 51767;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Hyundai"}           = 33;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Infiniti"}          = 16355;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Innocenti"}         = 15629;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Iso Rivolta"}       = 16402;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Isuzu"}             = 35;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Iveco"}             = 14882;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"IZH"}               = 16387;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Jaguar"}            = 37;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Jeep"}              = 38;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Karabag"}           = 16417;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Kia"}               = 39;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Koenigsegg"}        = 51781;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"KTM"}               = 50060;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Lada"}              = 40;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Lamborghini"}       = 41;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Lancia"}            = 42;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Land Rover"}        = 15641;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"LDV"}               = 16426;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Lexus"}             = 43;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Lifan"}             = 16393;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Ligier"}            = 16353;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Lincoln"}           = 14890;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Lotus"}             = 44;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Mahindra"}          = 16359;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"MAN"}               = 51780;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Mansory"}           = 16435;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Martin Motors"}     = 16410;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Maserati"}          = 45;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Maybach"}           = 16348;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Mazda"}             = 46;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"McLaren"}           = 51519;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Melex"}             = 16399;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"MG"}                = 48;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Microcar"}          = 16361;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Minauto"}           = 51766;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"MINI"}              = 16338;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Mitsubishi"}        = 50;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Mitsuoka"}          = 51782;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Morgan"}            = 51;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Moskvich"}          = 16388;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"MP Lafer"}          = 51554;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Nissan"}            = 52;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Oldsmobile"}        = 53;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Oldtimer"}          = 15670;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Pagani"}            = 16341;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Panther Westwinds"} = 51553;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Peugeot"}           = 55;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"PGO"}               = 50083;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Piaggio"}           = 16350;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Plymouth"}          = 51770;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Pontiac"}           = 56;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Porsche"}           = 57;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Proton"}            = 15636;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Puch"}              = 51768;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Qoros"}             = 16412;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Qvale"}             = 16425;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Reliant"}           = 16398;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Renault"}           = 60;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Rolls-Royce"}       = 61;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Rover"}             = 62;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Ruf"}               = 51536;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Saab"}              = 63;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Santana"}           = 16369;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Savel"}             = 16405;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"SDG"}               = 51771;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"SEAT"}              = 64;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Skoda"}             = 65;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"smart"}             = 15525;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"SpeedArt"}          = 51538;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Spyker"}            = 16377;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"SsangYong"}         = 66;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Subaru"}            = 67;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Suzuki"}            = 68;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"TagAZ"}             = 16395;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Talbot"}            = 51551;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Tasso"}             = 16404;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Tata"}              = 16327;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Tazzari EV"}        = 51557;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"TECHART"}           = 51535;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Tesla"}             = 51520;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Town Life"}         = 16420;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Toyota"}            = 70;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Trabant"}           = 15633;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Trailer-Anhaenger"} = 16326;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Triumph"}           = 2120;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Trucks-Lkw"}        = 16253;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"TVR"}               = 71;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"UAZ"}               = 16389;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"VAZ"}               = 16385;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"VEM"}               = 16422;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Volvo"}             = 73;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Vortex"}            = 51514;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Wallys"}            = 51776;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Wartburg"}          = 16336;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Westfield"}         = 51513;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Wiesmann"}          = 16351;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Zastava"}           = 16408;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"ZAZ"}               = 16394;
  $G_DATA->{sites}->{autoScout24}->{makers}->{"Sonstige"}          = 16328;
}

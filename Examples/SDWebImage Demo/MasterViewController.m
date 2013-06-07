//
//  MasterViewController.m
//  SDWebImage Demo
//
//  Created by Olivier Poitrey on 09/05/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "MasterViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DetailViewController.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = @"SDWebImage";
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Clear Cache"
                                                                                style:UIBarButtonItemStylePlain
                                                                               target:self
                                                                               action:@selector(flushCache)];
        _objects = [NSArray arrayWithObjects:
                    @"http://assets.sbnation.com/assets/2512203/dogflops.gif",
                    @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
                    @"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp",
                    @"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.jpg?20120509154705",
                    @"http://static2.dmcdn.net/static/video/629/228/44822926:jpeg_preview_small.jpg?20120509181018",
                    @"http://static2.dmcdn.net/static/video/116/367/44763611:jpeg_preview_small.jpg?20120509101749",
                    @"http://static2.dmcdn.net/static/video/340/086/44680043:jpeg_preview_small.jpg?20120509180118",
                    @"http://static2.dmcdn.net/static/video/666/645/43546666:jpeg_preview_small.jpg?20120412153140",
                    @"http://static2.dmcdn.net/static/video/771/577/44775177:jpeg_preview_small.jpg?20120509183230",
                    @"http://static2.dmcdn.net/static/video/810/508/44805018:jpeg_preview_small.jpg?20120508125339",
                    @"http://static2.dmcdn.net/static/video/152/008/44800251:jpeg_preview_small.jpg?20120508103336",
                    @"http://static2.dmcdn.net/static/video/694/741/35147496:jpeg_preview_small.jpg?20120508111445",
                    @"http://static2.dmcdn.net/static/video/988/667/44766889:jpeg_preview_small.jpg?20120508130425",
                    @"http://static2.dmcdn.net/static/video/282/467/44764282:jpeg_preview_small.jpg?20120507130637",
                    @"http://static2.dmcdn.net/static/video/754/657/44756457:jpeg_preview_small.jpg?20120507093012",
                    @"http://static2.dmcdn.net/static/video/831/107/44701138:jpeg_preview_small.jpg?20120506133917",
                    @"http://static2.dmcdn.net/static/video/411/057/44750114:jpeg_preview_small.jpg?20120507014914",
                    @"http://static2.dmcdn.net/static/video/894/547/44745498:jpeg_preview_small.jpg?20120509183004",
                    @"http://static2.dmcdn.net/static/video/082/947/44749280:jpeg_preview_small.jpg?20120507015022",
                    @"http://static2.dmcdn.net/static/video/833/347/44743338:jpeg_preview_small.jpg?20120509183004",
                    @"http://static2.dmcdn.net/static/video/683/666/44666386:jpeg_preview_small.jpg?20120505111208",
                    @"http://static2.dmcdn.net/static/video/595/946/44649595:jpeg_preview_small.jpg?20120507194104",
                    @"http://static2.dmcdn.net/static/video/984/935/44539489:jpeg_preview_small.jpg?20120501184650",
                    @"http://static2.dmcdn.net/static/video/440/416/44614044:jpeg_preview_small.jpg?20120505174152",
                    @"http://static2.dmcdn.net/static/video/561/977/20779165:jpeg_preview_small.jpg?20120423161805",
                    @"http://static2.dmcdn.net/static/video/104/546/44645401:jpeg_preview_small.jpg?20120507185246",
                    @"http://static2.dmcdn.net/static/video/671/636/44636176:jpeg_preview_small.jpg?20120504021339",
                    @"http://static2.dmcdn.net/static/video/142/746/44647241:jpeg_preview_small.jpg?20120504104451",
                    @"http://static2.dmcdn.net/static/video/776/860/44068677:jpeg_preview_small.jpg?20120507185251",
                    @"http://static2.dmcdn.net/static/video/026/626/44626620:jpeg_preview_small.jpg?20120503203036",
                    @"http://static2.dmcdn.net/static/video/364/663/39366463:jpeg_preview_small.jpg?20120509163505",
                    @"http://static2.dmcdn.net/static/video/392/895/44598293:jpeg_preview_small.jpg?20120503165252",
                    @"http://static2.dmcdn.net/static/video/620/865/44568026:jpeg_preview_small.jpg?20120507185121",
                    @"http://static2.dmcdn.net/static/video/031/395/44593130:jpeg_preview_small.jpg?20120507185139",
                    @"http://static2.dmcdn.net/static/video/676/495/44594676:jpeg_preview_small.jpg?20120503121341",
                    @"http://static2.dmcdn.net/static/video/025/195/44591520:jpeg_preview_small.jpg?20120503132132",
                    @"http://static2.dmcdn.net/static/video/993/665/44566399:jpeg_preview_small.jpg?20120503182623",
                    @"http://static2.dmcdn.net/static/video/137/635/44536731:jpeg_preview_small.jpg?20120501165940",
                    @"http://static2.dmcdn.net/static/video/611/794/44497116:jpeg_preview_small.jpg?20120507184954",
                    @"http://static2.dmcdn.net/static/video/732/790/44097237:jpeg_preview_small.jpg?20120430162348",
                    @"http://static2.dmcdn.net/static/video/064/991/44199460:jpeg_preview_small.jpg?20120430101250",
                    @"http://static2.dmcdn.net/static/video/404/094/44490404:jpeg_preview_small.jpg?20120507184948",
                    @"http://static2.dmcdn.net/static/video/413/120/44021314:jpeg_preview_small.jpg?20120507180850",
                    @"http://static2.dmcdn.net/static/video/200/584/44485002:jpeg_preview_small.jpg?20120507184941",
                    @"http://static2.dmcdn.net/static/video/551/318/42813155:jpeg_preview_small.jpg?20120412153202",
                    @"http://static2.dmcdn.net/static/video/524/750/44057425:jpeg_preview_small.jpg?20120501220912",
                    @"http://static2.dmcdn.net/static/video/124/843/44348421:jpeg_preview_small.jpg?20120507184551",
                    @"http://static2.dmcdn.net/static/video/496/394/42493694:jpeg_preview_small.jpg?20120430105337",
                    @"http://static2.dmcdn.net/static/video/548/883/44388845:jpeg_preview_small.jpg?20120428212713",
                    @"http://static2.dmcdn.net/static/video/282/533/44335282:jpeg_preview_small.jpg?20120427102844",
                    @"http://static2.dmcdn.net/static/video/257/132/44231752:jpeg_preview_small.jpg?20120428212609",
                    @"http://static2.dmcdn.net/static/video/480/193/44391084:jpeg_preview_small.jpg?20120501143214",
                    @"http://static2.dmcdn.net/static/video/903/432/44234309:jpeg_preview_small.jpg?20120427200002",
                    @"http://static2.dmcdn.net/static/video/646/573/44375646:jpeg_preview_small.jpg?20120507184652",
                    @"http://static2.dmcdn.net/static/video/709/573/44375907:jpeg_preview_small.jpg?20120507184652",
                    @"http://static2.dmcdn.net/static/video/885/633/44336588:jpeg_preview_small.jpg?20120507184540",
                    @"http://static2.dmcdn.net/static/video/732/523/44325237:jpeg_preview_small.jpg?20120426110308",
                    @"http://static2.dmcdn.net/static/video/935/132/44231539:jpeg_preview_small.jpg?20120426115744",
                    @"http://static2.dmcdn.net/static/video/941/129/43921149:jpeg_preview_small.jpg?20120426094640",
                    @"http://static2.dmcdn.net/static/video/775/942/44249577:jpeg_preview_small.jpg?20120425011228",
                    @"http://static2.dmcdn.net/static/video/868/332/44233868:jpeg_preview_small.jpg?20120429152901",
                    @"http://static2.dmcdn.net/static/video/959/732/44237959:jpeg_preview_small.jpg?20120425133534",
                    @"http://static2.dmcdn.net/static/video/383/402/44204383:jpeg_preview_small.jpg?20120424185842",
                    @"http://static2.dmcdn.net/static/video/971/932/44239179:jpeg_preview_small.jpg?20120424154419",
                    @"http://static2.dmcdn.net/static/video/096/991/44199690:jpeg_preview_small.jpg?20120423162001",
                    @"http://static2.dmcdn.net/static/video/661/450/44054166:jpeg_preview_small.jpg?20120507180921",
                    @"http://static2.dmcdn.net/static/video/419/322/44223914:jpeg_preview_small.jpg?20120424112858",
                    @"http://static2.dmcdn.net/static/video/673/391/44193376:jpeg_preview_small.jpg?20120507181450",
                    @"http://static2.dmcdn.net/static/video/907/781/44187709:jpeg_preview_small.jpg?20120423103507",
                    @"http://static2.dmcdn.net/static/video/446/571/44175644:jpeg_preview_small.jpg?20120423033122",
                    @"http://static2.dmcdn.net/static/video/146/671/44176641:jpeg_preview_small.jpg?20120428235503",
                    @"http://static2.dmcdn.net/static/video/463/571/44175364:jpeg_preview_small.jpg?20120428235503",
                    @"http://static2.dmcdn.net/static/video/442/471/44174244:jpeg_preview_small.jpg?20120428235502",
                    @"http://static2.dmcdn.net/static/video/523/471/44174325:jpeg_preview_small.jpg?20120422205107",
                    @"http://static2.dmcdn.net/static/video/977/159/43951779:jpeg_preview_small.jpg?20120420182100",
                    @"http://static2.dmcdn.net/static/video/875/880/40088578:jpeg_preview_small.jpg?20120501131026",
                    @"http://static2.dmcdn.net/static/video/434/992/38299434:jpeg_preview_small.jpg?20120503193356",
                    @"http://static2.dmcdn.net/static/video/448/798/42897844:jpeg_preview_small.jpg?20120418155203",
                    @"http://static2.dmcdn.net/static/video/374/690/44096473:jpeg_preview_small.jpg?20120507181124",
                    @"http://static2.dmcdn.net/static/video/284/313/43313482:jpeg_preview_small.jpg?20120420184511",
                    @"http://static2.dmcdn.net/static/video/682/060/44060286:jpeg_preview_small.jpg?20120421122436",
                    @"http://static2.dmcdn.net/static/video/701/750/44057107:jpeg_preview_small.jpg?20120420112918",
                    @"http://static2.dmcdn.net/static/video/790/850/44058097:jpeg_preview_small.jpg?20120424114522",
                    @"http://static2.dmcdn.net/static/video/153/617/43716351:jpeg_preview_small.jpg?20120419190650",
                    @"http://static2.dmcdn.net/static/video/394/633/37336493:jpeg_preview_small.jpg?20111109151109",
                    @"http://static2.dmcdn.net/static/video/893/330/44033398:jpeg_preview_small.jpg?20120419123322",
                    @"http://static2.dmcdn.net/static/video/395/046/42640593:jpeg_preview_small.jpg?20120418103546",
                    @"http://static2.dmcdn.net/static/video/913/040/44040319:jpeg_preview_small.jpg?20120419164908",
                    @"http://static2.dmcdn.net/static/video/090/020/44020090:jpeg_preview_small.jpg?20120418185934",
                    @"http://static2.dmcdn.net/static/video/349/299/43992943:jpeg_preview_small.jpg?20120418112749",
                    @"http://static2.dmcdn.net/static/video/530/189/43981035:jpeg_preview_small.jpg?20120419013834",
                    @"http://static2.dmcdn.net/static/video/763/469/43964367:jpeg_preview_small.jpg?20120425111931",
                    @"http://static2.dmcdn.net/static/video/961/455/43554169:jpeg_preview_small.jpg?20120418110127",
                    @"http://static2.dmcdn.net/static/video/666/889/43988666:jpeg_preview_small.jpg?20120507180735",
                    @"http://static2.dmcdn.net/static/video/160/459/43954061:jpeg_preview_small.jpg?20120501202847",
                    @"http://static2.dmcdn.net/static/video/352/069/43960253:jpeg_preview_small.jpg?20120503175747",
                    @"http://static2.dmcdn.net/static/video/096/502/43205690:jpeg_preview_small.jpg?20120417142655",
                    @"http://static2.dmcdn.net/static/video/257/119/43911752:jpeg_preview_small.jpg?20120416101238",
                    @"http://static2.dmcdn.net/static/video/874/098/43890478:jpeg_preview_small.jpg?20120415193608",
                    @"http://static2.dmcdn.net/static/video/406/148/43841604:jpeg_preview_small.jpg?20120416123145",
                    @"http://static2.dmcdn.net/static/video/463/885/43588364:jpeg_preview_small.jpg?20120409130206",
                    @"http://static2.dmcdn.net/static/video/176/845/38548671:jpeg_preview_small.jpg?20120414200742",
                    @"http://static2.dmcdn.net/static/video/447/848/51848744:jpeg_preview_small.jpg?20121105223446",
                    @"http://static2.dmcdn.net/static/video/337/848/51848733:jpeg_preview_small.jpg?20121105223433",
                    @"http://static2.dmcdn.net/static/video/707/848/51848707:jpeg_preview_small.jpg?20121105223428",
                    @"http://static2.dmcdn.net/static/video/102/848/51848201:jpeg_preview_small.jpg?20121105223411",
                    @"http://static2.dmcdn.net/static/video/817/848/51848718:jpeg_preview_small.jpg?20121105223402",
                    @"http://static2.dmcdn.net/static/video/007/848/51848700:jpeg_preview_small.jpg?20121105223345",
                    @"http://static2.dmcdn.net/static/video/696/848/51848696:jpeg_preview_small.jpg?20121105223355",
                    @"http://static2.dmcdn.net/static/video/296/848/51848692:jpeg_preview_small.jpg?20121105223337",
                    @"http://static2.dmcdn.net/static/video/080/848/51848080:jpeg_preview_small.jpg?20121105223653",
                    @"http://static2.dmcdn.net/static/video/386/848/51848683:jpeg_preview_small.jpg?20121105223343",
                    @"http://static2.dmcdn.net/static/video/876/848/51848678:jpeg_preview_small.jpg?20121105223301",
                    @"http://static2.dmcdn.net/static/video/866/848/51848668:jpeg_preview_small.jpg?20121105223244",
                    @"http://static2.dmcdn.net/static/video/572/548/51845275:jpeg_preview_small.jpg?20121105223229",
                    @"http://static2.dmcdn.net/static/video/972/548/51845279:jpeg_preview_small.jpg?20121105223227",
                    @"http://static2.dmcdn.net/static/video/112/548/51845211:jpeg_preview_small.jpg?20121105223226",
                    @"http://static2.dmcdn.net/static/video/549/448/51844945:jpeg_preview_small.jpg?20121105223223",
                    @"http://static2.dmcdn.net/static/video/166/848/51848661:jpeg_preview_small.jpg?20121105223228",
                    @"http://static2.dmcdn.net/static/video/856/848/51848658:jpeg_preview_small.jpg?20121105223223",
                    @"http://static2.dmcdn.net/static/video/746/848/51848647:jpeg_preview_small.jpg?20121105223204",
                    @"http://static2.dmcdn.net/static/video/446/848/51848644:jpeg_preview_small.jpg?20121105223204",
                    @"http://static2.dmcdn.net/static/video/726/848/51848627:jpeg_preview_small.jpg?20121105223221",
                    @"http://static2.dmcdn.net/static/video/436/848/51848634:jpeg_preview_small.jpg?20121105223445",
                    @"http://static2.dmcdn.net/static/video/836/848/51848638:jpeg_preview_small.jpg?20121105223144",
                    @"http://static2.dmcdn.net/static/video/036/848/51848630:jpeg_preview_small.jpg?20121105223125",
                    @"http://static2.dmcdn.net/static/video/026/848/51848620:jpeg_preview_small.jpg?20121105223102",
                    @"http://static2.dmcdn.net/static/video/895/848/51848598:jpeg_preview_small.jpg?20121105223112",
                    @"http://static2.dmcdn.net/static/video/116/848/51848611:jpeg_preview_small.jpg?20121105223052",
                    @"http://static2.dmcdn.net/static/video/006/848/51848600:jpeg_preview_small.jpg?20121105223043",
                    @"http://static2.dmcdn.net/static/video/432/548/51845234:jpeg_preview_small.jpg?20121105223022",
                    @"http://static2.dmcdn.net/static/video/785/848/51848587:jpeg_preview_small.jpg?20121105223031",
                    @"http://static2.dmcdn.net/static/video/975/848/51848579:jpeg_preview_small.jpg?20121105223012",
                    @"http://static2.dmcdn.net/static/video/965/848/51848569:jpeg_preview_small.jpg?20121105222952",
                    @"http://static2.dmcdn.net/static/video/365/848/51848563:jpeg_preview_small.jpg?20121105222943",
                    @"http://static2.dmcdn.net/static/video/755/848/51848557:jpeg_preview_small.jpg?20121105222943",
                    @"http://static2.dmcdn.net/static/video/722/248/51842227:jpeg_preview_small.jpg?20121105222908",
                    @"http://static2.dmcdn.net/static/video/155/848/51848551:jpeg_preview_small.jpg?20121105222913",
                    @"http://static2.dmcdn.net/static/video/345/848/51848543:jpeg_preview_small.jpg?20121105222907",
                    @"http://static2.dmcdn.net/static/video/535/848/51848535:jpeg_preview_small.jpg?20121105222848",
                    @"http://static2.dmcdn.net/static/video/035/848/51848530:jpeg_preview_small.jpg?20121105222837",
                    @"http://static2.dmcdn.net/static/video/525/848/51848525:jpeg_preview_small.jpg?20121105222826",
                    @"http://static2.dmcdn.net/static/video/233/848/51848332:jpeg_preview_small.jpg?20121105223414",
                    @"http://static2.dmcdn.net/static/video/125/848/51848521:jpeg_preview_small.jpg?20121105222809",
                    @"http://static2.dmcdn.net/static/video/005/848/51848500:jpeg_preview_small.jpg?20121105222802",
                    @"http://static2.dmcdn.net/static/video/015/848/51848510:jpeg_preview_small.jpg?20121105222755",
                    @"http://static2.dmcdn.net/static/video/121/548/51845121:jpeg_preview_small.jpg?20121105222850",
                    @"http://static2.dmcdn.net/static/video/205/848/51848502:jpeg_preview_small.jpg?20121105222737",
                    @"http://static2.dmcdn.net/static/video/697/448/51844796:jpeg_preview_small.jpg?20121105222818",
                    @"http://static2.dmcdn.net/static/video/494/848/51848494:jpeg_preview_small.jpg?20121105222724",
                    @"http://static2.dmcdn.net/static/video/806/448/51844608:jpeg_preview_small.jpg?20121105222811",
                    @"http://static2.dmcdn.net/static/video/729/348/51843927:jpeg_preview_small.jpg?20121105222805",
                    @"http://static2.dmcdn.net/static/video/865/148/51841568:jpeg_preview_small.jpg?20121105222803",
                    @"http://static2.dmcdn.net/static/video/481/548/51845184:jpeg_preview_small.jpg?20121105222700",
                    @"http://static2.dmcdn.net/static/video/190/548/51845091:jpeg_preview_small.jpg?20121105222656",
                    @"http://static2.dmcdn.net/static/video/128/448/51844821:jpeg_preview_small.jpg?20121105222656",
                    @"http://static2.dmcdn.net/static/video/784/848/51848487:jpeg_preview_small.jpg?20121105222704",
                    @"http://static2.dmcdn.net/static/video/182/448/51844281:jpeg_preview_small.jpg?20121105222652",
                    @"http://static2.dmcdn.net/static/video/801/848/51848108:jpeg_preview_small.jpg?20121105222907",
                    @"http://static2.dmcdn.net/static/video/974/848/51848479:jpeg_preview_small.jpg?20121105222657",
                    @"http://static2.dmcdn.net/static/video/274/848/51848472:jpeg_preview_small.jpg?20121105222644",
                    @"http://static2.dmcdn.net/static/video/954/848/51848459:jpeg_preview_small.jpg?20121105222637",
                    @"http://static2.dmcdn.net/static/video/554/848/51848455:jpeg_preview_small.jpg?20121105222615",
                    @"http://static2.dmcdn.net/static/video/944/848/51848449:jpeg_preview_small.jpg?20121105222558",
                    @"http://static2.dmcdn.net/static/video/144/848/51848441:jpeg_preview_small.jpg?20121105222556",
                    @"http://static2.dmcdn.net/static/video/134/848/51848431:jpeg_preview_small.jpg?20121105222539",
                    @"http://static2.dmcdn.net/static/video/624/848/51848426:jpeg_preview_small.jpg?20121105222523",
                    @"http://static2.dmcdn.net/static/video/281/448/51844182:jpeg_preview_small.jpg?20121105222502",
                    @"http://static2.dmcdn.net/static/video/414/848/51848414:jpeg_preview_small.jpg?20121105222516",
                    @"http://static2.dmcdn.net/static/video/171/848/51848171:jpeg_preview_small.jpg?20121105223449",
                    @"http://static2.dmcdn.net/static/video/904/848/51848409:jpeg_preview_small.jpg?20121105222514",
                    @"http://static2.dmcdn.net/static/video/004/848/51848400:jpeg_preview_small.jpg?20121105222443",
                    @"http://static2.dmcdn.net/static/video/693/848/51848396:jpeg_preview_small.jpg?20121105222439",
                    @"http://static2.dmcdn.net/static/video/401/848/51848104:jpeg_preview_small.jpg?20121105222832",
                    @"http://static2.dmcdn.net/static/video/957/648/51846759:jpeg_preview_small.jpg?20121105223109",
                    @"http://static2.dmcdn.net/static/video/603/848/51848306:jpeg_preview_small.jpg?20121105222324",
                    @"http://static2.dmcdn.net/static/video/990/848/51848099:jpeg_preview_small.jpg?20121105222807",
                    @"http://static2.dmcdn.net/static/video/929/448/51844929:jpeg_preview_small.jpg?20121105222216",
                    @"http://static2.dmcdn.net/static/video/320/548/51845023:jpeg_preview_small.jpg?20121105222214",
                    @"http://static2.dmcdn.net/static/video/387/448/51844783:jpeg_preview_small.jpg?20121105222212",
                    @"http://static2.dmcdn.net/static/video/833/248/51842338:jpeg_preview_small.jpg?20121105222209",
                    @"http://static2.dmcdn.net/static/video/993/348/51843399:jpeg_preview_small.jpg?20121105222012",
                    @"http://static2.dmcdn.net/static/video/660/848/51848066:jpeg_preview_small.jpg?20121105222754",
                    @"http://static2.dmcdn.net/static/video/471/848/51848174:jpeg_preview_small.jpg?20121105223419",
                    @"http://static2.dmcdn.net/static/video/255/748/51847552:jpeg_preview_small.jpg?20121105222420",
                    @"http://static2.dmcdn.net/static/video/257/448/51844752:jpeg_preview_small.jpg?20121105221728",
                    @"http://static2.dmcdn.net/static/video/090/848/51848090:jpeg_preview_small.jpg?20121105223020",
                    @"http://static2.dmcdn.net/static/video/807/448/51844708:jpeg_preview_small.jpg?20121105221654",
                    @"http://static2.dmcdn.net/static/video/196/448/51844691:jpeg_preview_small.jpg?20121105222110",
                    @"http://static2.dmcdn.net/static/video/406/448/51844604:jpeg_preview_small.jpg?20121105221647",
                    @"http://static2.dmcdn.net/static/video/865/348/51843568:jpeg_preview_small.jpg?20121105221644",
                    @"http://static2.dmcdn.net/static/video/932/448/51844239:jpeg_preview_small.jpg?20121105221309",
                    @"http://static2.dmcdn.net/static/video/967/438/51834769:jpeg_preview_small.jpg?20121105221020",
                    @"http://static2.dmcdn.net/static/video/362/348/51843263:jpeg_preview_small.jpg?20121105220855",
                    @"http://static2.dmcdn.net/static/video/777/448/51844777:jpeg_preview_small.jpg?20121105220715",
                    @"http://static2.dmcdn.net/static/video/567/348/51843765:jpeg_preview_small.jpg?20121105220708",
                    @"http://static2.dmcdn.net/static/video/905/248/51842509:jpeg_preview_small.jpg?20121105220640",
                    @"http://static2.dmcdn.net/static/video/857/748/51847758:jpeg_preview_small.jpg?20121105221003",
                    @"http://static2.dmcdn.net/static/video/578/348/51843875:jpeg_preview_small.jpg?20121105220350",
                    @"http://static2.dmcdn.net/static/video/214/448/51844412:jpeg_preview_small.jpg?20121105220415",
                    @"http://static2.dmcdn.net/static/video/264/748/51847462:jpeg_preview_small.jpg?20121105220635",
                    @"http://static2.dmcdn.net/static/video/817/748/51847718:jpeg_preview_small.jpg?20121105220233",
                    @"http://static2.dmcdn.net/static/video/784/848/51848487:jpeg_preview_small.jpg?20121105222704",
                    @"http://static2.dmcdn.net/static/video/182/448/51844281:jpeg_preview_small.jpg?20121105222652",
                    @"http://static2.dmcdn.net/static/video/801/848/51848108:jpeg_preview_small.jpg?20121105222907",
                    @"http://static2.dmcdn.net/static/video/974/848/51848479:jpeg_preview_small.jpg?20121105222657",
                    @"http://static2.dmcdn.net/static/video/274/848/51848472:jpeg_preview_small.jpg?20121105222644",
                    @"http://static2.dmcdn.net/static/video/954/848/51848459:jpeg_preview_small.jpg?20121105222637",
                    @"http://static2.dmcdn.net/static/video/554/848/51848455:jpeg_preview_small.jpg?20121105222615",
                    @"http://static2.dmcdn.net/static/video/944/848/51848449:jpeg_preview_small.jpg?20121105222558",
                    @"http://static2.dmcdn.net/static/video/144/848/51848441:jpeg_preview_small.jpg?20121105222556",
                    @"http://static2.dmcdn.net/static/video/134/848/51848431:jpeg_preview_small.jpg?20121105222539",
                    @"http://static2.dmcdn.net/static/video/624/848/51848426:jpeg_preview_small.jpg?20121105222523",
                    @"http://static2.dmcdn.net/static/video/281/448/51844182:jpeg_preview_small.jpg?20121105222502",
                    @"http://static2.dmcdn.net/static/video/414/848/51848414:jpeg_preview_small.jpg?20121105222516",
                    @"http://static2.dmcdn.net/static/video/171/848/51848171:jpeg_preview_small.jpg?20121105223449",
                    @"http://static2.dmcdn.net/static/video/904/848/51848409:jpeg_preview_small.jpg?20121105222514",
                    @"http://static2.dmcdn.net/static/video/004/848/51848400:jpeg_preview_small.jpg?20121105222443",
                    @"http://static2.dmcdn.net/static/video/693/848/51848396:jpeg_preview_small.jpg?20121105222439",
                    @"http://static2.dmcdn.net/static/video/401/848/51848104:jpeg_preview_small.jpg?20121105222832",
                    @"http://static2.dmcdn.net/static/video/957/648/51846759:jpeg_preview_small.jpg?20121105223109",
                    @"http://static2.dmcdn.net/static/video/603/848/51848306:jpeg_preview_small.jpg?20121105222324",
                    @"http://static2.dmcdn.net/static/video/990/848/51848099:jpeg_preview_small.jpg?20121105222807",
                    @"http://static2.dmcdn.net/static/video/929/448/51844929:jpeg_preview_small.jpg?20121105222216",
                    @"http://static2.dmcdn.net/static/video/320/548/51845023:jpeg_preview_small.jpg?20121105222214",
                    @"http://static2.dmcdn.net/static/video/387/448/51844783:jpeg_preview_small.jpg?20121105222212",
                    @"http://static2.dmcdn.net/static/video/833/248/51842338:jpeg_preview_small.jpg?20121105222209",
                    @"http://static2.dmcdn.net/static/video/993/348/51843399:jpeg_preview_small.jpg?20121105222012",
                    @"http://static2.dmcdn.net/static/video/660/848/51848066:jpeg_preview_small.jpg?20121105222754",
                    @"http://static2.dmcdn.net/static/video/471/848/51848174:jpeg_preview_small.jpg?20121105223419",
                    @"http://static2.dmcdn.net/static/video/255/748/51847552:jpeg_preview_small.jpg?20121105222420",
                    @"http://static2.dmcdn.net/static/video/257/448/51844752:jpeg_preview_small.jpg?20121105221728",
                    @"http://static2.dmcdn.net/static/video/090/848/51848090:jpeg_preview_small.jpg?20121105224514",
                    @"http://static2.dmcdn.net/static/video/807/448/51844708:jpeg_preview_small.jpg?20121105221654",
                    @"http://static2.dmcdn.net/static/video/196/448/51844691:jpeg_preview_small.jpg?20121105222110",
                    @"http://static2.dmcdn.net/static/video/406/448/51844604:jpeg_preview_small.jpg?20121105221647",
                    @"http://static2.dmcdn.net/static/video/865/348/51843568:jpeg_preview_small.jpg?20121105221644",
                    @"http://static2.dmcdn.net/static/video/932/448/51844239:jpeg_preview_small.jpg?20121105221309",
                    @"http://static2.dmcdn.net/static/video/967/438/51834769:jpeg_preview_small.jpg?20121105221020",
                    @"http://static2.dmcdn.net/static/video/362/348/51843263:jpeg_preview_small.jpg?20121105220855",
                    @"http://static2.dmcdn.net/static/video/777/448/51844777:jpeg_preview_small.jpg?20121105220715",
                    @"http://static2.dmcdn.net/static/video/567/348/51843765:jpeg_preview_small.jpg?20121105220708",
                    @"http://static2.dmcdn.net/static/video/905/248/51842509:jpeg_preview_small.jpg?20121105220640",
                    @"http://static2.dmcdn.net/static/video/857/748/51847758:jpeg_preview_small.jpg?20121105221003",
                    @"http://static2.dmcdn.net/static/video/578/348/51843875:jpeg_preview_small.jpg?20121105220350",
                    @"http://static2.dmcdn.net/static/video/214/448/51844412:jpeg_preview_small.jpg?20121105220415",
                    @"http://static2.dmcdn.net/static/video/264/748/51847462:jpeg_preview_small.jpg?20121105220635",
                    @"http://static2.dmcdn.net/static/video/817/748/51847718:jpeg_preview_small.jpg?20121105220233",
                    @"http://static2.dmcdn.net/static/video/807/748/51847708:jpeg_preview_small.jpg?20121105220241",
                    @"http://static2.dmcdn.net/static/video/199/838/51838991:jpeg_preview_small.jpg?20121105220605",
                    @"http://static2.dmcdn.net/static/video/776/748/51847677:jpeg_preview_small.jpg?20121105220150",
                    @"http://static2.dmcdn.net/static/video/986/748/51847689:jpeg_preview_small.jpg?20121105224514",
                    @"http://static2.dmcdn.net/static/video/915/748/51847519:jpeg_preview_small.jpg?20121105222216",
                    @"http://static2.dmcdn.net/static/video/983/448/51844389:jpeg_preview_small.jpg?20121105220116",
                    @"http://static2.dmcdn.net/static/video/751/348/51843157:jpeg_preview_small.jpg?20121105220104",
                    @"http://static2.dmcdn.net/static/video/192/538/51835291:jpeg_preview_small.jpg?20121105220103",
                    @"http://static2.dmcdn.net/static/video/596/448/51844695:jpeg_preview_small.jpg?20121105220033",
                    @"http://static2.dmcdn.net/static/video/750/648/51846057:jpeg_preview_small.jpg?20121105221259",
                    @"http://static2.dmcdn.net/static/video/441/148/51841144:jpeg_preview_small.jpg?20121105215911",
                    @"http://static2.dmcdn.net/static/video/860/448/51844068:jpeg_preview_small.jpg?20121105215905",
                    @"http://static2.dmcdn.net/static/video/995/748/51847599:jpeg_preview_small.jpg?20121105215939",
                    @"http://static2.dmcdn.net/static/video/774/748/51847477:jpeg_preview_small.jpg?20121105223414",
                    @"http://static2.dmcdn.net/static/video/498/648/51846894:jpeg_preview_small.jpg?20121105221807",
                    @"http://static2.dmcdn.net/static/video/011/748/51847110:jpeg_preview_small.jpg?20121105221118",
                    @"http://static2.dmcdn.net/static/video/794/748/51847497:jpeg_preview_small.jpg?20121105220829",
                    @"http://static2.dmcdn.net/static/video/988/648/51846889:jpeg_preview_small.jpg?20121105222149",
                    @"http://static2.dmcdn.net/static/video/769/548/51845967:jpeg_preview_small.jpg?20121105215601",
                    @"http://static2.dmcdn.net/static/video/225/448/51844522:jpeg_preview_small.jpg?20121105215552",
                    @"http://static2.dmcdn.net/static/video/172/308/51803271:jpeg_preview_small.jpg?20121105215455",
                    @"http://static2.dmcdn.net/static/video/994/748/51847499:jpeg_preview_small.jpg?20121105220343",
                    @"http://static2.dmcdn.net/static/video/852/748/51847258:jpeg_preview_small.jpg?20121105221031",
                    @"http://static2.dmcdn.net/static/video/671/838/51838176:jpeg_preview_small.jpg?20121105215421",
                    @"http://static2.dmcdn.net/static/video/172/448/51844271:jpeg_preview_small.jpg?20121105215420",
                    @"http://static2.dmcdn.net/static/video/735/448/51844537:jpeg_preview_small.jpg?20121105215437",
                    @"http://static2.dmcdn.net/static/video/834/448/51844438:jpeg_preview_small.jpg?20121105215431",
                    @"http://static2.dmcdn.net/static/video/613/448/51844316:jpeg_preview_small.jpg?20121105215431",
                    @"http://static2.dmcdn.net/static/video/581/748/51847185:jpeg_preview_small.jpg?20121105220637",
                    @"http://static2.dmcdn.net/static/video/407/648/51846704:jpeg_preview_small.jpg?20121105220316",
                    @"http://static2.dmcdn.net/static/video/460/448/51844064:jpeg_preview_small.jpg?20121105215245",
                    @"http://static2.dmcdn.net/static/video/298/648/51846892:jpeg_preview_small.jpg?20121105220953",
                    @"http://static2.dmcdn.net/static/video/053/748/51847350:jpeg_preview_small.jpg?20121105221113",
                    @"http://static2.dmcdn.net/static/video/996/448/51844699:jpeg_preview_small.jpg?20121105222807",
                    @"http://static2.dmcdn.net/static/video/451/448/51844154:jpeg_preview_small.jpg?20121105221955",
                    @"http://static2.dmcdn.net/static/video/049/648/51846940:jpeg_preview_small.jpg?20121105215910",
                    @"http://static2.dmcdn.net/static/video/091/748/51847190:jpeg_preview_small.jpg?20121105215617",
                    @"http://static2.dmcdn.net/static/video/573/748/51847375:jpeg_preview_small.jpg?20121105223420",
                    @"http://static2.dmcdn.net/static/video/103/248/51842301:jpeg_preview_small.jpg?20121105215014",
                    @"http://static2.dmcdn.net/static/video/991/548/51845199:jpeg_preview_small.jpg?20121105215407",
                    @"http://static2.dmcdn.net/static/video/872/648/51846278:jpeg_preview_small.jpg?20121105220635",
                    @"http://static2.dmcdn.net/static/video/813/748/51847318:jpeg_preview_small.jpg?20121105214729",
                    @"http://static2.dmcdn.net/static/video/153/448/51844351:jpeg_preview_small.jpg?20121105214622",
                    @"http://static2.dmcdn.net/static/video/328/648/51846823:jpeg_preview_small.jpg?20121105214944",
                    @"http://static2.dmcdn.net/static/video/892/748/51847298:jpeg_preview_small.jpg?20121105224514",
                    @"http://static2.dmcdn.net/static/video/640/048/51840046:jpeg_preview_small.jpg?20121105214430",
                    @"http://static2.dmcdn.net/static/video/153/648/51846351:jpeg_preview_small.jpg?20121105214426",
                    @"http://static2.dmcdn.net/static/video/769/248/51842967:jpeg_preview_small.jpg?20121105214255",
                    @"http://static2.dmcdn.net/static/video/720/448/51844027:jpeg_preview_small.jpg?20121105214248",
                    @"http://static2.dmcdn.net/static/video/895/048/51840598:jpeg_preview_small.jpg?20121105214234",
                    @"http://static2.dmcdn.net/static/video/893/348/51843398:jpeg_preview_small.jpg?20121105214157",
                    @"http://static2.dmcdn.net/static/video/351/748/51847153:jpeg_preview_small.jpg?20121105214106",
                    @"http://static2.dmcdn.net/static/video/364/648/51846463:jpeg_preview_small.jpg?20121105215005",
                    @"http://static2.dmcdn.net/static/video/269/938/51839962:jpeg_preview_small.jpg?20121105214014",
                    nil];
    }
    [SDWebImageManager.sharedManager.imageDownloader setValue:@"SDWebImage Demo" forHTTPHeaderField:@"AppName"];
    SDWebImageManager.sharedManager.imageDownloader.executionOrder = SDWebImageDownloaderLIFOExecutionOrder;
    return self;
}

- (void)flushCache
{
    [SDWebImageManager.sharedManager.imageCache clearMemory];
    [SDWebImageManager.sharedManager.imageCache clearDisk];
}
							
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.text = [NSString stringWithFormat:@"Image #%d", indexPath.row];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [cell.imageView setImageWithURL:[NSURL URLWithString:[_objects objectAtIndex:indexPath.row]]
                   placeholderImage:[UIImage imageNamed:@"placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.detailViewController)
    {
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    }
    NSString *largeImageURL = [[_objects objectAtIndex:indexPath.row] stringByReplacingOccurrencesOfString:@"small" withString:@"source"];
    self.detailViewController.imageURL = [NSURL URLWithString:largeImageURL];
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

@end

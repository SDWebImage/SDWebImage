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
        _objects = [NSArray arrayWithObjects:
                    @"http://static2.dmcdn.net/static/video/451/838/44838154:jpeg_preview_small.jpg?20120509163826",
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
                    nil];
    }
    return self;
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
    [cell.imageView setImageWithURL:[NSURL URLWithString:[_objects objectAtIndex:indexPath.row]]
                   placeholderImage:[UIImage imageNamed:@"placeholder"]];
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

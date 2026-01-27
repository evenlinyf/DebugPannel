/// 创建时间：2026/01/21
/// 创建人：Codex
/// 用途：SFSymbols 列表页面实现。
#import "YFSFSymbolsViewController.h"

#import "YFAlertPresenter.h"
#import "YFHapticFeedback.h"

@interface YFSFSymbolsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<NSString *> *symbolNames;
@property (nonatomic, copy) NSArray<NSString *> *filteredNames;
@property (nonatomic, strong) UISearchController *searchController;
@end

@interface YFSFSymbolsCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
- (void)configureWithName:(NSString *)name image:(UIImage *)image;
@end

@implementation YFSFSymbolsCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = UIColor.secondarySystemBackgroundColor;
        self.contentView.layer.cornerRadius = 12.0;
        self.contentView.layer.masksToBounds = YES;

        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = UIColor.labelColor;

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.numberOfLines = 2;
        _titleLabel.textAlignment = NSTextAlignmentCenter;

        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _detailLabel.font = [UIFont systemFontOfSize:10.0];
        _detailLabel.textColor = UIColor.secondaryLabelColor;
        _detailLabel.textAlignment = NSTextAlignmentCenter;

        [self.contentView addSubview:_iconView];
        [self.contentView addSubview:_titleLabel];
        [self.contentView addSubview:_detailLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_iconView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10.0],
            [_iconView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:28.0],
            [_iconView.heightAnchor constraintEqualToConstant:28.0],

            [_titleLabel.topAnchor constraintEqualToAnchor:_iconView.bottomAnchor constant:6.0],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:6.0],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-6.0],

            [_detailLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2.0],
            [_detailLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:6.0],
            [_detailLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-6.0],
            [_detailLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-8.0]
        ]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.iconView.image = nil;
    self.titleLabel.text = nil;
    self.detailLabel.text = nil;
}

- (void)configureWithName:(NSString *)name image:(UIImage *)image {
    self.iconView.image = image ?: [UIImage systemImageNamed:@"questionmark.circle"];
    self.titleLabel.text = name;
    self.detailLabel.text = image ? @"点击复制" : @"不可用";
}

@end

@implementation YFSFSymbolsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"SFSymbols";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.symbolNames = [self loadSymbolNames];
    self.filteredNames = self.symbolNames;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(12.0, 16.0, 12.0, 16.0);
    layout.minimumInteritemSpacing = 12.0;
    layout.minimumLineSpacing = 12.0;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = UIColor.systemBackgroundColor;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[YFSFSymbolsCell class] forCellWithReuseIdentifier:@"YFSFSymbolsCell"];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.placeholder = @"搜索 SFSymbols";
    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;

    if (self.symbolNames.count == 0) {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.text = @"未找到 SFSymbols 列表";
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.textColor = UIColor.secondaryLabelColor;
        self.collectionView.backgroundView = emptyLabel;
    }
}

- (NSArray<NSString *> *)loadSymbolNames {
    NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/CoreServices/CoreGlyphs.bundle"];
    NSString *orderPath = [bundle pathForResource:@"symbol_order" ofType:@"plist"];
    NSArray *orderNames = [NSArray arrayWithContentsOfFile:orderPath];
    if (orderNames.count > 0) {
        return [self filteredSymbolNames:orderNames];
    }
    NSString *availabilityPath = [bundle pathForResource:@"name_availability" ofType:@"plist"];
    NSDictionary *availability = [NSDictionary dictionaryWithContentsOfFile:availabilityPath];
    if ([availability isKindOfClass:[NSDictionary class]] && availability.count > 0) {
        NSArray *sorted = [availability.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        return [self filteredSymbolNames:sorted];
    }
    return @[];
}

- (NSArray<NSString *> *)filteredSymbolNames:(NSArray *)names {
    NSMutableArray<NSString *> *results = [NSMutableArray array];
    for (id name in names) {
        if ([name isKindOfClass:[NSString class]] && ((NSString *)name).length > 0) {
            [results addObject:name];
        }
    }
    return [results copy];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredNames.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YFSFSymbolsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YFSFSymbolsCell" forIndexPath:indexPath];
    NSString *name = self.filteredNames[indexPath.row];
    UIImage *image = [UIImage systemImageNamed:name];
    [cell configureWithName:name image:image];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = self.filteredNames[indexPath.row];
    if (name.length == 0) {
        return;
    }
    UIPasteboard.generalPasteboard.string = name;
    [YFHapticFeedback impactLight];
    [YFAlertPresenter presentToastFrom:self message:[NSString stringWithFormat:@"已复制 %@", name] duration:1.0];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat horizontalPadding = 16.0 * 2;
    CGFloat spacing = 12.0;
    CGFloat availableWidth = collectionView.bounds.size.width - horizontalPadding - spacing * 2;
    CGFloat itemWidth = floor(availableWidth / 3.0);
    return CGSizeMake(MAX(itemWidth, 90.0), 110.0);
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *query = searchController.searchBar.text ?: @"";
    if (query.length == 0) {
        self.filteredNames = self.symbolNames;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSString *name, NSDictionary *bindings) {
            return [name localizedCaseInsensitiveContainsString:query];
        }];
        self.filteredNames = [self.symbolNames filteredArrayUsingPredicate:predicate];
    }
    [self.collectionView reloadData];
}

@end
